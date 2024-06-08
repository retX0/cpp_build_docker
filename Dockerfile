FROM ubuntu:20.04

# Set environment variables for tzdata to avoid interactive configuration
ENV DEBIAN_FRONTEND=noninteractive

# Install tzdata and other packages
RUN apt-get update && \
    apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Install development tools and other dependencies
RUN apt-get update && \
    apt-get install -y curl zip unzip tar \
    libz-dev libcurl4-openssl-dev libssl-dev libuv1-dev libz-dev uuid-dev \
    git cmake gcc g++ build-essential pkg-config \
    autoconf automake autoconf-archive python3

# Set environment variables for cmake and compilers
ENV CMAKE_TOOLCHAIN_FILE=/vcpkg/scripts/buildsystems/vcpkg.cmake
ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++

# install boost
WORKDIR /tmp/boost_installer
RUN BOOST_VERSION=1.69.0 && \
    BOOST_VERSION_UNDERSCORE=$(echo $BOOST_VERSION | sed 's/\./_/g') && \
    curl "https://archives.boost.io/release/$BOOST_VERSION/source/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz" -o boost.tar.gz && \
    tar xzf boost.tar.gz && \
    mkdir -p boost && \
    tar xzf boost.tar.gz -C boost --strip-components=1 && \
    cd boost && \
    ./bootstrap.sh && \
    ./b2 && ./b2 install
    
WORKDIR /
RUN rm -rf /tmp/boost_installer

# Set working directory

# Argument for vcpkg version
ARG VCPKG_VERSION=2024.05.24

ENV VCPKG_DOWNLOADS_RETRIES=10

# Clone the specified version of vcpkg repository
RUN git clone --single-branch --depth=1 -b ${VCPKG_VERSION} https://github.com/microsoft/vcpkg.git

# Set working directory to vcpkg
WORKDIR /vcpkg

# Bootstrap vcpkg
RUN ./bootstrap-vcpkg.sh

# Copy vcpkg.json to the vcpkg directory
COPY vcpkg.json /vcpkg/vcpkg.json

# Install packages listed in vcpkg.json
RUN ./vcpkg install

# Integrate vcpkg with the system
RUN ./vcpkg integrate install

# Set working directory to root
WORKDIR /root/

# Set default command to bash
CMD ["/bin/bash"]
