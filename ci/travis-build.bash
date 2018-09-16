#! /usr/bin/env bash

echo -e "\e[35m\e[1m Creating docker image \e[0m"

docker build -t "arpit-test" .
ls
docker run arpit-test
