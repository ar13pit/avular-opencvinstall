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

SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
VERSION="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cat version)"
OPENCVHOME=~/opencv-"${VERSION}"


# Installation flag defaults
DEVICE="desktop"
INSTALLATION="gui"
FLAG_CUDA=OFF
VERBOSE=true

if [ -f /etc/dphys-swapfile ]
then

    SWAPSIZE="$(grep "#CONF_SWAPSIZE=" /etc/dphys-swapfile)"
    if [ -z "$SWAPSIZE" ]
    then
        SWAPSIZE="$(grep "CONF_SWAPSIZE=" /etc/dphys-swapfile)"
        SWAPSIZE_FLAG=1
    else
        SWAPSIZE_FLAG=0
    fi
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
                jetsontx2\n \
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

if [ -z "$VERSION" ]
then
    echo "version file not found"
    echo
    usage
    exit 1
fi

echo
echo -e "\e[35m\e[1mOpenCV $VERSION Installation in $OPENCVHOME \e[0m"
echo

install_dependencies()
{
    echo
    echo -e "\e[35m\e[1mInstalling dependencies \e[0m"
    echo

    if [ "$VERBOSE" == "true" ]
    then
        FLAG_VERBOSE=
    else
        FLAG_VERBOSE=-qq
    fi

    sudo apt-get update $FLAG_VERBOSE
    sudo apt-get upgrade --assume-yes $FLAG_VERBOSE

    sudo apt-get install --assume-yes --no-install-recommends build-essential cmake git $FLAG_VERBOSE
    sudo apt-get install --assume-yes --no-install-recommends pkg-config unzip gfortran $FLAG_VERBOSE
    sudo apt-get install --assume-yes --no-install-recommends python3-dev python3-pip python3-numpy ipython3 $FLAG_VERBOSE
    sudo apt-get install --assume-yes --no-install-recommends libdc1394-22-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev $FLAG_VERBOSE
    sudo apt-get install --assume-yes --no-install-recommends libavcodec-dev libavformat-dev libavresample-dev libswscale-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev $FLAG_VERBOSE
    sudo apt-get install --assume-yes --no-install-recommends libv4l-dev libtbb-dev libtheora-dev $FLAG_VERBOSE
    sudo apt-get install --assume-yes --no-install-recommends libxvidcore-dev v4l-utils libx264-dev $FLAG_VERBOSE
    sudo apt-get install --assume-yes --no-install-recommends liblapacke-dev libopenblas-dev libgdal-dev checkinstall $FLAG_VERBOSE
    sudo apt-get install --assume-yes --no-install-recommends libeigen3-dev libatlas-base-dev $FLAG_VERBOSE
    sudo apt-get install --assume-yes --no-install-recommends libgirepository1.0-dev libglib2.0-dev $FLAG_VERBOSE

    pip3 install --user --upgrade numpy ipython

    if [ "$INSTALLATION" == "gui" ]
    then
        sudo apt-get install --assume-yes --no-install-recommends libgtk-3-dev libvtk7-dev vtk7 qtbase5-dev $FLAG_VERBOSE
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

    if [ "$VERBOSE" == "true" ]
    then
        FLAG_VERBOSE=
    else
        FLAG_VERBOSE=-q
    fi

    cd
    wget -O opencv-"${VERSION}".zip https://github.com/opencv/opencv/archive/"${VERSION}".zip --no-verbose
    unzip $FLAG_VERBOSE opencv-"${VERSION}".zip && rm opencv-"${VERSION}".zip

    echo
    echo -e "\e[35m\e[1mDownloading and extracting OpenCV-contrib-$VERSION \e[0m"
    echo

    cd
    wget -O opencv_contrib-"${VERSION}".zip https://github.com/opencv/opencv_contrib/archive/"${VERSION}".zip --no-verbose
    unzip $FLAG_VERBOSE opencv_contrib-"${VERSION}" && rm opencv_contrib-"${VERSION}".zip
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
    echo "In $PWD"
    mkdir -p build
    cd build
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib-"${VERSION}"/modules \
        -D BUILD_DOCS=OFF \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_JAVA=OFF \
        -D BUILD_opencv_apps=OFF \
        -D BUILD_opencv_dpm=OFF \
        -D BUILD_opencv_dnn=OFF \
        -D BUILD_opencv_dnn_objdetect=OFF \
        -D BUILD_opencv_java_bindings_gen=OFF \
        -D BUILD_opencv_python2=OFF \
        -D BUILD_opencv_python3=ON \
        -D BUILD_PERF_TESTS=OFF \
        -D BUILD_TESTS=OFF \
        -D CUDA_ARCH_BIN="${ARCH_BIN}" \
        -D CUDA_ARCH_PTX="" \
        -D INSTALL_C_EXAMPLES=OFF \
        -D INSTALL_PYTHON_EXAMPLES=OFF \
        -D WITH_TBB=ON \
        -D WITH_OPENMP=ON \
        -D WITH_IPP=ON \
        -D WITH_NVCUVID=ON \
        -D WITH_CUDA="${FLAG_CUDA}" \
        -D ENABLE_FAST_MATH=ON \
        -D CUDA_FAST_MATH=ON \
        -D WITH_CUBLAS=ON \
        -D WITH_LIBV4L=ON \
        -D WITH_GSTREAMER=ON \
        -D WITH_GSTREAMER_0_10=OFF \
        -D WITH_QT=ON \
        -D WITH_OPENGL=ON \
        -D WITH_CSTRIPES=ON \
        -D WITH_OPENCL=ON \
        -D WITH_VTK=ON \
        -D OPENCV_ENABLE_NONFREE=ON \
        -D OPENCV_GENERATE_PKGCONFIG=ON \
        -D PYTHON_DEFAULT_EXECUTABLE=/usr/bin/python3 ..

#        -D OPENCV_GENERATE_PKGCONFIG=ON \
#        -D OPENCV_PYTHON3_VERSION=ON \

#        -D CMAKE_INSTALL_PREFIX=~/.venvs/cv \
#        -D PYTHON_EXECUTABLE=~/.venvs/cv/bin/python \

}


