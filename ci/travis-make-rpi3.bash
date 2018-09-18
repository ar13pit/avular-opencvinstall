#!/bin/bash

echo -e "\e[33m\e[1mBuilding OpenCV for Raspberry Pi 3 \e[0m"

docker exec avular-env-rpi3 ./_git/opencvinstall.bash --download-opencv
docker exec avular-env-rpi3 ./_git/opencvinstall.bash --config-cmake

