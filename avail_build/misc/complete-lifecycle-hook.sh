#!/bin/bash -xe

TIMESTAMP=`date +%D\ %T`
# Remove run of this script at startup
LC_HOOK_LINK=/etc/init.d/complete-lifecycle-hook.sh
LOGFILE=/var/log/avail/lifecycle_hook.log

if [ -f $LC_HOOK_LINK ]; then
  rm $LC_HOOK_LINK
  if [ $? != 0 ]; then
    echo "ERROR: $TIMESTAMP Can't remove lifecycle hook script execution" >> $LOGFILE
    exit
  else
    echo "INFO; $TIMESTAMP successfully removed lifecycle hook script execution" >> $LOGFILE
  fi
else
  echo "INFO: $TIMESTAMP No startup execution for lifecycle hook script is enabled" >> $LOGFILE
  exit
fi

# Go back to /avail_build dir
cd /avail_build
# Create a virtualenv so our required python packages don't interfere with AVAIL

echo "Creating Lifecycle Hook virtualenv"
virtualenv --python=python3 lifecycle

echo "Activating Lifecycle Hook virtualenv"
cd lifecycle
. bin/activate

# Get required packages
echo "Getting required packages"
pip install awscli==1.10.67
echo -n "installed awscli version : "
aws --version

# Use apt to install jq. pip needs a bunch of compilation tools that we don't want
apt-get install -y jq
echo -n "installed jq version : "
jq --version

# Get Instance ID and Region from instance metadata
INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
REGION=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region'`

# Use AWS API to Detect AutoScaling Group and LifeCycle Hook names
ASG_NAME=`aws --region $REGION autoscaling describe-auto-scaling-instances | jq -r '.AutoScalingInstances[] | select(.InstanceId=="'$INSTANCE_ID'") | .AutoScalingGroupName'`
echo AutoScaling Group Name is : $ASG_NAME

LIFECYCLE_HOOK_NAME=`aws --region $REGION autoscaling describe-lifecycle-hooks --auto-scaling-group-name ${ASG_NAME} | jq -r '.LifecycleHooks[].LifecycleHookName'`
echo LifeCycle Hook Name is : $LIFECYCLE_HOOK_NAME

# Notify Detected LifeCycle Hook to continue for this instance
echo Sending \"CONTINUE\" Notification to LifeCycle Hook Named \"${LIFECYCLE_HOOK_NAME}\" for instance ID: ${INSTANCE_ID}
aws --region $REGION autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE --instance-id ${INSTANCE_ID} --lifecycle-hook-name ${LIFECYCLE_HOOK_NAME} --auto-scaling-group-name ${ASG_NAME}
