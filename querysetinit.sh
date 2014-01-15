#start fuseki and upload the dump to several graphs
BIGLITERAL=0
SF=0
NTdir=""
Outputdir="out"
numberofqueries=2
prune=0
Optional=0
service="-"
filter=0
log="BIG Literal No"
> countqueries
set -- $(getopt FBDOi:s:o:n:T: "$@")
while [ $# -gt 0 ]
do
    case "$1" in
    (-B) BIGLITERAL=1; log="BIG Literal Yes";;
    (-F) filter=1;;
    (-D) SF=1;;
    (-O) Optional=1;;
   (-s) service="$2"; shift;;
    (-i) NTdir="$2"; shift;;
    (-o) Outputdir="$2"; shift;;
    (-n) numberofqueries="$2";  shift;;
    (-T) prune="$2";  shift;;
    (--) shift; break;;
    (-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
    (*)  break;;
    esac
    shift
done
echo "#########################" >> log
date >> log
echo "#########################" >> log
if [ $SF -eq 1 ]; then
log="$log Distribution Yes"
else
log="$log Distribution No"
fi

if [ $Optional -eq 1 ]; then
log="$log Optional Yes"
else
log="$log Optional No"
fi

if [ $service == "-" ]; then
log="$log not provide SERVICE query"
else
log="$log provide SERVICE query"
fi

log="$log Limit Number of Queries per class $numberofqueries Threshold per properties $prune"
echo $log >> log



if [[ $NTdir == "" ]] || [[ ! -d $NTdir ]]
then
     echo "$0: error the input directory"
     exit 1
fi

if [[ $service != "-" ]] && [[ ! -f $service ]]
then
     echo " $service: can not be found"
     exit 1
fi



function clean_up {

	rm /tmp/prop
	rm /tmp/class
	rm SF
	#kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
	exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM

if [ ! -d $Outputdir ];
then
mkdir $Outputdir
else
rm -Rf $Outputdir/*
fi

mkdir $Outputdir/class
mkdir $Outputdir/dump
mkdir $Outputdir/prop

if [ ! -d data ];
then
mkdir data
else
rm -Rf data/*
fi

kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
sleep 10s
java -jar  fuseki-server.jar --update --loc=data /mydata &

echo "0" > $Outputdir/SF
> /tmp/prop
> /tmp/class
for fileNT in $NTdir/*.nt
do
	echo "processing ... $fileNT"
	filename=${fileNT##*/}
	./dump.sh $fileNT  $Outputdir
	sleep 50s
	./s-put http://localhost:3030/mydata/data http://localhost/$filename  $Outputdir/dump/$filename
done

> $Outputdir/OCC
awk -v output=$Outputdir/OCC '{
	freq[$1]++
	count[$1]=count[$1]+$2
	
}
END {
	for(class in freq)
	{
		print class " " freq[class] " " count[class]  >> output

	}
}

' /tmp/class
rm /tmp/class

> $Outputdir/OCP
awk -v output=$Outputdir/OCP '{
	freq[$1]++
	count[$1]=count[$1]+$2
}
END {
	for(prop in freq)
	{
		print  prop " " freq[prop] " " count[prop]  >> output

	}
}

' /tmp/prop
rm /tmp/prop

echo "start interlinking discovery"
./link-discovery.sh $Outputdir $numberofqueries $BIGLITERAL $SF $prune $Optional $service $filter
echo "start no interlinking discovery"
./no-link-discovery.sh $Outputdir $numberofqueries $BIGLITERAL $SF $prune $Optional $service $filter
#echo "start popular predicate discovery"
#./popularpredicate.sh $Outputdir $service
cp $Outputdir/query query
cp $Outputdir/queryservice queryservice

SF=`cat $Outputdir/SF`
q=`cat qid`
AvgSF=`echo "scale=2;$SF / $q" | bc -l` 

echo "Total distribution $SF" >> log
echo "Average Distribution $AvgSF" >> log
echo "Number of queries generated $q" >> log

### Types of queries
awk ' Begin {smush=0; nolinksameprops=0  }{
	if ($0 ~ /objclass/ )
	objclass++
	else if ($0 ~ /objentity/ )
	objentity++
	if ($0 ~ /linkclass/ )
	linkclass++
	else if ($0 ~ /linkentity/ )
	linkentity++	
	else if ($0 ~ /popular/ )
	popular++
	else if($0 ~ /smush/  )
	smush++
	else if($0 ~ /nolinksameprops/)
	nolinksameprops++
	else if($0 ~ /hybrid/)
	hybrid++
} END {
print "Object Comparison Class - Class " objclass >> "log"
print "Object Comparison Entity - Class " objentity >> "log"
print "Interlinking Class - Class " linkclass >> "log"
print "Interlinking Entity - Class " linkentity >> "log"
print "Popular predicate " popular >> "log"
print "Smushing Identifier " smush >> "log"
print "Object comparison same property " nolinksameprops >> "log"
print "hybrid " hybrid >> "log"
}	
' countqueries



#rm -Rf $Outputdir

