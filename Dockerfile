FROM ubuntu:latest

MAINTAINER Juan Pedro Perez "jp.alcantara@geographica.gs"

RUN apt-get update
RUN apt-get install -y less libpython2.7 python-dev python-pip
ENV APT_PACKAGES nano
ENV PIP_PACKAGES ipython
ENV CONTAINER_USER_UID 1000
ENV CONTAINER_GROUP_ID 1000
ENV ADDTOPYPATH $PYTHONPATH
ADD setup /usr/local/bin/
ADD install_packages /usr/local/bin/
RUN chmod 755 /usr/local/bin/setup
RUN chmod 755 /usr/local/bin/install_packages

ENTRYPOINT ["/usr/local/bin/setup"]
