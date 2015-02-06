#! /bin/bash

psql -qAtc \
"select drevina
, max(plocha_proc) 
from hratky_se_svg.slhp 
where avb is not NULL 
group by drevina;" \
   -F ' '\
   pokusnik |
while read drev max; do
   echo $drev .. $max;
done;
