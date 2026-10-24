FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-client \
    sshpass \
    nmap \
    hydra \
    netcat-openbsd \
    curl \
    wget \
    python3 \
    python3-pip \
    iputils-ping \
    dnsutils \
    vim \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /scenarios

CMD ["sleep", "infinity"]
