#! /usr/bin/env bash
#
# Install script for OpenCV
#
# Script dependencies:
#   1) version - Text file containing the version of OpenCV to be installed
#
# Supported systems:
#   1) Ubuntu 16.04
#   2) Raspbian Stretch
#
# Supported programming languages:
#   1) Python3
#   2) C++
#
# Contributors:
#   2018-08-22 Arpit Aggarwal


VERSION="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cat version)"
OPENCVHOME=~/opencv-"${VERSION}"

SWAPSIZE="$(grep "#CONF_SWAPSIZE=" /etc/dphys-swapfile)"

# Installation flag defaults
DEVICE="desktop"
INSTALLATION="gui"
FLAG_CUDA=OFF
VERBOSE=true

if [ -z "$SWAPSIZE" ]; then
    SWAPSIZE="$(grep "CONF_SWAPSIZE=" /etc/dphys-swapfile)"
    SWAPSIZE_FLAG=1
else
    SWAPSIZE_FLAG=0
fi

usage()
{
    echo "Create a version file with the version of OpenCV to be installed in it"
    echo "Example:  echo \"3.4.2\" > version "
    echo
    echo "Install OpenCV using opencvinstall.bash"
    echo "Usage: ./opencvinstall.bash [options] <arguments>"
    echo -e "options:\n \
    -h | --help\n \
    -d | --device\n \
            Arguments:\n \
                rpi3\n \
                jetsontx1\n \
                desktop\n \
                desktop-with-cuda\n \
    -t | --type\n \
            Arguments:\n \
                gui\n \
                no-gui\n \
    -nv | --no-verbose\n \
    --download-opencv\n\
    --config-cmake\n \
    --install-default\n \
            equivalent to:  -d desktop -t gui\n \
    --install-dependencies\n \
    --install-opencv\n \
    --install-virtualenv\n \
    --check-install"
    echo
    echo "--------------------------------------------------------------------------"
}

if [ -z "$VERSION" ]; then
    echo "version file not found"
    echo
    usage
    exit 1
fi

echo
echo -e "\e[35m\e[1mOpenCV $VERSION Installation \e[0m"
echo

install_dependencies()
{
    echo
    echo -e "\e[35m\e[1mInstalling dependencies \e[0m"
    echo
    
    if [ !$VERBOSE ]
    then
        FLAG_VERBOSE=-qq
    else
        FLAG_VERBOSE=
    fi

    sudo apt-get update $FLAG_VERBOSE
    sudo apt-get upgrade --assume-yes $FLAG_VERBOSE

    sudo apt-get install --assume-yes $FLAG_VERBOSE build-essential cmake git vim
    sudo apt-get install --assume-yes $FLAG_VERBOSE pkg-config unzip ffmpeg python3-dev gfortran python3-pip
    sudo apt-get install --assume-yes $FLAG_VERBOSE libdc1394-22 libdc1394-22-dev libjpeg-dev libpng-dev libtiff5-dev libjasper-dev
    sudo apt-get install --assume-yes $FLAG_VERBOSE libavcodec-dev libavformat-dev libswscale-dev libxine2-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev
    sudo apt-get install --assume-yes $FLAG_VERBOSE libv4l-dev libtbb-dev libfaac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev
    sudo apt-get install --assume-yes $FLAG_VERBOSE libvorbis-dev libxvidcore-dev v4l-utils vtk6 libx264-dev
    sudo apt-get install --assume-yes $FLAG_VERBOSE liblapacke-dev libopenblas-dev libgdal-dev checkinstall
    sudo apt-get install --assume-yes $FLAG_VERBOSE libeigen3-dev libatlas-base-dev
    sudo apt-get install --assume-yes $FLAG_VERBOSE libgirepository1.0-dev libglib2.0-dev

    if [ "$INSTALLATION" == "gui" ]
    then
        sudo apt-get install --assume-yes $FLAG_VERBOSE libgtk-3-dev
    fi
}


install_dependencies_pi()
{
    install_dependencies
    # To get rid of Python warning: Error retrieving accessibility bus address [org.a11y.Bus]
    sudo apt-get install --assume-yes at-spi2-core
}

download_opencv()
{
    echo
    echo -e "\e[35m\e[1mDownloading and extracting OpenCV-$VERSION \e[0m"
    echo

    if [ !$VERBOSE ]
    then
        FLAG_VERBOSE=-nv
    else
        FLAG_VERBOSE=
    fi

    cd
    wget -O opencv-"${VERSION}".zip https://github.com/opencv/opencv/archive/"${VERSION}".zip opencv-"${VERSION}".zip $FLAG_VERBOSE
    unzip opencv-"${VERSION}".zip && rm opencv-"${VERSION}".zip

    echo
    echo -e "\e[35m\e[1mDownloading and extracting OpenCV-contrib-$VERSION \e[0m"
    echo

    cd
    wget -O opencv_contrib-"${VERSION}".zip https://github.com/opencv/opencv_contrib/archive/"${VERSION}".zip $FLAG_VERBOSE
    unzip opencv_contrib-"${VERSION}" && rm opencv_contrib-"${VERSION}".zip
}


