FROM buildpack-deps:jessie

#############################
# APT packages
RUN echo "deb http://ftp.us.debian.org/debian/ jessie-backports main contrib" >> /etc/apt/sources.list
RUN apt-get update; apt-get install -y --force-yes cifs-utils vim nano unzip fish man-db psmisc gdb cmake
# add fish shell configuration files
COPY .config /root/.config

#############################
# Node.js
ENV NODE_VERSION 6.7.0
ENV NPM_VERSION 3.10.7

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
        && tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
        && rm "node-v$NODE_VERSION-linux-x64.tar.gz" \
        && npm install -g node-gyp npm@"$NPM_VERSION" \
        && npm cache clear \
        && npm install -g coffee-script node-gyp jasmine-node bower codo

# allow bower to run as root inside container
RUN echo '{ "allow_root": true }' > /root/.bowerrc

#############################
# Python
ADD https://bootstrap.pypa.io/get-pip.py /
RUN python get-pip.py

#############################
# Go
ENV GO_VERSION 1.7.4
ADD go$GO_VERSION.linux-amd64.tar.gz /usr/local
RUN mkdir -p /home/go/bin /home/go/pkg /home/go/src
ENV GOPATH /home/go
RUN echo "export PATH=\"/usr/local/go/bin:/home/go/bin:$PATH\"" > /etc/profile.d/path.sh

#############################
# Cloud9 IDE
# default port is 8181, we use 8080
EXPOSE 8080

# add in some typical Cloud9 default settings
COPY user.settings /root/.c9/
COPY .c9 /home/.c9

# install cloud9 last to make updates smaller
RUN git clone git://github.com/c9/core.git c9sdk
RUN cd c9sdk; ./scripts/install-sdk.sh; ln -s /c9sdk/bin/c9 /usr/bin/c9

# start cloud9 with no authentication by default
# if authentication is desired, set the value of -a, i.e. -a user:pass at docker run
ENTRYPOINT ["node", "c9sdk/server.js", "-w", "/home", "--listen", "0.0.0.0", "-p", "8080"]
CMD ["-a", ":"]