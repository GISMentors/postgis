cd uhuldta/2013/ORP;

OLDIFS=$IFS;
IFS=`echo -en "\n\n"`;

find *.txt | while read ff; do 
   head -n 1 $ff | cut -d ';' -f 1 | psql -c "COPY hratky_se_svg.soubory_slhp (nazev) FROM STDIN" pokusnik;

   tail -n +8 $ff | sed 's/,/./g' | 
   psql -c "COPY hratky_se_svg.slhp (drevina, plocha_ha, plocha_proc, zasoba_m3, zasoba_proc, avb, stredni_vek) 
   FROM STDIN WITH DELIMITER ';' NULL ''" pokusnik;
done 2> err

IFS=$OLDIFS;
