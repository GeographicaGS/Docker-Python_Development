# A Docker Container for Interactively Running Python Tests Inside a Docker-Compose

First things first: I'm in no way a __Docker__ expert. We at [Geographica](http://www.geographica.gs/en) have been using Docker for some time now and therefore we are learning new things constantly. Perhaps this Docker is the ugliest compendium of hacks around and is a mess, perhaps there are other, finer ways of achieving what I'm trying to do here, I don't know. Perhaps even this is brilliant! (I doubt so). In any case, it solves more or less a problem I came by.

The situation this image is trying to mitigate is the following: I'm developing a library in Python that attacks a REST interface coupled with a PostgreSQL database (if you are curious, it is here: [https://github.com/GeographicaGS/GeoServer-Python-REST-API](https://github.com/GeographicaGS/GeoServer-Python-REST-API)). So I created a __Docker Compose__ that creates the REST application and the PostgreSQL, and links them so the web application can see the PostgreSQL inside the network shared by Docker. This creates the following situation:

- both containers exposes their ports to the host, so they are reachable from a Python test suite running on it. For example, I mapped the PostgreSQL port 5432 to 5435, so the PostgreSQL inside the container is reachable at _localhost:5435_ from the host;

- both containers see each other inside the Docker created network, but they see with their respective Compose names and they expose their original ports to each other. This way, the same PostgreSQL reachable from the host as described above is reachable from the REST container as _db:5432_.

Suppose now that one of the tests (as is the case) asks the REST for certain connection details to the PostgreSQL container. The REST application is reaching the PostgreSQL container from within the Docker private network, so it says that to connect to the PostgreSQL you must call host _db_ at port _5432_. But this has no sense for the host since it can't resolve the hostname _db_. So tests can't continue from the hosts.

# This Solution is Probably an Overkill

But works for me until I know more about Docker. What I did with this image is integrating the Python testing platform inside the __Compose__ deployment, so it can resolve other containers hostnames. It is basicly a very simple image to share a static volume with the host (where the test code is stored) and run them.

# Possible Alternatives

I've explored some alternatives to the use of this image, which I think is an overshoot:

- _Compose's_ link writes to the /etc/hosts of each container the IP of the linked containers. This way, the REST application can resolve the name _db_. I have not, however, found an easy way to resolve those names from the host. As each container has an IP both visible from the other containers and from the host thanks to the _docker0_ network interface, it can be nice if the host can be able to resolve container hostnames.

- The __run__ command seems to have an __--ip__ option to specify the IP of a container. But Docker Compose, being an orchestrator, does not have it, so containers IP can vary from deployment to deployment, so they aren't reliable as accessors from the tests being run at the host.

# How It Works

Build it:

```Shell
docker build -t="geographica/python_development:2.7.11" .
```

or pull from DockerHub:

```Shell
docker pull geographica/python_development:2.7.11
```

Always run the Compose or the container with __-d__. To run it:

```Shell
docker run -d --name whatever -e "APT_PACKAGES=libpq-dev" \
-e "PIP_PACKAGES=ipython;psycopg2;pytest" \
-e "CONTAINER_USER_UID=1001" -e "CONTAINER_GROUP_ID=1002" \
-e "ADDTOPYPATH=/home/python-dev/src" \
-v /home/testuser/:/home/python-dev/ geographica/python_development:2.7.11
```

Do not attach to this container with __attach__. An example of integration in a _Compose_:

```yaml
python-dev:
  image: geographica/python_development:2.7.11
  environment:
    - APT_PACKAGES=libpq-dev
    - PIP_PACKAGES=ipython;psycopg2
    - CONTAINER_USER_UID=1000
    - CONTAINER_GROUP_ID=1000
	- ADDTOPYPATH=/home/python-dev/src/
  volumes:
    - /home/git/GeoServer-Python-REST-API/:/GeoServer-Python-REST-API/
  links:
    - db
    - sourcegeoserver
    - destinationgeoserver
```

As far as I can tell, Docker does not any effort to map container's users to host's users, so here is the trick. There are two environmental variables defined, __CONTAINER_USER_UID__ and __CONTAINER_GROUP_ID__. These variables defines the identifiers of both user and group, which are shared by the container and the host when they share a hard volume. Hard volumes are generally a bad idea in production and this a hack only suitable for personal development environment, which is the intended use scope of this image. When you link a volume with the __-v__ option, if a file is written from the container it will be written with the user and group ID as seen from the container, but will be interpreted by the host user definitions on its own. So if the container is writing something with user ID 1001, which is for example _tomcat_ in the container, it will be seen as belonging to user ID 1001 in the host, that may be whatever. So the trick is to pass to the container the user and group ID of the intended user at the host. This is easy to know by issuing:

```Shell
id username
```

that will output something like this:

```Shell
uid=1001(username) gid=1001(username) groups=1002(username)
```

where __CONTAINER_USER_ID__ will be the __uid__ and __CONTAINER_GROUP_ID__ will be the __groups__. The container will create a dummy user with those ID called _python-dev_ that is the one to be used for running Python code inside the container.

The __APT_PACKAGES__ variable contains a list of semicolon-separated APT package names to be installed on the first run. __PIP_PACKAGES__ does the same with PIP oneso. __ADDTOPYPATH__ adds folders inside the container (most probably the hard linked volume mounted with _-v_) to the __PYTHONPATH__.

To check if the first run setup process is over, launch:

```Shell
docker exec containername ps aux
```

If __setup__ is one of the running processes, it's not ready yet.

Once started, the container will be in an infinite loop doing nothing. To use it, execute:

```Shell
docker exec -ti containername su python-dev -c /bin/bash
```

This will enter into interactive mode where Python code can be executed. If root access to the container is needed, for example to install a pip package:

```Shell
docker exec -ti containername /bin/bash
```

The interactive console can be quit with _exit_; however, the container will continue to run. Stop it with:

```Shell
docker stop containername
```

# Tags

The only tag available is __2.7.11__, which refers to the Python version being used.
