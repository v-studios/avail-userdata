cd {{ avail_dir }}/{{ avail_role }}
exec {{ avail_dir }}/{{ avail_role }}/bin/uwsgi --ini-paste {{ avail_dir }}/{{ avail_role }}/{{ op_env }}.ini $@
