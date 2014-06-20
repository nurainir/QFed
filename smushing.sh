outputdir=$1
let numberofqueries=$2+1
BIGLITERAL=$3
SF=$4
prune=1
#> $outputdir/linking
Optional=$6
service=$7
filter=$8
newline='
'

qid=`cat qid`
> smushx
sort -u smush > temp
awk -v limit=$prune  'BEGIN { s=""; d1=""; d2="" }{
 
if(s!=$1 && class[$4] < limit)
	{ s=$1; d1=$2; d2=$3 ; class[$4]++ 
		print $0 >> "smushx"
		#print s "\t" class[$4] "\t" $4
	}
else if(d1!=$3 && d2!=$2 && class[$4] < limit)
	{
		print $0 >> "smushx"; class[$4]++ 
	}
}
' temp 
rm temp


while read line
			do
			#split by tab
			arr=(${line//'\t'/ })
			datasetname=${arr[1]}
			otherdatasetname=${arr[2]}
			if [ $service != "-" ]; then
				urldataset=`grep "$datasetname" $service | awk '{print $2}'`
				urlotherdataset=`grep "$otherdatasetname" $service | awk '{print $2}'`
			fi
			./s-query --service http://localhost:3030/mydata/query "SELECT * { 
							graph<http://localhost/$datasetname>
							{ ${arr[0]} ?p  ?o }	
							} " --output=tsv | sed 1d | sort -u > qresprop
			if [ $qid -gt 1 ]; then
				 echo "${newline}#$qid#" > qfile
			else
				echo "#$qid#" > qfile
			fi
			cat qfile >> $outputdir/query
			echo "select * {     " >> $outputdir/query
							if [ $service != "-" ]; then
							cat qfile >> $outputdir/queryservice
							echo "select * { ${newline}  service<$urldataset> { " >> $outputdir/queryservice								
							
							fi
					echo "smush" >> countqueries
								
							##########SF##############
							if [ $SF -eq 1 ]; then
							rm qfile
							awk -v qfile="qfile" -v LITERAL="" -v URI=""  -v filter=$filter ' NR==FNR{ref[$1]=$2;next} 
							{
							# 1 URI, 1 SMALL LITERAL
							#	print $1 
								if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>")
									next
								else if ($2 ~ /^</ )
								{
									if (URI == "")
URI=$1													
									else if(URI != $1 && ref[$2]>U)
										URI=$1; U=ref[$2]
								}
																
								else if ($2 !~ /####/ && LITERAL != $1)
								{
									if (LITERAL == "") { LITERAL=$1; myfilter=$2}
									else if(ref[$2]>L)
										{LITERAL=$1;L=ref[$2];myfilter=$2}
								}
								
								
								
							}END {
							if (URI != "")
							{
								print "?s " URI " ?URI ." >> qfile
								print URI >> "SF"
								print URI > "curprop"
							}
							else if(LITERAL!= "" )
								{
									print "?s " LITERAL " ?LITERAL ." >> qfile
									if(myfilter ~ /^[0-9]+/ && filter==1)
									print "FILTER (?LITERAL >= " myfilter " )" >> qfile	
									print LITERAL >> "SF"
									print LITERAL > "curprop"
								}
								
							}' $outputdir/OCP qresprop
							
								cat qfile  >> $outputdir/query
								
								if [ $service != "-" ]; then
								
								echo " } " >> qfile
								cat qfile >> $outputdir/queryservice				
								fi
								
								rm qfile
								./calcSF.sh $outputdir	
							else
							
							rm qfile
							awk -v qfile="qfile" -v filter=$filter -v LITERAL="" -v URI="" '
							{
							# 1 URI, 1 SMALL LITERAL
							#	print $1 
								if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>")
									next
								else if ($2 ~ /^</) 
								{if(URI =="")
									{
									print "?s " $1 " ?URI ." >> qfile
									URI=$1
									print $1 >> "SF"
									print URI > "curprop"
									exit
									}
								}
								
								else if ($2 !~ /####/ && LITERAL =="")
									{
										
										LITERAL=$1
										myfilter=$2
										print "?s " LITERAL " ?LITERAL ." >> qfile
										if(myfilter ~ /^[0-9]+/ && filter==1)
										print "FILTER (?LITERAL >= " myfilter " )" >> qfile	
										print LITERAL >> "SF"
										print LITERAL > "curprop"
										exit
									}
								
							}' qresprop
							
								cat qfile  >> $outputdir/query
								
								if [ $service != "-" ]; then
								echo " } " >> qfile
								cat qfile >> $outputdir/queryservice	
									
								fi
								rm qfile
								./calcSF.sh $outputdir
							fi ## END SF first dataset
							### second dataset

							curprop=`cat curprop`
							./s-query --service http://localhost:3030/mydata/query "SELECT * { 
							graph<http://localhost/$otherdatasetname>
							{ ${arr[0]} ?p  ?o }	
							} " --output=tsv | sed 1d | sort -u > qresprop

							
							if [ $service != "-" ]; then
								echo "service<$urlotherdataset> { " >> $outputdir/queryservice							
							fi

								##########SF##############
							if [ $SF -eq 1 ]; then
							rm qfile
							awk -v qfile="qfile" -v curprop=$curprop -v big=$BIGLITERAL -v LITERAL="" -v URI="" -v BIGLITERAL="" -v filter=$filter -v optional=$Optional ' NR==FNR{ref[$1]=$2;next} 
							{
							# 1 URI, 1 SMALL LITERAL
							#	print $1 
								if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" || curprop == $1)
									next
								else if ($2 ~ /^</  )
								{
									if (URI == "")
URI=$1													
									else if(URI != $1 && ref[$2]>U)
										URI=$1; U=ref[$2]
								}
								else if ($2 ~ /####/ && BIGLITERAL!=$1 && big ==1)
								{
									if (BIGLITERAL == "") BIGLITERAL=$1
									else if(ref[$2]>B)
										BIGLITERAL=$1;B=ref[$2]
								}								
								else if ($2 !~ /####/ && LITERAL != $1)
								{
									if (LITERAL == "") { LITERAL=$1; myfilter=$2}
									else if(ref[$2]>L)
										{LITERAL=$1;L=ref[$2];myfilter=$2}
								}
								
								
								
							}END {
							if (URI != "")
							{
								print "?s " URI " ?URI2 ." >> qfile
								print URI >> "SF"
							}
							if(LITERAL!= "" && BIGLITERAL =="" )
								{
									
									if(optional==1)
										print "OPTIONAL {" >> qfile
										print "?s " LITERAL " ?LITERAL2 ." >> qfile
									if(optional==1)
										print "}" >> qfile
									
									if(myfilter ~ /^[0-9]+/ && filter==1)
									print "FILTER (?LITERAL >= " myfilter " )" >> qfile	
									print LITERAL >> "SF"
								}
								if(BIGLITERAL!= "")
								{
									print "?s " BIGLITERAL " ?BIGLITERAL ." >> qfile
									print BIGLITERAL >> "SF"
								}
							}' $outputdir/OCP qresprop
							
							echo " } " >> qfile
								cat qfile  >> $outputdir/query
								if [ $service != "-" ]; then
								echo " } " >> qfile
								cat qfile >> $outputdir/queryservice							
								fi
								rm qfile
								./calcSF.sh $outputdir	
							else
							#echo "SF 0 $curprop"  >> $outputdir/query
							rm qfile
							awk -v qfile="qfile" -v big=$BIGLITERAL -v curprop=$curprop -v filter=$filter -v LITERAL="" -v URI="" -v BIGLITERAL="" -v optional=$Optional '
							{
							# 1 URI, 1 SMALL LITERAL
							#	print $1 
								if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>"  || curprop == $1)
									next
								else if ($2 ~ /^</) 
								{if(URI =="")
									{
									print "?s " $1 " ?URI2 ." >> qfile
									URI=$1
									print $1 >> "SF"
									}
								}
								
								else if ($2 ~ /####/ && BIGLITERAL=="" && big ==1)
									{
										
										BIGLITERAL=$1
																			
									}
									else if ($2 !~ /####/ && LITERAL =="")
									{
										
										LITERAL=$1
										myfilter=$2
									}
								
							}END {
								
								if(LITERAL!= "" && BIGLITERAL =="" )
								{
									if(optional==1)
										print "OPTIONAL {" >> qfile
									print "?s " LITERAL " ?LITERAL2 ." >> qfile
							
									if(optional==1)
										print "}" >> qfile
									if(myfilter ~ /^[0-9]+/ && filter==1)
									print "FILTER (?LITERAL >= " myfilter " )" >> qfile	
									print LITERAL >> "SF"
								}
								if(BIGLITERAL!= "")
								{
									print "?s " BIGLITERAL " ?BIGLITERAL ." >> qfile
									print BIGLITERAL >> "SF"
								}
								}' qresprop
							echo " } " >> qfile
								cat qfile  >> $outputdir/query
								if [ $service != "-" ]; then
									echo " } " >> qfile
									cat qfile >> $outputdir/queryservice
								fi
								rm qfile
								./calcSF.sh $outputdir
							fi


							if [ $service != "-" ]; then
								echo ${newline} >> $outputdir/queryservice
							fi
							echo ${newline} >> $outputdir/query
							((qid++))
							echo $qid > qid
							rm qresprop
							
		done < smushx	

rm smush smushx



