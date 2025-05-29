#!/bin/bash
sudo yum groupinstall "Development Tools" -y && \
sudo ln -s $(which python3) /usr/bin/python && \
sudo python3 -m ensurepip --upgrade && \
sudo python3 -m pip install --upgrade pip && \
sudo python3 -m pip install packaging && \
cd /opt && \
wget https://files.pythonhosted.org/packages/source/a/ansible/ansible-2.9.27.tar.gz && \
cd /usr/local && \
sudo tar -xvzf /opt/ansible-2.9.27.tar.gz && \
cd /usr/local/ansible-2.9.27 && \
sudo make && \
sudo make install && \
sudo yum install git -y && \
cd /home/ec2-user && \


