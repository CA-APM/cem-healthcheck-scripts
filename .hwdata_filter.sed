s/Intel(R)//g
s/CPU//g
s/Core(TM)//g
s/RedHatEnterpriseServer/Enterprise Server/g
s/\-\[//g
s/\]\-//g
s/^ *//;s/ *$//;s/ \{1,\}/ /g
/^#/d
s/'/\\'/g
s/`/\\'/g
s/"//g