make_opencv()
{
    echo
    echo -e "\e[35m\e[1mBuilding OpenCV-$VERSION \e[0m"
    echo

    cd $OPENCVHOME/build

    if [ "$SWAPSIZE_FLAG" == 1 ]
    then
        sudo sed -i "s/$SWAPSIZE/CONF_SWAPSIZE=1024/g" /etc/dphys-swapfile
        sudo systemctl restart dphys-swapfile
    fi

    make -j $(($(nproc) - 1))

    if [ "$SWAPSIZE_FLAG" == 1 ]
    then
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

    CVV="$(python3 -c "import cv2; print(cv2.__version__)")"

    if [ "$CVV" != "$VERSION" ]
    then
        echo -e "\e[33m\e[1mInstallation failure \e[0m"
    else
        echo -e "\e[33m\e[1mOpenCV-$VERSION successfully installed \e[0m"
    fi
}

install_complete()
{
    install_dependencies
    download_opencv
#    install_virtualenv
    config_cmake

    echo -e "\e[35m\e[1mExamine the output of CMake before continuing \e[0m"
    read -n1 -rsp $'Press space to continue...\n' key
    while [ "$key" != '' ]
    do
        :
    done

    make_opencv
    install_opencv
    check_install
}

# Read Postional Parameters
if [ -z "$1" ]
then
    usage
else
    while [ "$1" != "" ]
    do
        case $1 in
            -d | --device )
                shift
                case $1 in
                    rpi3 )
                        DEVICE="rpi3"
                        FLAG_CUDA=OFF ;;

                    jetsontx1 )
                        DEVICE="jetsontx1"
                        FLAG_CUDA=ON
                        ARCH_BIN="5.3" ;;

                    jetsontx2 )
                        DEVICE="jetsontx2"
                        FLAG_CUDA=ON
                        ARCH_BIN="6.2"
                        sudo patch -N /usr/local/cuda/include/cuda_gl_interop.h $SOURCE_DIR/patches/jetsontx2/OpenGLHeader.patch
                        sudo ln -sfn /usr/lib/aarch64-linux-gnu/tegra/libGL.so /usr/lib/aarch64-linux-gnu/libGL.so
 ;;

                    desktop )
                        DEVICE="desktop"
                        FLAG_CUDA=OFF ;;

                    desktop-with-cuda )
                        DEVICE="desktop-with-cuda"
                        FLAG_CUDA=ON
                        # Quadro M1200 Architecture
                        ARCH_BIN="5.0" ;;
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

            -h | --help )
                usage
                exit 1 ;;

            * )
                usage
                exit 1 ;;
        esac
        shift
    done
fi
