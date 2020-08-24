FROM debian:stretch

ENV MKDOMOTICZ_UPDATED=20200427

ARG DOMOTICZ_VERSION="master"

# install packages
RUN apt-get update && apt-get install -y \
make \
gcc \
g++ \
libcurl4-gnutls-dev \
libcereal-dev \
liblua5.3-dev \
uthash-dev \
wget \
git \
libssl1.0.2 libssl-dev \
build-essential \
libboost-all-dev \
libsqlite3-0 \
libsqlite3-dev \
curl \
libcurl3 \
libusb-0.1-4 \
libusb-dev \
zlib1g-dev \
libudev-dev \
python3-dev \
python3-pip \
fail2ban
# linux-headers-generic
## install cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v3.17.0/cmake-3.17.0.tar.gz && \
tar -xzvf cmake-3.17.0.tar.gz && \
rm cmake-3.17.0.tar.gz && \
cd cmake-3.17.0 && \
./bootstrap && \
make && \
make install && \
cd .. && \
rm -Rf cmake-3.17.0

## OpenZwave installation
# grep git version of openzwave
RUN git clone --depth 2 https://github.com/OpenZWave/open-zwave.git /src/open-zwave && \
cd /src/open-zwave && \
# compile
make && \
make install && \

# "install" in order to be found by domoticz
ln -s /src/open-zwave /src/open-zwave-read-only
# Liboost

RUN apt remove -y --purge --auto-remove libboost-dev libboost-thread-dev libboost-system-dev libboost-atomic-dev libboost-regex-dev libboost-chrono-dev && \
mkdir boost && cd boost && wget https://dl.bintray.com/boostorg/release/1.72.0/source/boost_1_72_0.tar.gz && tar xfz boost_1_72_0.tar.gz && \
cd boost_1_72_0/ && ./bootstrap.sh && ./b2 stage threading=multi link=static --with-thread --with-system && ./b2 install threading=multi link=static --with-thread --with-system && \
cd ../../ && rm -Rf boost/

# install python3.6
RUN apt-get update && apt-get install -y build-essential tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev libdb5.3-dev libgdbm-dev libsqlite3-dev libssl-dev && \
libexpat1-dev liblzma-dev zlib1g-dev && \
wget https://www.python.org/ftp/python/3.6.8/Python-3.6.8.tgz && \
tar zxf Python-3.6.8.tgz && \
cd Python-3.6.8 && \
./configure && \
make -j 4 && \
make altinstall

COPY bashrc ~/.bashrc

## Install python-miio
RUN pip3 install -U python-miio && \
cd /src/domoticz/plugins/ && git clone https://github.com/deennoo/domoticz-Xiaomi-Led-Lamp.git && chmod 777 /src/domoticz/plugins/domoticz-Xiaomi-Led-Lamp/MyBulb.py
## Domoticz installation
# clone git source in src


RUN git clone -b "${DOMOTICZ_VERSION}" --depth 2 https://github.com/domoticz/domoticz.git /src/domoticz && \
# Domoticz needs the full history to be able to calculate the version string
cd /src/domoticz && \
git fetch --unshallow && \
# prepare makefile
cmake -DCMAKE_BUILD_TYPE=Release . && \
# compile
make && \
# Install
# install -m 0555 domoticz /usr/local/bin/domoticz && \
cd /tmp && \
# Cleanup
# rm -Rf /src/domoticz && \

# ouimeaux
pip3 install -U ouimeaux

# add zigbee2mqtt plugin
RUN cd /src/domoticz && \
git clone https://github.com/stas-demydiuk/domoticz-zigbee2mqtt-plugin.git zigbee2mqtt

# remove git and tmp dirs

RUN apt-get remove -y linux-headers-amd64 build-essential libssl-dev libboost-dev libboost-thread-dev libboost-system-dev libsqlite3-dev libcurl4-openssl-dev libusb-dev zlib1g-dev libudev-dev && \
apt-get autoremove -y && \ 
apt-get clean && \
rm -rf /var/lib/apt/lists/*

VOLUME /config

EXPOSE 8080

COPY start.sh /start.sh

#ENTRYPOINT ["/src/domoticz/domoticz", "-dbase", "/config/domoticz.db", "-log", "/config/domoticz.log"]
#CMD ["-www", "8080"]
CMD [ "/start.sh" ]
