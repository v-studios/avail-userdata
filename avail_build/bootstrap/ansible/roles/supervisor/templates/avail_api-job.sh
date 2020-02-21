# If the instance is in the avail_api group, then it is an avai_api instance
#   When this is true, execute the multipart iam credentials script
#   This loads the iam credentials into the shell env before launching the avail_api worker
{% if op_env == "dev" %}
    source <( aws s3 cp s3://avail-private-dev/credentials/multipart_iam_creds.sh - )
{% elif op_env == "stage" %}
    source <( aws s3 cp s3://avail-private-stage/credentials/multipart_iam_creds.sh - )
{% elif op_env == "prod" %}
    source <( aws s3 cp s3://avail-private/credentials/multipart_iam_creds.sh - )
{% endif %}

cd {{ avail_dir }}/{{ avail_role }}
exec {{ avail_dir }}/{{ avail_role }}/bin/uwsgi --ini-paste {{ avail_dir }}/{{ avail_role }}/{{ op_env }}-job.ini $@
