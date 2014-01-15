endpoints=$2

function runquery
{
		STARTTIME=$(date +%s%N)
		./tcpdumpON.sh endpoints & cmdpid=$! 
		./ngrepON.sh endpoints & cmdpid2=$! 
		echo $cmdpid > pid
		echo $cmdpid2 > pid2	
		./FedXsinglequery.sh $1 $2 $3
		ENDTIME=$(date +%s%N)
		if [ -f queryrequest ]; then
		T="$((ENDTIME-STARTTIME))"
		T=`echo "scale=2;$T / 1000000" | bc -l`
		./tcpdumpOFF.sh endpoints > var
		BW=`cat var`
		./ngrepOFF.sh endpoints > var
		RQ=`cat var`
		./countNtriples.sh > var
		IR=`cat var`
		rm var
		
		if [ -f qres ];then
		Qerror=`grep -c "ERROR" qres`
		if [ $Qerror -gt 0 ]; then 
			echo $3 >> $1-failed
			echo "$3 - - - - - - - - - - -" >> $1-fedsuccess
		else
			res=`wc -l < qres`
			
			if [ $res -lt 3 ]; then
				echo $3 >> $1-failed
				echo "$3 - - - - - - - - - - -" >> $1-fedsuccess

			else 
				let res=$res-2				
				echo "$3 $T $BW $RQ $IR $res" >> $1-fedsuccess
			fi
			
		fi
		rm queryfed
		rm qres
		fi
		fi


 
}

function clean_up {
	if [  -f queryfed ]; then
	rm queryfed
	fi
	exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM


#for queryset in $1/*
#do
echo $1
queryset=$1
if [ -f $queryset ]; then
echo "execute $queryset" >> log
rm cache.db
> queryfed
echo "QID T DReceived DTotal Source Ask Construct Describe Select IR Max" > $queryset-fedsuccess
while read queryline
do
	if [[ $queryline =~ ^#[0-9]+#$ ]]; then
		arr=(${queryline//'#'/ })
		qid=${arr[0]}
		echo "executing $qid"
		
	elif [ ! -z "${queryline}" ]; then
		echo "$queryline" >> queryfed
	elif [  -f queryfed ]; then
		runquery $queryset $endpoints $qid
		sleep 5
		
	fi

	
done < $queryset
if [ -f queryfed ]; then
	runquery $queryset $endpoints $qid
fi
fi
#done
