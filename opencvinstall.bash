#! /usr/bin/env bash

VERSION="$(cat version)"

if [ -z "$VERSION" ]; then
    echo "version file not found"
    echo "Create a version file with the version of OpenCV to be installed in it"
    echo "Example:  echo \"3.4.2\" > version "
    exit
fi

echo "------------------------------------------------------"
echo "              OpenCV $VERSION Installation"
echo "------------------------------------------------------"

sudo apt-get update
sudo apt-get upgrade --assume-yes

echo "Installing dependencies"
echo

sudo apt-get install --assume-yes build-essential cmake git vim
sudo apt-get install --assume-yes pkg-config unzip ffmpeg python3-dev gfortran python3-pip
sudo apt-get install --assume-yes libopencv-dev libgtk-3-dev libdc1394-22 libdc1394-22-dev libjpeg-dev libpng12-dev libtiff5-dev libjasper-dev
sudo apt-get install --assume-yes libavcodec-dev libavformat-dev libswscale-dev libxine2-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev
sudo apt-get install --assume-yes libv4l-dev libtbb-dev libfaac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev
sudo apt-get install --assume-yes libvorbis-dev libxvidcore-dev v4l-utils vtk6 libx264-dev
sudo apt-get install --assume-yes liblapacke-dev libopenblas-dev libgdal-dev checkinstall

echo "Downloading and extracting OpenCV-$VERSION "
echo

wget opencv-"${VERSION}".zip https://github.com/opencv/opencv/archive/"${VERSION}".zip opencv-"${VERSION}".zip
unzip opencv-"${VERSION}".zip && rm opencv-"${VERSION}".zip

echo "Downloading and extracting OpenCV-contrib-$VERSION"
echo

wget opencv_contrib-"${VERSION}".zip https://github.com/opencv/opencv_contrib/archive/"${VERSION}".zip
unzip opencv_contrib-"${VERSION}" && rm opencv_contrib-"${VERSION}".zip

echo "Installing virtualenv"
echo

sudo pip3 install -U pip
sudo pip3 install virtualenv
sudo rm -rf ~/.cache/pip

if [ ! -d ~/.venvs ]; then
    mkdir ~/.venvs
fi

cd ~/.venvs
virtualenv --no-site-packages -p python3 cv
echo "alias cv='source ~/.venvs/cv/bin/activate && PYTHONPATH='" >> ~/.bash_aliases
source ~/.bashrc
source ~/.venvs/cv/bin/activate
export PYTHONPATH=

pip install numpy

echo "Building OpenCV"

