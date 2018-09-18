#!/bin/bash

echo -e "\e[35m\e[1mCreating docker image \e[0m"

# Build docker image
docker build -t avular-test .

# Start docker image containers
docker run -d --name avular-env-rpi3 -t avular-test:latest
#docker run -d --name avular-env-jetsontx1 -t avular-test:latest
