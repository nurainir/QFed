outputdir=$1
qid=`cat qid`
newline='
'
service=$3 
SF=$2
i=0


while read line 
do
########first position s3#####
	if [ $i -eq 0 ]; then
	s3=$line
####second line position two dataset 
	elif [ $i -eq 1 ]; then
		db=(${line//' '/ })
		rm qfile
	for dataset in $outputdir/dump/*
	do
	datasetname=${dataset##*/}
	if [[ ${db[0]} != $datasetname ]] && [[ ${db[1]} != $datasetname ]]; then
		if [ $service != "-" ]; then
				urldataset=`grep "$datasetname" $service | awk '{print $2}'`
				
			fi
		./s-query --service http://localhost:3030/mydata/query "SELECT * { 
							graph<http://localhost/$datasetname>
							{ $s3 ?p  ?o }	
							} " --output=tsv | sed 1d | sort -u > qresprop
		res=`wc -l < qresprop`
		if [ $res -gt 1 ]; then #getresults 
			
			if [ $SF -eq 1 ]; then
					awk -v qfile="qfile" -v URI="" ' NR==FNR{ref[$2]=$1;next} 
						{
						
						if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" )
							next
						else if ($2 ~ /^</ )
						{
							if (URI == "")
								URI=$1													
							else if(URI != $1 && ref[$2]>U)
								URI=$1; U=ref[$2]
						}
						}END {
						if (URI != "")
						{
							print "?s3 " URI " ?URI3 ." >> qfile
							print URI >> "SF"
						}
						}' $outputdir/OCP qresprop
							
						
						
				else
					awk -v qfile="qfile" ' 
					{
		
					if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" )
						next
					else if ($2 ~ /^</)
					{ 
						print "?s3 " $1 " ?URI3 ." >> qfile
						print URI >> "SF"								
						exit 1
					}
							
					}' qresprop
								
					
			fi ### end sf 
			./calcSF.sh $outputdir				
						
			break
		fi ## end get results
	fi ## end other dataset
	done
#############3rd
elif [ $i -eq 3 ]; then	
	break
fi ## end line
((i++))
done < hybrid
 if [ -f qfile ]; then
	#if [ $service == "-" ]; then
		echo "#$qid#" >>$outputdir/query
		echo "select * { " >>  $outputdir/query
		tail -n +2 hybrid >> $outputdir/query
		cat qfile >> $outputdir/query
		echo " } ${newline}" >> $outputdir/query
	#fi
		echo "#$qid#" >>$outputdir/queryservice
		echo "select * { " >>  $outputdir/queryservice
		tail -n +1 hybrids >> $outputdir/queryservice
		echo "service<$urldataset> {" >> $outputdir/queryservice	
		cat qfile >> $outputdir/queryservice
		echo "} } ${newline}" >> $outputdir/queryservice
	
	cat hsf >> SF
	rm hsf
	rm qfile
	./calcSF.sh $outputdir
	((qid++))
	echo $qid > qid
	echo "hybrid" >> countqueries

 fi

rm hybrid
rm hybrids



