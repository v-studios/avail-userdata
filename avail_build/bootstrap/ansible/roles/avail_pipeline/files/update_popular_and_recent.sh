#!/bin/bash

# Script to periodically pull popular.json and recent.json
# from AVAIl API and store them in the public bucket

export AWS_DEFAULT_REGION=us-east-1

# Use Bash pipefail option to return non-0 if any command in the pipeline fails,
#   otherwise bash only returns the last command in the pipeline.
# see: https://www.gnu.org/software/bash/manual/html_node/Pipelines.html
set -o pipefail

# Check which op_env we're running in to get appropriate endpoints
public_bucket_name=`grep avail.aws.s3.prod.bucket.name /usr/local/avail/avail_pipeline/published*.ini | cut -d' ' -f3`
timestamp="`date +[%d/%b/%Y:%k:%M:%S\ %z]` avail_role=$avail_role ip=$ip_addr"
if [ $? -ne 0 ]
then
	echo "$timestamp ERROR: could not get public_bucket_name"
	exit 1
fi

case ${public_bucket_name} in
	images-assets.dev.nasawestprime.com)
		api_endpoint_name=images-api.dev.nasawestprime.com
		op_env=dev
		;;
	images-assets.stage.nasawestprime.com)
		api_endpoint_name=images-api.stage.nasawestprime.com
		op_env=stage
		;;
	images-assets.nasa.gov)
		api_endpoint_name=images-api.nasa.gov
		op_env=prod
		;;
	*)
		echo "$timestamp ERROR: invalid bucket name, can't detect op_env"
		exit 1
		;;
esac

# Set Logging prefix with date and avail info for splunk logging
avail_role="avail_pipeline"
ip_addr=`curl -s 169.254.169.254/latest/meta-data/local-ipv4`
if [ $? -ne 0 ]
then
	echo "$timestamp ERROR: could not get ip_addr"
	exit 1
fi

timestamp="`date +[%d/%b/%Y:%k:%M:%S\ %z]` op_env=$op_env avail_role=$avail_role ip=$ip_addr"
if [ $? -ne 0 ]
then
	echo "$timestamp ERROR: could not get timestamp"
	exit 1
fi

# Get local instance_id
instance_id=`curl -s 169.254.169.254/latest/meta-data/instance-id`
if [ $? -ne 0 ]
then
	echo "$timestamp ERROR: could not get instance_id"
	exit 1
fi

# Get ELB Name for op_env
elb_name=`aws cloudformation describe-stack-resources --stack-name avail$op_env | \
       	    jq -r '.StackResources[] | select(.LogicalResourceId=="PipelineLoadBalancer") | .PhysicalResourceId' `

if [ $? -ne 0 ]
then
	echo "$timestamp ERROR: could not get elb_name"
	exit 1
fi

# Get list of instances in Pipeline ELB 
# Filter on Instance in "In Service" state, then sort list numberically
# take the highest value InstanceId (newest-ish)
get_newest_instance_id()
{
	aws elb describe-instance-health --load-balancer-name $elb_name | \
	  jq -r '.InstanceStates[] | select(.State=="InService") | .InstanceId ' | \
	  sort -n | tail -n 1
	if [ $? -ne 0 ]
	then
		echo "$timestamp ERROR: could not get newest_instance_id"
		exit 1
	fi
}

# Get self InstanceId for HighLander Election
newest_instance_id=`get_newest_instance_id`

# Ensures that "there can be only one" pipeline running recent/popular update
# by choosing the highest InstanceId fom among the healthy instances in the Pipeline LoadBalancer

if [ "$instance_id" != "$newest_instance_id" ]
then
	echo -n "$timestamp INFO: We are not the newest, skipping recent/popular update. "
	echo -n "Our instance_id is : $instance_id, "
	echo "The newest_instance_id is : $newest_instance_id."
	exit 0
fi

# Curl silently, ignore certificate warnings, return non 0 status code if HTTP result is not 200
curl_prefix="curl -sk -f"

for json_data in popular recent
do

	# Get json file from API endpoint and store in /tmp
	${curl_prefix} -o /tmp/${json_data}.json "https://${api_endpoint_name}/asset/?orderby=${json_data}"
	if [ $? -ne 0 ]
	then
		echo "$timestamp ERROR: could not get json object: ${json_data}.json"
		exit 1
	else
		json_data_etag=`md5sum /tmp/${json_data}.json`
		if [ $? -ne 0 ]
		then
			echo "$timestamp ERROR: could not get md5 hash for file: /tmp/${json_data}.json"
			exit 1
		fi

		json_data_url=`cat /tmp/${json_data}.json | jq '.collection.href'`
		if [ $? -ne 0 ]
		then
			echo "$timestamp ERROR: could not get URL from /tmp/${json_data}.json"
			exit 1
		else
			echo ${json_data_url} | grep -q ${json_data}
			if [ $? -ne 0 ]
			then
				echo "$timestamp ERROR: URL in /tmp/${json_data}.json does not include string: ${json_data}"
				echo "$timestamp ERROR: URL in /tmp/${json_data}.json is: ${json_data_url}"
				exit 1
			fi

			echo "$timestamp INFO: URL in /tmp/${json_data}.json is : ${json_data_url}"
		fi

		echo "$timestamp INFO: got json object: ${json_data}.json with etag: ${json_data_etag}"
	fi

	# Put json file from /tmp into public bucket
	aws s3 --region us-east-1 --quiet cp /tmp/${json_data}.json s3://${public_bucket_name}/${json_data}.json \
		--content-type "application/json" \
		--cache-control "public, max-age=300, s-maxage=600" 
	if [ $? -ne 0 ]
	then
		echo "$timestamp ERROR: could not put json object: ${json_data}.json"
		exit 1
	else
		echo "$timestamp INFO: published json object: ${json_data}.json to: s3://${public_bucket_name}/${json_data}.json with etag: ${json_data_etag}"
	fi

done
