FROM python:2.7.11

MAINTAINER Juan Pedro Perez "jp.alcantara@geographica.gs"

RUN apt-get update
ENV PIP_PACKAGES ipython
ENV CONTAINER_USER_UID 1000
ENV CONTAINER_GROUP_ID 1000
ADD setup /usr/local/bin/
ADD install_pip_packages /usr/local/bin/
RUN chmod 755 /usr/local/bin/setup
RUN chmod 755 /usr/local/bin/install_pip_packages

ENTRYPOINT ["/usr/local/bin/setup"]
