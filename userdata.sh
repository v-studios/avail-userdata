#!/bin/bash -xe
export op_env={}\n".format(op_env),
apt-get -y remove ansible
pip install ansible==2.1.5.0
mkdir {}\n".format(ec2_tarball_build_dir),
cd {}\n".format(ec2_tarball_build_dir),
curl --location -o {} {}\n".format(
	ec2_tarball_pipeline_file,
	ec2_tarball_pipeline_url),
tar zxf {}\n".format(ec2_tarball_pipeline_file),
sh {}\n".format(ec2_tarball_pipeline_sh),
cat {}/misc/rc.local > /etc/rc.local\n".format(ec2_tarball_build_dir),
ln -s {}/misc/complete-lifecycle-hook.sh /etc/init.d/\n".format(ec2_tarball_build_dir),
reboot\n"
