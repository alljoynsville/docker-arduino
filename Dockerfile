FROM debian:stretch-slim

# Version of arduino IDE
ARG VERSION="1.8.7"

ARG SSH_KEY_FILE=""

# Version of Arduino IDE to download
ENV ARDUINO_VERSION=$VERSION

# Where Arduino IDE should be installed
ENV ARDUINO_DIR="/opt/arduino"

# Arduino built-in examples
ENV ARDUINO_EXAMPLES="${ARDUINO_DIR}/examples"

# Arduino hardware
ENV ARDUINO_HARDWARE="${ARDUINO_DIR}/hardware"

# Arduino built-in libraries
ENV ARDUINO_LIBS="${ARDUINO_DIR}/libraries"

# Arduino tools
ENV ARDUINO_TOOLS="${ARDUINO_HARDWARE}/tools"

# Arduino tools-builder
ENV ARDUINO_TOOLS_BUILDER="${ARDUINO_DIR}/tools-builder"

# Arduino boards FQBN prefix
ENV A_FQBN="arduino:avr"

# Binary directory
ENV A_BIN_DIR="/usr/local/bin"

# Tools directory
ENV A_TOOLS_DIR="/opt/tools"

# Home directory
ENV A_HOME="/root"

ENV A_ARDUINO_CLI_NAME="arduino-cli-0.3.1-alpha.preview-linux64"

# Shell
SHELL ["/bin/bash","-c"]

# Working directory
WORKDIR ${A_HOME}

# Get updates and install dependencies
RUN dpkg --add-architecture i386
RUN apt-get update && \
    apt-get install python3-pip wget tar xz-utils git xvfb libc6:i386 libncurses5:i386 libstdc++6:i386 -y && \
    apt-get clean && rm -rf /var/lib/apt/list/*

RUN pip3 install nrfutil adafruit-nrfutil

# Get and install Arduino IDE
RUN wget -q https://downloads.arduino.cc/arduino-${ARDUINO_VERSION}-linux64.tar.xz -O arduino.tar.xz && \
    tar -xf arduino.tar.xz && \
    rm arduino.tar.xz && \
    mv arduino-${ARDUINO_VERSION} ${ARDUINO_DIR} && \
    ln -s ${ARDUINO_DIR}/arduino ${A_BIN_DIR}/arduino && \
    ln -s ${ARDUINO_DIR}/arduino-builder ${A_BIN_DIR}/arduino-builder && \
    echo "${ARDUINO_VERSION}" > ${A_ARDUINO_DIR}/version.txt

RUN wget -q https://downloads.arduino.cc/arduino-cli/${A_ARDUINO_CLI_NAME}.tar.bz2 -O arduino-cli.tar.bz2 && \
    tar -xvjf arduino-cli.tar.bz2 && \
    rm arduino-cli.tar.bz2 && \
    mv ${A_ARDUINO_CLI_NAME} -t ${ARDUINO_DIR} && \
    ln -s ${ARDUINO_DIR}/${A_ARDUINO_CLI_NAME} ${A_BIN_DIR}/arduino-cli 

# Install additional commands & directories
RUN mkdir ${A_TOOLS_DIR}
COPY tools/* ${A_TOOLS_DIR}/
RUN chmod +x ${A_TOOLS_DIR}/* && \
    ln -s ${A_TOOLS_DIR}/* ${A_BIN_DIR}/ && \
    mkdir ${A_HOME}/Arduino && \
    mkdir ${A_HOME}/Arduino/libraries && \
    mkdir ${A_HOME}/Arduino/hardware && \
    mkdir ${A_HOME}/Arduino/tools


# Install additional Arduino boards and libraries
RUN arduino_add_board_url https://adafruit.github.io/arduino-board-index/package_adafruit_index.json,http://arduino.esp8266.com/stable/package_esp8266com_index.json && \
    arduino_install_board arduino:sam && \
    arduino_install_board arduino:samd && \
    arduino_install_board esp8266:esp8266 && \
    arduino_install_board adafruit:avr && \
    arduino_install_board adafruit:samd && \
    arduino_install_board adafruit:nrf52 && \
    arduino --pref "compiler.warning_level=all" --save-prefs 2>&1

RUN echo "${A_HOME}/.arduino15/packages" >> "${A_HOME}/arduino_hardware.txt"
RUN echo "${A_HOME}/.arduino15/packages" >> "${A_HOME}/arduino_tools.txt"
RUN ls ${A_HOME}

RUN arduino-cli lib install "Adafruit ZeroTimer Library@1.0.0"
RUN arduino-cli lib install Sodaq_wdt
RUN arduino-cli lib install arduino-NVM
RUN arduino_install_lib https://eyal_cot@bitbucket.org/cloudofthings/radiohead.git,https://github.com/adafruit/Adafruit_ASFcore.git
# Crypto is not only in a specific version it's also not comming from arduino but from platform io packages, 
# we need to clone, cehckout the version and copy just the directory we need!
RUN cd /tmp && git clone https://github.com/rweather/arduinolibs.git && cd arduinolibs && \
    git checkout 27ad81051d81e29906c9738a22f1d75ab80c36b0 && \
    mv libraries/Crypto ${A_HOME}/Arduino/libraries
