# OpenCV-3 Installation [![Build Status](https://travis-ci.org/ar13pit/opencvinstall.svg?branch=master)](https://travis-ci.org/ar13pit/opencvinstall)

Bash script to install version independent OpenCV-3. Under the releases tab ```.deb``` files for installation on Ubuntu 16.04 desktop (complete with CUDA enabled GPU), Raspberry Pi 3 (Compute Module inclusive) and Nvidia Jetson TX1 can be found.

Raspberry Pi 3 and Nvidia Jetson TX1 install files do not include GUI support and installed examples. This can be enabled by changing the ```CMake``` flags.

## Setup
Clone the repository and run:
```
./opencvinstall.bash
```
to see the list of available options to install OpenCV-3.
