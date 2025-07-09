#!/bin/bash
# 개발 도구 설치
sudo dnf groupinstall "Development Tools" -y && \
sudo ln -s $(which python3) /usr/bin/python && \
sudo python3 -m ensurepip --upgrade && \
sudo python3 -m pip install --upgrade pip && \
sudo python3 -m pip install packaging
# ansible 설치
cd /opt
sudo wget https://files.pythonhosted.org/packages/source/a/ansible/ansible-2.9.27.tar.gz && \
sudo tar -xvzf ansible-2.9.27.tar.gz && \
cd ansible-2.9.27 && \
sudo make && \
sudo make install
# git 설치
sudo dnf install git -y
# java 설치
sudo dnf install -y java-17-amazon-corretto-devel

# 홈 디렉토리로 이동
cd /home/ec2-user
git clone https://github.com/ehdrn3020/kafka_connect_cdc.git