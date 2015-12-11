FROM python:2

MAINTAINER Juan Pedro Perez "jp.alcantara@geographica.gs"

RUN apt-get update

ENV PIP_PACKAGES ipython
ADD install_pip_packages /usr/local/bin/
RUN chmod 755 /usr/local/bin/install_pip_packages

