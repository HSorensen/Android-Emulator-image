FROM linuxmintd/mint21-amd64

#============================
# xdotool 
#============================
RUN apt-get update && apt-get install -y libxtst-dev libxinerama-dev xvfb x11vnc wmctrl xterm bash
#RUN apt-get update && apt-get install -y libxtst-dev libxinerama-dev xserver-xephyr x11vnc wmctrl xterm 
RUN apt-get install -y ruby 
RUN apt-get install -y dbus-x11 cinnamon

ADD xdotool-master.zip xdotool-src/
RUN cd xdotool-src && unzip xdotool-master && cd xdotool-master && make && make install

#=========================
# Node Version Manager 
#   Nodejs, npm
#
# https://www.linode.com/docs/guides/how-to-install-use-node-version-manager-nvm/
#=========================
RUN cd /root && wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash 
RUN . /root/.bashrc && nvm install node

#=========================
# Appium
#=========================
# from https://dev.to/testwithblake/a-step-by-step-guide-to-test-automation-with-appium-2nmf
# See https://github.com/appium/appium-uiautomator2-driver
RUN apt-get install -y ffmpeg libfuse2 firefox
RUN . /root/.bashrc && npm install -g appium -g appium-doctor -g mjpeg-consumer && \
     appium driver install uiautomator2 

# Install gstreamer1.0
RUN apt-get install -y gstreamer1.0*

# Install bundle tool jar into /usr/local/bin, and mark executable
RUN wget https://github.com/google/bundletool/releases/download/1.15.6/bundletool-all-1.15.6.jar -O bundletool.jar --progress=dot:giga \
  && mv bundletool.jar /usr/local/bin && chmod ugo+x /usr/local/bin/bundletool.jar

# Install appium inspector
# from https://github.com/appium/appium-inspector
RUN wget https://github.com/appium/appium-inspector/releases/download/v2023.12.2/Appium-Inspector-linux-2023.12.2.AppImage -O /root/Appium-Inspector-linux.AppImage --progress=dot:giga \
  && chmod a+x /root/Appium-Inspector-linux.AppImage

#========================
# SDKMAN
# https://sdkman.io/install
#========================
SHELL ["/bin/bash","-c"] 
RUN curl -s "https://get.sdkman.io" | bash

# Install dependencies
# Install JDK
RUN source "/root/.sdkman/bin/sdkman-init.sh" && sdk install java 17.0.10-tem
ENV JAVA_HOME=/root/.sdkman/candidates/java/current

#=========================
# Android Studio
# https://developer.android.com/studio/install
#=========================
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386
RUN wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.28/android-studio-2023.1.1.28-linux.tar.gz --progress=dot:giga  -O android-studio.tar.gz
RUN cd /usr/local && tar xzvf /android-studio.tar.gz
RUN rm android-studio.tar.gz

# ENV ANDROID_HOME=/usr/local/android-studio
ENV ANDROID_HOME=/root/Android/Sdk
ENV ANDROID_SDK_ROOT=/root/Android/Sdk

#=========================
# Android Tools
#=========================
# The Android Studio is installed when the container is running. 
# Prepare the commandline tools to me installed when the container is running.
ARG ANDROID_CMD="commandlinetools-linux-10406996_latest.zip"
RUN wget --progress=dot:giga https://dl.google.com/android/repository/${ANDROID_CMD} -O /root/cmdline-tools.zip \
             && cd /root && unzip cmdline-tools.zip \
             && rm /root/cmdline-tools.zip
#ARG ANDROID_CMD="commandlinetools-linux-10406996_latest.zip"
#RUN wget --progress=dot:giga https://dl.google.com/android/repository/${ANDROID_CMD} -O /root/cmdline-tools.zip \
#             && mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/tools \
#             && unzip -d $ANDROID_SDK_ROOT /cmdline-tools.zip \
#             && cd $ANDROID_SDK_ROOT/cmdline-tools && mv NOTICE.txt source.properties bin lib tools/ \
#             && cd $ANDROID_SDK_ROOT/cmdline-tools/tools && ls
#==============================
# Prepare Path for Andriod SDK
#==============================
ENV PATH "$PATH:$ANDROID_SDK_ROOT/cmdline-tools/bin:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/build-tools/${BUILD_TOOLS}"

#===============================
# Install Intellij Communication
#===============================
# From https://download.jetbrains.com/idea/ideaIC-2023.3.3-aarch64.tar.gz
# Install into /opt
RUN wget --progress=dot:giga https://download.jetbrains.com/idea/ideaIC-2023.3.3-aarch64.tar.gz -O /root/ideaIC-aarch64.tar.gz \
  && tar -xzf /root/ideaIC-*.tar.gz -C /opt \
  && rm /root/ideaIC-*.tar.gz

#=========================
# Copying Scripts to root
#=========================
COPY start_vnc_hs.sh /
RUN chmod a+x start_vnc_hs.sh

#=======================
# framework entry point
#=======================
CMD [ "/bin/bash" ]

#https://anivaz.medium.com/how-to-set-up-appium-with-android-studio-for-mobile-app-testing-a300b7910364
#https://medium.com/propertyfinder-engineering/mobile-app-automation-setup-appium-android-studio-20668c254899
#https://appium.io/docs/en/2.4/guides/caps/#