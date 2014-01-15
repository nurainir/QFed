# Author : Nur Aini Rakhmawati, February 22nd, 2013 ... 38 Weeks of pregnancy
#input file datasource
datasource=$1
filter=`awk -F "/" '{ if (NR>1) {printf " or "} if ($3 ~ /:/)  { split($3,array,":"); printf "(host " array[1] " and port " array[2] ")" } else { printf "(host " $3 ")" }  }' $datasource`
tcpdump -l -i any $filter -nNqtt > downuplink 
