#!/bin/sh

IMAGE_NAME=`basename $0 .sh | tr [A-Z] [a-z]`
TARGET=`basename $PWD`

mkdir -p build

cat << _EOF_ > build/Dockerfile

FROM ubuntu:18.04
ENV DISPLAY=:0
RUN apt-get -y update
RUN apt-get -y install curl
RUN apt-get -y install xz-utils
RUN curl -L "https://www.arduino.cc/download.php?f=/arduino-1.8.13-linux64.tar.xz" -O
RUN tar -xf arduino-1.8.13-linux64.tar.xz
RUN apt-get -y install xserver-xorg-video-dummy x11-apps
RUN curl -L http://xpra.org/xorg.conf -O 
RUN mv xorg.conf /etc
RUN apt-get -y install sudo
RUN apt-get -y install libxtst6
RUN rm -f /bin/sh && ln /bin/bash /bin/sh
RUN apt-get -y install libxi6
RUN /arduino-1.8.13/arduino-linux-setup.sh root
RUN /arduino-1.8.13/arduino --get-pref > /root/tmp
RUN curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR=/usr/bin sh
RUN /usr/bin/arduino-cli update

RUN /arduino-1.8.13/arduino --get-pref > /root/.arduino15/preferences.txt
RUN echo "boardsmanager.additional.urls=http://arduino.esp8266.com/stable/package_esp8266com_index.json" >> /root/.arduino15/preferences.txt
RUN /arduino-1.8.13/arduino --install-boards esp8266:esp8266

RUN echo "#!/bin/sh" > /root/init
# RUN echo "/usr/bin/Xorg &" >> /root/init
RUN echo "cd /root" >> /root/init
RUN echo "ln -s build $TARGET" >> /root/init
RUN echo "cd $TARGET" >> /root/init

RUN echo "echo Compiling...." >> /root/init
RUN echo "arduino-cli compile --build-path \`pwd\` -b esp8266:esp8266:d1 --build-properties compiler.cpp.extra_flags=-I." >> /root/init

RUN echo "cp \\\`find build -name $TARGET*.bin\\\` ." >> /root/init
RUN echo "cp \\\`find ~/.arduino15 -name esptool.py\\\` build" >> /root/init
RUN echo "cp \\\`find ~/.arduino15 -name espota.py\\\` build" >> /root/init
# RUN echo "/bin/sh" >> /root/init

RUN chmod +x /root/init
CMD /root/init
_EOF_

echo "*******************************************************"
echo "*														"
echo "* Build / Prepare build machine as $IMAGE_NAME"
echo "*														"
echo "*******************************************************"
docker build build -t $IMAGE_NAME

echo "*******************************************************"
echo "*														"
echo "* Running build machine"
echo "*														"
echo "*******************************************************"
docker run -e -it -v $PWD:/root/build $IMAGE_NAME

