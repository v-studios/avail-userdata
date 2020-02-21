cd {{ avail_dir }}/{{ avail_role }}
exec {{ avail_dir }}/{{ avail_role }}/bin/{{ item }}_worker {{ avail_dir }}/{{ avail_role }}/{{ item }}-{{ op_env }}.ini

