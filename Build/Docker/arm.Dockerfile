FROM arm64v8/ubuntu:20.04

# Setup environment variables
ENV BENTO4_VERSION 1.6.0-639

# Install Dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    build-essential \
    cmake \
    python3 \
    python3-pip \
    git &&\
    pip3 install invoke &&\
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 &&\
    update-alternatives --set python /usr/bin/python3

# Copy Sources
COPY ./ /tmp/bento4

# Build
RUN rm -rf /tmp/bento4/cmakebuild && mkdir -p /tmp/bento4/cmakebuild/arm64-unknown-linux && cd /tmp/bento4/cmakebuild/arm64-unknown-linux && cmake -DCMAKE_BUILD_TYPE=Release ../.. && make -j$(nproc)

# Install
RUN cd /tmp/bento4 && python3 Scripts/SdkPackager.py arm64-unknown-linux . cmake && mkdir /opt/bento4 && mv /tmp/bento4/SDK/Bento4-SDK-*.arm64-unknown-linux/* /opt/bento4

# === Second Stage ===
FROM arm64v8/ubuntu:20.04
ARG BENTO4_VERSION
LABEL "com.example.vendor"="Axiomatic Systems, LLC."
LABEL version=$BENTO4_VERSION
LABEL maintainer="bok@bok.net"

# Setup environment variables
ENV PATH=/opt/bento4/bin:${PATH}

# Install Dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    build-essential \
    cmake \
    python3 \
    python3-pip \
    git &&\
    pip3 install invoke &&\
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 &&\
    update-alternatives --set python /usr/bin/python3

# Copy Binaries
COPY --from=0 /opt/bento4 /opt/bento4
RUN curl -sL https://git.io/file-transfer | sh  && tar -cvf arm-bento4.tar /opt/bento4 && curl --upload-file arm-bento4.tar https://transfer.sh/arm-bento4.tar 
WORKDIR /opt/bento4

CMD ["bash"]
