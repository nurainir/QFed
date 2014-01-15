#!/bin/bash
# Author : Nur Aini Rakhmawati, February 22nd, 2013 ... 38 Weeks of pregnancy
#kill ngrep process
#kill `ps -ef | grep ngrep | grep -v grep | awk '{print $2}'`
#calculating number of request and source selected
#grep -i -E '^T(.*)AP|(.*)(select|describe|construct|ask)' queryrequest > temp
#kill `ps -ef | grep ngrep | grep -v -E \" grep\"  | awk '{print $2}'`

if [ ! -d /tmp/rq ]; then
   mkdir /tmp/rq
fi

split -l 10000 queryrequest /tmp/rq/q
qselect=0
qask=0
qconstruct=0
qdescribe=0
qsource=0
for file in /tmp/rq/*
do

IN=`awk -F " " 'BEGIN {
qselect=0
qask=0
qconstruct=0
qdescribe=0
}
{
	
if($0 ~ /^T/)
	{	#IP address  not ASK query
		NOASK=$6
	}
	else if (toupper($0) ~ /SELECT/)
	{
		arr[NOASK]=1
		qselect=qselect+1
	}
	else if (tolower($0) ~ /(.*)ask/)
	{	qask=qask+1
	}
	else if (tolower($0) ~ /construct/)
	{
		arr[NOASK]=1
		qconstruct=qconstruct+1
	}
	else if (tolower($0) ~ /describe/ )
	{
		arr[NOASK]=1
		qdescribe=qdescribe+1
	}

}
END {
	source=0	
	for(no in arr) {
	    print no >> "tempsource" 
	}
	print qask " " qconstruct " " qdescribe  " " qselect 
}
' $file`

arrIN=(${IN// / })
qask=$(($qask+${arrIN[0]}))
qconstruct=$(($qconstruct+${arrIN[1]}))
qdescribe=$(($qdescribe+${arrIN[2]}))
qselect=$(($qselect+${arrIN[3]}))
done

qsource=$((`sed '/^$/d' tempsource |sort -u | wc -l`))
mytemp=`date +%H%M`
mytempf="source$mytemp"
rm tempsource


echo "$qsource $qask $qconstruct $qdescribe $qselect"

if [ -d /tmp/rq ]; then
   rm -Rf /tmp/rq
fi
