queryset=$1
endpoint=$2

function runquery
{	
		./tcpdumpON.sh endpoints & cmdpid=$! 
		echo $cmdpid > pid
		./validatesinglequery.sh $1 $2 $3
		
		if [ -f qres ];then
		res=`wc -l < qres`
		./tcpdumpOFF.sh endpoints > var
		BW=`cat var`
		endpointvar=`grep -c "endpoint" queryval`
		
		if [[ $endpointvar -gt 0 ]] && [[ $res -lt 2 ]]; then
			echo $3 >> $1-failed
		elif [ $res -eq 0 ]; then
			echo $3 >> $1-failed

		else 
			echo "$3 $BW" >> $1-success
		fi
		rm queryval
		rm qres
		fi




}

function clean_up {
	if [  -f queryval ]; then
	rm queryval
	fi
	exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM

> queryval
echo $queryset >> /tmp/success 
while read queryline
do
	if [[ $queryline =~ ^#[0-9]+#$ ]]; then
		arr=(${queryline//'#'/ })
		qid=${arr[0]}
		echo "executing $qid"
		
	elif [ ! -z "${queryline}" ]; then
		echo "$queryline" >> queryval
	elif [  -f queryval ]; then
		runquery $queryset $endpoint $qid
		sleep 5
		
	fi
	
	
	
done < $queryset
if [  -f queryval ]; then
	runquery $queryset $endpoint $qid
fi



#done < $queryset/queryservice
