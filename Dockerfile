FROM debian:stretch

ENV MKDOMOTICZ_UPDATED=20190316

ARG DOMOTICZ_VERSION="master"

# install packages
RUN apt-get update && apt-get install -y \
make \
gcc \
g++ \
libcurl4-gnutls-dev \
libcereal-dev \
liblua5.3-dev \
uthash-dev\
wget \
git \
libssl1.0.2 libssl-dev \
build-essential \
libboost-all-dev \
libsqlite3-0 \
libsqlite3-dev \
curl \
libcurl3 \
libcurl4-openssl-dev \
libusb-0.1-4 \
libusb-dev \
zlib1g-dev \
libudev-dev \
python3-dev \
python3-pip \
fail2ban && \
    # linux-headers-generic
## install cmake
wget https://github.com/Kitware/CMake/releases/download/v3.17.0/cmake-3.17.0.tar.gz && \
tar -xzvf cmake-3.17.0.tar.gz && \
rm cmake-3.17.0.tar.gz && \
cd cmake-3.17.0 && \
./bootstrap && \
make && \
make install && \
cd .. && \
rm -Rf cmake-3.17.0 && \

## OpenZwave installation
# grep git version of openzwave
git clone --depth 2 https://github.com/OpenZWave/open-zwave.git /src/open-zwave && \
cd /src/open-zwave && \
# compile
make && \

# "install" in order to be found by domoticz
ln -s /src/open-zwave /src/open-zwave-read-only && \

## Domoticz installation
# clone git source in src
git clone -b "${DOMOTICZ_VERSION}" --depth 2 https://github.com/domoticz/domoticz.git /src/domoticz && \
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
pip3 install -U ouimeaux && \

# add zigbee2mqtt plugin
cd /src/domoticz && \
git clone https://github.com/stas-demydiuk/domoticz-zigbee2mqtt-plugin.git zigbee2mqtt && \

# remove git and tmp dirs
apt-get remove -y linux-headers-amd64 build-essential libssl-dev libboost-dev libboost-thread-dev libboost-system-dev libsqlite3-dev libcurl4-openssl-dev libusb-dev zlib1g-dev libudev-dev && \
apt-get autoremove -y && \ 
apt-get clean && \
rm -rf /var/lib/apt/lists/*


VOLUME /config

EXPOSE 8080

COPY start.sh /start.sh

#ENTRYPOINT ["/src/domoticz/domoticz", "-dbase", "/config/domoticz.db", "-log", "/config/domoticz.log"]
#CMD ["-www", "8080"]
CMD [ "/start.sh" ]
