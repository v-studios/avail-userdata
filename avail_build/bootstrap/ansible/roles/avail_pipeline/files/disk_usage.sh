#!/bin/bash

# Script to periodically output disk usage stats on AVAIL Pilepline instances
# and store them in a log file

# Set Logging prefix with date and avail info for splunk logging
avail_role="avail_pipeline"
ip_addr=`curl -s 169.254.169.254/latest/meta-data/local-ipv4`
timestamp="`date +[%d/%b/%Y:%k:%M:%S\ %z]` avail_role=$avail_role ip=$ip_addr"

# Check which op_env we're running in to get appropriate endpoints
public_bucket_name=`grep avail.aws.s3.prod.bucket.name /usr/local/avail/avail_pipeline/published*.ini | cut -d' ' -f3`

case ${public_bucket_name} in
	images-assets.dev.nasawestprime.com)
		op_env=dev
		;;
	images-assets.stage.nasawestprime.com)
		op_env=stage
		;;
	images-assets.nasa.gov)
		op_env=prod
		;;
	*)
		echo "$timestamp ERROR: invalid bucket name, can't detect op_env"
		exit 1
		;;
esac

timestamp="`date +[%d/%b/%Y:%k:%M:%S\ %z]` op_env=$op_env avail_role=$avail_role ip=$ip_addr"

# Print timestamp at beginning of log entry
echo -n $timestamp" "

# Print disk usage for "/" filesystem
df -h --output=size,avail,pcent / | tail -n 1 | awk -F" " '{print "volume_size="$1", space_available="$2", percent_used="$3}'

if [ $? -ne 0 ] 
then
	echo "ERROR: could not get disk usage"
	exit 1
fi 
