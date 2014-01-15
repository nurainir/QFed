NTdir=$1
outputdir=$2
totalSO=0
totalOO=0

#if [ ! -d $outputdir ];
#then
#mkdir $outputdir
#else
#rm -Rf $outputdir/*
#fi

#mkdir $outputdir/class
#mkdir $outputdir/dump
#mkdir $outputdir/prop

#if [ ! -d data ];
#then
#mkdir data
#else
#rm -Rf data/*
#fi

#kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
#sleep 10s
#java -jar  fuseki-server.jar --update --loc=data /mydata &

#echo "0" > $outputdir/SF
#> /tmp/prop
#> /tmp/class
#for fileNT in $NTdir/*.nt
#do
#	echo "processing ... $fileNT"
#	filename=${fileNT##*/}
#	./dump.sh $fileNT  $outputdir
#	sleep 50s
#	./s-put http://localhost:3030/mydata/data http://localhost/$filename  $outputdir/dump/$filename
#done

for dataset in $outputdir/class/*
do
	
	datasetname=${dataset##*/}
	for otherdataset in $outputdir/class/*
	do
		
		otherdatasetname=${otherdataset##*/}
		
		if [ $otherdatasetname != $datasetname ]; then
		echo " $otherdataset $dataset "
		#### S - O###########
#			while read lclassdataset
#			do
#   				lclass=(${lclassdataset//'\t'/ })
#				classdataset=${lclass[0]}
#				
#				while read lclassotherdataset
#				do
#   				
#				lclassother=(${lclassotherdataset//'\t'/ })
#				classotherdataset=${lclassother[0]}

#				./s-query --service http://localhost:3030/mydata/query "SELECT * { 
#					graph<http://localhost/$datasetname>
#					{?s1 a $classdataset .
#					 ?s1 ?p1 ?s2 .	}
#					graph<http://localhost/$otherdatasetname>
#					{ ?s2 a  $classotherdataset }	
#					} " --output=tsv | sort -u >  qres

#				res=`wc -l < qres`
#					if [ $res -gt 1 ]; then 
#						 let totalSO=$totalSO+$res				
#					fi

#				rm qres

#					
#				done < $outputdir/class/$otherdatasetname

#			done < $outputdir/class/$datasetname

		######SO#############

		
		fi

	done

done


for dataset in $outputdir/dump/*
do
	
	datasetname=${dataset##*/}
	for otherdataset in $outputdir/dump/*
	do
		
		otherdatasetname=${otherdataset##*/}
		
		if [ $otherdatasetname != $datasetname ]; then
			echo " $otherdataset $dataset "
###O-O###########

		> qres
			
			awk '{
			if(NR==FNR){ 
				if($3 !~ /####/ && (tolower($2) != "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" ) ) 					{ if(NF==4) {object[$3]=$1 "\t" $2; next} else if (NF==5)  {object[$3]=$1 "\t" $2 " " $3; next}}; subject[$1]; next }
			 
			
			if( $3 ~ /####/ && tolower($2) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" )
				next
			else if(NF==4 && object[$3]  )
				{  
				print $1 "\t" $2 "\t" object[$3]  >> "qres" 
							
				}
			else if (NF==5)
			{
				obj=$3 " " $4
				print $1 "\t" $2 "\t" object[obj]  >> "qres" 
				}
			}
			 ' $otherdataset $dataset
			sort -u qres > qrestemp
			res=`wc -l < qrestemp`
			if [ $res -gt 1 ]; then 
				let totalOO=$totalOO+$res				
			fi
			rm qres qrestemp
			
		###O-O##########
		fi

done

done




echo "$totalSO $totalOO"

