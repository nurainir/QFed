outputdir=$1
let numberofqueries=$2+1
BIGLITERAL=$3
SF=$4
prune=$5
Optional=$6
service=$7
filter=$8
> $outputdir/linking
> $outputdir/interlinks
newline='
'
> $outputdir/query
> $outputdir/queryservice
qid=1
echo "dummy dummyy" > $outputdir/entity
for dataset in $outputdir/class/*
do
	
	datasetname=${dataset##*/}
	for otherdataset in $outputdir/class/*
	do
		
		otherdatasetname=${otherdataset##*/}
		##### SERVICE URL ENDPOINTS
		if [ $service != "-" ]; then
			urldataset=`grep "$datasetname" $service | awk '{print $2}'`
			urlotherdataset=`grep "$otherdatasetname" $service | awk '{print $2}'`
		fi
		if [ $otherdatasetname != $datasetname ]; then

			while read lclassdataset
			do
   				lclass=(${lclassdataset//'\t'/ })
				classdataset=${lclass[0]}
				
				while read lclassotherdataset
				do
   				
				lclassother=(${lclassotherdataset//'\t'/ })
				classotherdataset=${lclassother[0]}

				./s-query --service http://localhost:3030/mydata/query "SELECT * { 
					graph<http://localhost/$datasetname>
					{?s1 a $classdataset .
					 ?s1 ?p1 ?s2 .	}
					graph<http://localhost/$otherdatasetname>
					{ ?s2 a  $classotherdataset }	
					} " --output=tsv > qres
					
					
					res=`wc -l < qres`
					if [ $res -gt 1 ]; then #getresults 
						
						
						#echo "compare  $datasetname class $classdataset to $otherdatasetname class $classotherdataset $res" >> /tmp/temp
						#remove headers of TSV results file
						sed 1d qres | sort -k2,2 -k1,1 | uniq > qrestemp 
						

						##store links for hybird query
						awk '{print $2}' qrestemp | uniq >> $outputdir/interlinks 						
				
						#create a list on interlinking
						#map with reference key to avoid redudancy, put key already used in entitytemp during the parsing process then storing at entity 
						> entitytemp
						awk -v limit=$numberofqueries -v total=0 -v p=" " ' NR==FNR{{refS[$1]=1;refO[$2]=1};next}
						{
							if(refS[$1]!=1 &&  refO[$3]!=1)
							{	
									
								if(e[$1]!=1) # different entities
								{ e[$1]=1
						 		 if(p!=$2) { p=$2; total=1; print $0; print $1 " " $3 >> "entitytemp"  } # different properties 
						  			else if (total < limit) {print $0; total++; print $1 " " $3 >> "entitytemp"  }} }} 
						' $outputdir/entity  qrestemp >  $outputdir/linking
						if [ $prune -gt 0 ]; then
						#######prune#######
						> linking
						awk 'NR==FNR{ref[$1]=$3;next} 
						{
						if(ref[$2])
							print ref[$2] "\t" $0 >> "linking" }' $outputdir/OCP $outputdir/linking	
			
						sort -n -r -k 1,1 -k3,3 -k 2,2 linking | uniq | awk -F '\t' -v prune=$prune -v p="" ' {
						if(p!=$3) 
							{
							po++	
							p=$3
							print $2 "\t" $3  "\t" $4
							}
						else if(po < prune) #same prop dif object
						print $2 "\t" $3  "\t" $4
						if(po == prune)
						exit 1 		
						}
						' > $outputdir/linking					
						rm linking
						fi # end prune if
						# create queries based on the results
						line=1
						while read list
						do
						#split by tab
						arr=(${list//'\t'/ })
						./s-query --service http://localhost:3030/mydata/query "SELECT * { 
							graph<http://localhost/$otherdatasetname>
							{ ${arr[2]} ?p  ?o }	
							} " --output=tsv | sed 1d | sort -u > qres
						
						# first query between classes
						if [ $line -eq 1 ]; then
													
							# parsing query results
							if [ $qid -gt 1 ]; then
								 echo "${newline}#$qid#" > qfile
							else
								echo "#$qid#" > qfile
							fi

							cat qfile >> $outputdir/query
							echo "select * { ${newline} ?s1 a $classdataset . ${newline} ?s1 ${arr[1]} ?s2 . " >> $outputdir/query

							if [ $service != "-" ]; then
								cat qfile  >> $outputdir/queryservice
								echo "select * { ${newline} service<$urldataset> {${newline} ?s1 a $classdataset . ${newline} ?s1 ${arr[1]} ?s2 . }" >> $outputdir/queryservice														
								echo "service<$urlotherdataset> ${newline} {" >>  $outputdir/queryservice
							
							fi

							if [ $filter -eq 1 ]; then
								echo "select ?LITERAL { ${newline} graph<http://localhost/$datasetname> {${newline} ?s1 a $classdataset . ${newline} ?s1 ${arr[1]} ?s2 . }" > qfilter														
								echo "graph<http://localhost/$otherdatasetname> ${newline} {" >>  qfilter
							
							fi
							rm qfile
							echo $classdataset > SF
							echo ${arr[1]} >> SF
							#### counting queries
							echo "linkclass" >> countqueries
							#### optional
						#	if [ $Optional -eq 1 ]; then
						#		echo "OPTIONAL {" >> $outputdir/query
						#	fi
							##########SF##############
							if [ $SF -eq 1 ]; then
								awk -v qfile="qfile" -v LITERAL="" -v URI="" -v optional=$Optional  ' NR==FNR{ref[$2]=$1;next} 
								{
								# 1 URI, 1 SMALL LITERAL
									if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" )
										next
									else if ($2 ~ /^</ )
									{
										if (URI == "")
										URI=$1													
										else if(URI != $1 && ref[$2]>U)
											{URI=$1; U=ref[$2]}
											
									}
									else if ($2 !~ /####/ && LITERAL != $1)
									{
										if (LITERAL == "") LITERAL=$1
										else if(ref[$2]>L)
											{LITERAL=$1;L=ref[$2]}
									}
								} END {
								if (URI != "")
								{
									print "?s2 " URI " ?URI ." >> qfile
									print URI >> "SF"
								}
								if(LITERAL!= "")
								{
									if(optional==1)
										print "OPTIONAL {" >> qfile
									print "?s2 " LITERAL " ?LITERAL ." >> qfile
									if(optional==1)
										print "}" >> qfile
									print LITERAL >> "SF"
								}
								}' $outputdir/OCP  qres
								if [ $filter -eq 1 ]; then
									
									cat qfile >> qfilter
									echo " }} " >> qfilter
									qfilter=`cat qfilter`
									./s-query --service http://localhost:3030/mydata/query "$qfilter" --output=tsv | sed 1d | sort -n > qres
									res=`wc -l < qres`
									if [ $res -gt 1 ]; then
										let med=($res+1)/2
										const=`awk -v med=$med 'NR==med{print;exit}' qres`
										if [[ $const =~ ^[0-9]+ ]]; then
											echo "FILTER(?LITERAL >= $const) ." >> qfile
										fi
									fi
								rm qfilter
												
								fi
								echo " } " >> qfile
								cat qfile  >> $outputdir/query
								if [ $service != "-" ]; then
									echo " } " >> qfile
									cat qfile >> $outputdir/queryservice
									
								fi
								rm qfile

								./calcSF.sh $outputdir
						
							else ####NO SF
								awk -v qfile="qfile" -v optional=$Optional ' BEGIN {URI=0; LITERAL=0 }
								{
								# 1 URI, 1 SMALL LITERAL
									if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" )
										next
									else if ($2 ~ /^</ )
									{
										if(URI==0)
										{									
										print "?s2 " $1 " ?URI ." >> qfile
										print $1 >> "SF"
										URI=1
										}
									}
									else if ($2 !~ /####/ && LITERAL ==0)
									{
										if(optional==1)
										print "OPTIONAL {" >> qfile										
										print "?s2 " $1 " ?LITERAL ." >> qfile
										if(optional==1)
										print "}" >> qfile
										LITERAL=1
										print $1 >> "SF"
									}
									if( LITERAL == 1 && URI ==1 )
									{
										exit 1
									}
								}' qres
								if [ $filter -eq 1 ]; then
									
									cat qfile >> qfilter
									echo " }} " >> qfilter
									qfilter=`cat qfilter`
									./s-query --service http://localhost:3030/mydata/query "$qfilter" --output=tsv | sed 1d | sort -n > qres
									res=`wc -l < qres`
									if [ $res -gt 1 ]; then
										let med=($res+1)/2
										const=`awk -v med=$med 'NR==med{print;exit}' qres`
										if [[ $const =~ ^[0-9]+ ]]; then
											echo "FILTER(?LITERAL >= $const) ." >> qfile
										fi
									fi
								rm qfilter
												
								fi
								echo " } " >> qfile
								cat qfile  >> $outputdir/query
							
								if [ $service != "-" ]; then
									echo " } " >> qfile
									cat qfile >> $outputdir/queryservice
									#echo ${newline} >> $outputdir/queryservice
								fi
								rm qfile
								./calcSF.sh $outputdir
							fi ## end SF classes join
							
							#if [ $Optional -eq 1 ]; then
							#	echo "}" >> $outputdir/query
							#fi
							if [ $service != "-" ]; then
								echo "LIMIT 2 ${newline}" >> $outputdir/queryservice
							fi
							echo ${newline} >> $outputdir/query
							
						# NOT CLASS JOIN		
						else
							# parsing query results
							echo "#$qid#" >>$outputdir/query
							echo "select * { ${newline} ${arr[0]} ${arr[1]} ?s2 . " >>  $outputdir/query
							
							#service
							if [ $service != "-" ]; then
								echo "#$qid#" >> $outputdir/queryservice
								echo "select * { ${newline} service<$urldataset> {${newline}${arr[0]} ${arr[1]} ?s2 . }" >> $outputdir/queryservice														
								echo "service<$urlotherdataset> ${newline} {" >>  $outputdir/queryservice
							fi

							if [ $filter -eq 1 ]; then
								echo "select ?LITERAL { ${newline} graph<http://localhost/$datasetname> {${newline} ${arr[0]} ${arr[1]} ?s2 .}" > qfilter														
								echo "graph<http://localhost/$otherdatasetname> ${newline} {" >>  qfilter
							
							fi
							echo ${arr[1]} >> SF
							echo "linkentity" >> countqueries
							##########SF##############
							if [ $SF -eq 1 ]; then
								awk -v qfile="qfile" -v big=$BIGLITERAL -v LITERAL="" -v URI="" -v BIGLITERAL=""  ' NR==FNR{ref[$2]=$1;next} 
								{
								# 1 URI, 1 SMALL LITERAL
								#	print $1 
									if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" )
										next
									else if ($2 ~ /^</ )
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
										if (LITERAL == "") LITERAL=$1
										else if(ref[$2]>L)
											LITERAL=$1;L=ref[$2]
									}
								
								
								
								}END {
								if (URI != "")
								{
									print "?s2 " URI " ?URI ." >> qfile
									print URI >> "SF"
								}
								if(LITERAL!= "" && BIGLITERAL =="" )
								{
									print "?s2 " LITERAL " ?LITERAL ." >> qfile
									print "0" > "big"
									print LITERAL >> "SF"
								}
								if(BIGLITERAL!= "")
								{
									print "?s2 " BIGLITERAL " ?BIGLITERAL ." >> qfile
									print "1" > "big"
									print BIGLITERAL >> "SF"
								}
								}' $outputdir/OCP qres
								if [ $filter -eq 1 ]; then
									big=`cat big`
									if [big -eq 0 ]; then
										cat qfile >> qfilter
										echo " }} " >> qfilter
										qfilter=`cat qfilter`
										./s-query --service http://localhost:3030/mydata/query "$qfilter" --output=tsv | sed 1d | sort -n > qres
										res=`wc -l < qres`
										if [ $res -gt 1 ]; then
											let med=($res+1)/2
											const=`awk -v med=$med 'NR==med{print;exit}' qres`
											if [[ $const =~ ^[0-9]+ ]]; then
												echo "FILTER(?LITERAL >= $const) ." >> qfile
											fi
										fi
									fi
								fi
							#	rm qfilter
								echo " } " >> qfile
								cat qfile  >> $outputdir/query
								if [ $service != "-" ]; then
								echo " } " >> qfile
								cat qfile >> $outputdir/queryservice							
								fi
								rm qfile
								./calcSF.sh $outputdir
							else
								awk -v qfile="qfile" -v big=$BIGLITERAL ' BEGIN {URI=""; LITERAL=""; BIGLITERAL="" }
								{
								# 1 URI, 1 SMALL LITERAL, 1 BIG LITERAL
								#print BIGLITERAL >> qfile
									if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" )
										next
									else if ($2 ~ /^</)
									{ if(URI =="")
										{
										print "?s2 " $1 " ?URI ." >> qfile
										URI=1
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
										
									}
									
								}END {
								
								if(LITERAL!= "" && BIGLITERAL =="" )
								{
									print "?s2 " LITERAL " ?LITERAL ." >> qfile
									print "0" > "big"
									print LITERAL >> "SF"
								}
								if(BIGLITERAL!= "")
								{
									print "?s2 " BIGLITERAL " ?BIGLITERAL ." >> qfile
									print BIGLITERAL >> "SF"
									print "1" > "big"
								}
								}' qres
								if [ $filter -eq 1 ]; then
									big=`cat big`
									if [big -eq 0 ]; then
										cat qfile >> qfilter
										echo " }} " >> qfilter
										qfilter=`cat qfilter`
										./s-query --service http://localhost:3030/mydata/query "$qfilter" --output=tsv | sed 1d | sort -n > qres
										res=`wc -l < qres`
										if [ $res -gt 1 ]; then
											let med=($res+1)/2
											const=`awk -v med=$med 'NR==med{print;exit}' qres`
											if [[ $const =~ ^[0-9]+ ]]; then
												echo "FILTER(?LITERAL >= $const) ." >> qfile
											fi
										fi
									fi
								fi
#								rm qfilter
								echo " } " >> qfile
								cat qfile  >> $outputdir/query
								if [ $service != "-" ]; then
									echo " } " >> qfile
									cat qfile >> $outputdir/queryservice
								fi
								rm qfile
								./calcSF.sh $outputdir
							fi ### end sf entities
							if [ $service != "-" ]; then
								echo ${newline} >> $outputdir/queryservice
							fi
							echo ${newline} >> $outputdir/query
						fi ### end claass or entites
						((qid++))
						((line++))
						echo $qid > qid
						done <  $outputdir/linking
							
						
						cat entitytemp >> $outputdir/entity
						rm entitytemp qrestemp qres
					fi

				done < $outputdir/class/$otherdatasetname

			done < $outputdir/class/$datasetname
		fi

	done

done

sort -u $outputdir/interlinks > interlinkstemp
mv interlinkstemp $outputdir/interlinks
