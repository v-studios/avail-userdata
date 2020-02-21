Avail Ansible repo
==================

This repository contains ansible plays needed to bootstrap avail
servers running Ubuntu 16.04 LTS. The target AMI is the EAST2 baseline AMI
prepared by MPG.


Install
=======

Dependencies
------------
1. [Ansible](http://www.ansible.com/)
2. [git](http://git-scm.com/)
3. Run against instance built from a [EAST2 Approved AMI] (https://confluence.nasawestprime.com/display/NWD/Approved+AMIs) with splunk installed

Dev Tools
---------
- VCS: git
    - OS X: `$ brew install git`
    - Ubuntu: `sudo apt-get install git`

- Deploy tools: Ansible
    - OS X: `$ brew install ansible`
    - Ubuntu: `sudo apt-get install ansible`


Run
===

- Deploy components to localhost on a stock ubuntu 16.04 installation:

    $ ansible-playbook -i hosts -l $PACKAGE setup.yml

    Where $PACKAGE is one of the following avail roles:
	avail_api
	avail_pipeline
	avail_imageresizer
