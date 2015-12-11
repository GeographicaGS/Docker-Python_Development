This is an image that simply creates a Python enviroment for testing in Docker-Compose deployments.

It is designed for mounting hard volumes of code to execute them inside the container. An environment variable controls the pip packages to be installed called PIP_PACKAGES, separate package names by ;. It is designed to be used interactively with run -ti /bin/bash. Execute install_pip_packages once to install from pip.

To build:

docker build -t="geographica/python-dev:2.7.11" .


To run:

docker run -ti --rm geographica/python-dev:2.7.11 /bin/bash


don't forget to hard mount the code volume and to add -e ENV with the packages to load. Execute install_pip_packages on first run. Make it part of Docker-Compose. Integrate into GeoServer-REST compose to run tests.
