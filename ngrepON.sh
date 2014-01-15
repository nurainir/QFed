# Author : Nur Aini Rakhmawati, February 22nd, 2013 ... 38 Weeks of pregnancy
#input file datasource
datasource=$1
#create filter for capturing packet
filter=`awk -F "/" '{ if (NR>1) {printf " or "} if ($3 ~ /:/)  { split($3,array,":"); printf "(host " array[1] " and port " array[2] ")" } else { printf "(host " $3 ")" }  }' $datasource`
ngrep -l -t -P '#' -qd any $filter -W byline > queryrequest 
#ngrep -l -t -qd any '(select|ask|construct|describe)' $filter -W byline > queryrequest &
#ngrep -l -t -P '#' -v -qd any '^(GET|POST)' $filter -W byline > ntriple &