install_virtualenv()
{
    echo
    echo -e "\e[35m\e[1mInstalling virtualenv and setting up (cv) venv \e[0m"
    echo


    sudo pip3 install -U pip
    sudo pip3 install virtualenv
    sudo rm -rf ~/.cache/pip

    if [ ! -d ~/.venvs ]; then
        mkdir ~/.venvs
    fi

    cd ~/.venvs
    virtualenv --no-site-packages -p python3 cv
    cd ~
    echo "alias cv='source ~/.venvs/cv/bin/activate && PYTHONPATH='" >> ~/.bash_aliases
    source ~/.bashrc
    source ~/.venvs/cv/bin/activate
    export PYTHONPATH=

    pip install -U pip
    pip install numpy matplotlib ipython pillow pgi pycairo cairocffi imageio
    pip install pygobject
}


config_cmake()
{
    echo
    echo -e "\e[35m\e[1mConfiguring OpenCV-$VERSION build \e[0m"
    echo

    cd $OPENCVHOME
    mkdir build
    cd build
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=~/.venvs/cv \
        -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib-"${VERSION}"/modules \
        -D PYTHON_EXECUTABLE=~/.venvs/cv/bin/python \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_opencv_apps=OFF \
        -D BUILD_DOCS=OFF \
        -D BUILD_PERF_TESTS=OFF \
        -D BUILD_TESTS=OFF \
        -D INSTALL_PYTHON_EXAMPLES=OFF \
        -D INSTALL_C_EXAMPLES=OFF \
        -D WITH_TBB=ON \
        -D WITH_OPENMP=ON \
        -D WITH_IPP=ON \
        -D WITH_NVCUVID=ON \
        -D WITH_CUDA="${FLAG_CUDA}" \
        -D WITH_CSTRIPES=ON \
        -D WITH_OPENCL=ON ..

}


make_opencv()
{
    echo
    echo -e "\e[35m\e[1mBuilding OpenCV-$VERSION \e[0m"
    echo
    
    cd $OPENCVHOME/build

    if [ "$SWAPSIZE_FLAG" == 1 ]; then
        sudo sed -i "s/$SWAPSIZE/CONF_SWAPSIZE=1024/g" /etc/dphys-swapfile
        sudo systemctl restart dphys-swapfile
    fi

    make -j $(($(nproc) + 1))

    if [ "$SWAPSIZE_FLAG" == 1 ]; then
        sudo sed -i "s/CONF_SWAPSIZE=1024/$SWAPSIZE/g" /etc/dphys-swapfile
        sudo systemctl restart dphys-swapfile
    fi
}

install_opencv()
{
    echo
    echo -e "\e[35m\e[1mInstalling OpenCV-$VERSION \e[0m"
    echo
    
    cd $OPENCVHOME/build
    make install
    sudo ldconfig
}


check_install()
{
    echo
    echo -e "\e[35m\e[1mChecking installation \e[0m"
    echo

    CVV="$(python -c "import cv2; print(cv2.__version__)")"

    if [ "$CVV" != "$VERSION" ]; then
        echo -e "\e[33m\e[1mInstallation failure \e[0m"
    else
        echo -e "\e[33m\e[1mOpenCV-$VERSION successfully installed \e[0m"
    fi
}

install_complete()
{
    install_dependencies
    download_opencv
    install_virtualenv
    config_cmake

    echo -e "\e[35m\e[1mExamine the output of CMake before continuing \e[0m"
    read -n1 -rsp $'Press space to continue...\n' key
    while [ "$key" != '' ]; do
        :
    done

    make_opencv
    install_opencv
    check_install
}

# Read Postional Parameters
if [ -z "$1" ]; then
    usage
else
    while [ "$1" != "" ]; do
        case $1 in
            -d | --device )
                shift
                case $1 in
                    rpi3 )
                        DEVICE="rpi3" 
                        FLAG_CUDA=OFF ;;

                    jetsontx1 )
                        DEVICE="jetsontx1"
                        FLAG_CUDA=ON ;;

                    desktop)
                        DEVICE="desktop"
                        FLAG_CUDA=OFF ;;

                    desktop-with-cuda )
                        DEVICE="desktop-with-cuda"
                        FLAG_CUDA=ON ;;
                esac ;;

            -t | --type )
                shift
                case $1 in
                    gui )
                        INSTALLATION="gui" ;;

                    no-gui )
                        INSTALLATION="no-gui" ;;
                esac ;;

            -nv | --no-verbose )
                VERBOSE=false ;;

            --install-default )
                install_complete ;;
                
            --install-dependencies )
                install_dependencies ;;

            --download-opencv )
                download_opencv ;;

            --install-virtualenv )
                install_virtualenv ;;

            --config-cmake )
                config_cmake ;;

            --make-opencv )
                make_opencv ;;

            --install-opencv )
                install_opencv ;;

            --check-install )
                check_install ;;

            --h | --help )
                usage
                exit 1 ;;

            * )
                usage
                exit 1 ;;
        esac
        shift
    done
fi
