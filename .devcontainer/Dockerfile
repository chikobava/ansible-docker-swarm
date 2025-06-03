FROM ghcr.io/ansible/community-ansible-dev-tools:latest

ARG USERNAME=ansible
ARG UUID=1000

RUN groupadd -g $UUID $USERNAME && \
    useradd -u $UUID -g $UUID -m $USERNAME -s /bin/bash 

USER ansible