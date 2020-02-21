#!/bin/bash -xe
# This expects to be run as root/sudo

ANSIBLE_VERSION="Version: 2.9.4-1ppa~xenial"

# Vars from infrastructure.py, hacked for sh:

op_env="dev"
# ec2_tarball_url_base = config['AWS']['ec2_tarball_url_base']
ec2_tarball_url_base="http://code.dev.nasawestprime.com/avail/"
ec2_tarball_pipeline_file="avail_pipeline.tgz"
ec2_tarball_pipeline_url="${ec2_tarball_url_base}avail_pipeline/${op_env}/latest/${ec2_tarball_pipeline_file}"
ec2_tarball_pipeline_sh="misc/bootstrap_pipeline.sh"
ec2_tarball_build_dir="/avail_build"

# Variable expansions below translated from python to sh

export op_env=${op_env}

# pip installation of cryptography needs
#$ sudo yum install gcc libffi-devel python-devel openssl-devel
# 'cryptography' no longer supports openssl-1.0.1, this installs 1.0.2
#echo "LIBFFI..."
#sudo apt-get install -y build-essential libssl-dev libffi-dev python-dev
#sudo apt-get install -y libffi-devel
#AttributeError: 'module' object has no attribute 'Cryptography_HAS_SSL_ST'

# cffi can't find ffi.h, needs libffi-dev
sudo apt-get install -y libffi-dev
sudo easy_install -U cffi
sudo easy_install -U cryptography

# There's a problem with U16's pip2 which is used by misc/bootstrap_pipeline.sh
# this fix, if it works, should go into that file probably.
# I thought this worked but maybe not:
#sudo python -m easy_install --upgrade pyOpenSSL==19.1.0
#   File "build/bdist.linux-x86_64/egg/OpenSSL/SSL.py", line 199, in <module>
# AttributeError: 'module' object has no attribute 'Cryptography_HAS_SSL_ST'
apt-get --auto-remove remove python-openssl
pip install pyOpenSSL

# And another when invoking system pip(2) fails:
# TypeError: from_buffer() cannot return the address of the raw string within
# a str or unicode or bytearray object
# https://github.com/ansible/ansible/issues/43976
# sudo pip uninstall cryptography
# sudo pip install paramiko
# sudo pip install cryptography -U


# Our current userdata removes MPG and pip installs old:
apt-get -y remove ansible
pip install ansible==2.1.5.0
# Use the MPG approach to get latest ansible 2.9.4-1 instead of pip install ancient
# sudo apt-add-repository --yes --update ppa:ansible/ansible
# sudo apt -y install ansible
# av==$(dpkg -s ansible|grep Version:)
# if [ "$av" != "${ANSIBLE_VERSION}" ]
# then
#   echo "WARNING unexpected Ansible version='${av}'"
# fi



mkdir ${ec2_tarball_build_dir}
cd ${ec2_tarball_build_dir}
curl --location -o ${ec2_tarball_pipeline_file} ${ec2_tarball_pipeline_url}
tar zxf ${ec2_tarball_pipeline_file}
sh ${ec2_tarball_pipeline_sh}

cat ${ec2_tarball_build_dir}/misc/rc.local > /etc/rc.local
ln -s ${ec2_tarball_build_dir}/misc/complete-lifecycle-hook.sh /etc/init.d/

echo NOT rebooting for our testing
# reboot
