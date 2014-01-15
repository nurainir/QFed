# Author : Nur Aini Rakhmawati, February 22nd, 2013 ... 38 Weeks of pregnancy
#input datasource


#kill ngrep process
#kill `ps -ef | grep tcpdump | grep -v -E \" grep\"  | awk '{print $2}'`


#check downuplink contain 127.0.0.1 sender and receiver parts
samehost=`awk -F " " '{ if($3 ~ /^127\.0\.0\.1/ && $5 ~ /^127\.0\.0\.1/)
	samehost=samehost+1 } END { if(samehost>0) print "1"; else  print "0" } ' downuplink`

#reading the IPs
IPs=`/sbin/ifconfig | awk -F':' '/inet addr/&&!/127.0.0.1/{split($2,_," ");printf _[1] ";"}'`

#sum received bytes from the SPARQL ENdpoint to federation
treceived=0

for ip in $(echo $IPs | tr ";" "\n")
do
received=`awk -F " " -v ip=$ip '{
 if($5 ~ /'"$ip"'/)
	received=received+$7
  	}
END {
if(received>0)
print received
else 
print "0"
}
' downuplink`
treceived=$(($received+$treceived))
done

if [ $samehost -gt 0  ]
then
datasource=$1
ports=`awk -F "/" '{ if ($3 ~ /:/)  { split($3,array,":"); printf array[2] ";"  } else printf  "80;"  }' $datasource`

tlocalreceived=0
for port in $(echo $ports | tr ";" "\n")
do
endpoint="127.0.0.1.$port:"
localreceived=`awk -F " " -v endpoint=$endpoint '{

 if($5 ~ /'$endpoint'$/)
	received=received+$7
  	}
END {
if(received>0)
print received
else 
print "0"
}
' downuplink`
tlocalreceived=$(($tlocalreceived+$localreceived))
done
treceived=$(($tlocalreceived+$treceived))
fi

#sum amount data sent and received from SPARQL Endpoint to Federation
total=`awk -F " " '{ total=total+$7 } END { if(total>0) print total; else  print "0" } ' downuplink`
if [ -f downuplink ]
then
    rm downuplink
fi
echo $treceived $total
