#!/bin/bash

echo -e "\e[33m\e[1mBuilding OpenCV for Nvidia Jetson TX1 \e[0m"

docker exec avular-env-jetsontx1 ./_git/install_packages.bash

