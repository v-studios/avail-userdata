#!/usr/bin/env bash
# Update packages, create venv, install avail_pipeline ansible playbook.
#
# The UserData script runs as root and currently untars into /
# so don't change directory here; do it CloudFormation later.
#
# Ubuntu has python-3.4 installed, with pyvenv-3.4
# Install pip, virtualenv
# Install avail and dependencies from local wheelhouse
#
# TODO:
# - startup various processes for the instance.
# - Should I do the cfn-signal ... by getting StackName and Region from CLI?

# Import common ENV vars
. misc/avail.env

# turn on verbose mode and fail-fast mode.
set -x
set -e

echo "# whoami=`whoami` pwd=`pwd`"

# Need apt-get update to ensure current package list
# ** No "apt-get upgrade" to ensure package versions aren't installing new  ** 
# ** package versions and breaking functionality during auto-scale deploys  **
echo "# Apt update, install ansible"
sudo apt-get -y update

# Run MPG patching ansible-playbook
# Enter patching playbook directory
cd system-patching
if [ $? != 0 ]; then
    echo "FAILED to enter patching directory" 1>&2
    exit 1
fi

# Ensure jinja2 package is installed
pip install jinja2
if [ $? != 0 ]; then
    echo "FAILED to pip install jinja2 package" 1>&2
    exit 1
fi

# Run patching playbook, without reboot
ansible-playbook PatchSystems.yaml -e "hosts=localhost reboot=false"
if [ $? != 0 ]; then
    echo "FAILED to run ansible patching playbook" 1>&2
    exit 1
fi
# Go back to /avail_build directory to continue
cd /avail_build

# Don't install ansible because it already exists in the baseline AMI
#sudo apt-get -y install ansible

echo "# Run ansible setup playbook"
cd bootstrap/ansible
ansible-playbook -i hosts -l ${PACKAGE} setup.yml -e op_env=$op_env
if [ $? != 0 ]; then
    echo "FAILED to run ansible setup playbook" 1>&2
    exit 1
fi
# Leave Ansible directory in case we want to add more tasks below later.
# shell doesn't understand pushd/popd, so use "cd -" instead
cd -
		
# turn off verbose mode and fail-fast mode.
set +x
set +e
