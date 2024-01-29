FROM linuxmintd/mint21-amd64

#============================
# xdotool 
#============================
RUN apt-get update && apt-get install -y libxtst-dev libxinerama-dev xvfb x11vnc wmctrl xterm 
#RUN apt-get update && apt-get install -y libxtst-dev libxinerama-dev xserver-xephyr x11vnc wmctrl xterm 
RUN apt-get install -y ruby 
RUN apt-get install -y dbus-x11 awesome

ADD xdotool-master.zip xdotool-src/
RUN cd xdotool-src && unzip xdotool-master && cd xdotool-master && make && make install

#=========================
# Node Version Manager 
#   Nodejs, npm
#
# https://www.linode.com/docs/guides/how-to-install-use-node-version-manager-nvm/
#=========================
RUN cd /root && wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash && . /root/.bashrc && nvm install node

#=========================
# Appium
#=========================
# from https://dev.to/testwithblake/a-step-by-step-guide-to-test-automation-with-appium-2nmf
# See https://github.com/appium/appium-uiautomator2-driver
RUN . /root/.bashrc && npm install -g appium -g appium-doctor && \
     appium driver install uiautomator2


#========================
# SDKMAN
# https://sdkman.io/install
#========================
RUN curl -s "https://get.sdkman.io" | bash

# Install dependencies
RUN apt-get install -y openjdk-17-jdk 

#=========================
# Android Studio
# https://developer.android.com/studio/install
#=========================
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386
RUN wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.28/android-studio-2023.1.1.28-linux.tar.gz --progress=dot:giga  -O android-studio.tar.gz
RUN cd /usr/local && tar xzvf /android-studio.tar.gz
RUN rm android-studio.tar.gz

ENV ANDROID_HOME=/usr/local/android-studio
#=========================
# Copying Scripts to root
#=========================
COPY start_vnc_hs.sh /
RUN chmod a+x start_vnc_hs.sh



#=======================
# framework entry point
#=======================
CMD [ "/bin/bash" ]
