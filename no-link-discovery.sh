outputdir=$1
let numberofqueries=$2+1
BIGLITERAL=$3
SF=$4
prune=$5
> $outputdir/linking
Optional=$6
service=$7
filter=$8
newline='
'> sameproperties
qid=`cat qid`
echo "dummy dummyy" > $outputdir/entity
for dataset in $outputdir/dump/*
do
	
	datasetname=${dataset##*/}
	for otherdataset in $outputdir/dump/*
	do
		
		otherdatasetname=${otherdataset##*/}
		
		if [ $otherdatasetname != $datasetname ]; then
			> nolink
			#echo "compare  $datasetname $otherdatasetname "
			if [ $service != "-" ]; then
				urldataset=`grep "$datasetname" $service | awk '{print $2}'`
				urlotherdataset=`grep "$otherdatasetname" $service | awk '{print $2}'`
			fi
			awk -v limit=$numberofqueries -v qid=$qid -v qfile=$outputdir '{
			if(NR==FNR){ 
				if($3 !~ /####/ && (tolower($2) != "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" ) ) 					{ if(NF==4) {object[$3]=$1 "\t" $2; next} else if (NF==5)  {object[$3]=$1 "\t" $2 " " $3; next}}; subject[$1]; next }
			 
			#############
			##smushing queries
			############
			if(subject[$1] && es[$1]!=1 )
				{
					if( tolower($3) != "<http://www.w3.org/1999/02/22-rdf-syntax-ns#property>")
					{					
						print "#" qid "#" >> qfile
						print "select * { " $1 " ?p ?o }\n" >> qfile "/query"
						print "?p" > "SF"
						system("./calcSF.sh " qfile)
						qid++
						print "smush" >> "countqueries"
						es[$1]=1
						
					}
			
					if(tolower($2) != "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" )
					{
						print "#" qid "#" >> qfile
						print "select * { \n ?s " subject[$1] " ?o1 ." >> qfile "/query"
						print subject[$1] > "SF"
						print "?s " $2 " ?o2 . \n } \n"
						print $2 >> "SF"
						print "smush" >> "countqueries"
						system("./calcSF.sh " qfile)
						qid++
						es[$1]=1
					}
					
				}	
			##############
			##object comparison
			##############		
			if( $3 ~ /####/ && tolower($2) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" )
				next
			else if(NF==4 && object[$3] && e[$1]!=1 && p[$2] < limit   )
				{  
				print $1 "\t" $2 "\t" object[$3]  >> "nolink" 
				e[$1]=1 
				p[$2]++ 
				### same properties
				otherdata=split(object[$3] ,arr,"\t")
				if(arr[1]==$2)
					print $2 "\t" $3 >> "sameproperties"
				}
			else if (NF==5)
			{
				obj=$3 " " $4
				if (object[obj] && e[$1]!=1 && p[$2] < limit   )
				{  
				print $1 "\t" $2 "\t" object[obj]  >> "nolink" 
				e[$1]=1 
				p[$2]++ }
			}
} END {
		print qid > "qid"
				}' $otherdataset $dataset

			

			#to avoid redundancy store class and properties in the classquery
			if [ $prune -eq 0 ]; then
				sort -k2,2 -k1,1 nolink | uniq  > nolinktemp
				mv nolinktemp nolink
			else
			### prunning steps ###
			awk 'NR==FNR{ref[$1]=$3;next} 
			{
			if(ref[$2])
				print ref[$2] "\t" $0 >> "nolinktemp" }' $outputdir/OCP nolink		
			
			sort -n -r -k 1,1 -k3,3 -k 2,2 nolinktemp | uniq | awk -F '\t' -v prune=$prune -v p="" ' {
			if(p!=$3) 
				{
				po++	
				p=$3
				print $2 "\t" $3  "\t" $4 "\t" $5 
				}
			else if(po < prune)
			print $2 "\t" $3  "\t" $4 "\t" $5 
			if(po == prune)
			exit 1 		
			}
			' > nolink
			fi
			##limit the query
			head -n $numberofqueries nolink > nolinktemp
			mv nolinktemp nolink

			> propnolink
			
			while read line
			do
			#split by tab
			arr=(${line//'\t'/ })
			./s-query --service http://localhost:3030/mydata/query "SELECT * { 
							graph<http://localhost/$datasetname>
							{ ${arr[0]} a  ?class1 }
							graph<http://localhost/$otherdatasetname>
							{ ${arr[2]} a  ?class2 }	
							} " --output=tsv | sed 1d | sort -u > qres

			while read classres
			do
				class=(${classres//'\t'/ })
				#finding properties
				./s-query --service http://localhost:3030/mydata/query "SELECT * { 
							graph<http://localhost/$otherdatasetname>
							{ ${arr[2]} ?p  ?o }	
							} " --output=tsv | sed 1d | sort -u > qresprop

				freqprop=`grep -c "${arr[1]}" propnolink`
						# parsing query results
							if [ $qid -gt 1 ]; then
								 echo "${newline}#$qid#" > qfile
							else
								echo "#$qid#" > qfile
							fi

							cat qfile >> $outputdir/query


				############## if p1==p2, we can create query select * { ?s1 p1 o1}
				#

				
				if [ $freqprop -eq 0 ]; then #class query
							echo "objclass" >> countqueries
							echo "select * { ${newline} ?s1 a ${class[0]} . ${newline} ?s1 ${arr[1]} ?o . ${newline} ?s2 a ${class[1]} . ${newline} ?s2 ${arr[3]} ?o .  " >> $outputdir/query
							if [ $service != "-" ]; then
							cat qfile >> $outputdir/queryservice
							echo "select * { ${newline} service<$urldataset> {${newline} ?s1 a ${class[0]} . ${newline} ?s1 ${arr[1]} ?o .}" >> $outputdir/queryservice														
							echo "service<$urlotherdataset> ${newline} { ?s2 a ${class[1]} . ${newline} ?s2 ${arr[3]} ?o ." >>  $outputdir/queryservice
							
							fi
							s1=${arr[0]}	
							echo ${class[0]} > SF					
							echo ${class[1]} >> SF	
							echo ${arr[3]} >> SF
							curprop=${arr[3]}
							#### optional
							#if [ $Optional -eq 1 ]; then
							#	echo "OPTIONAL { ">> $outputdir/query
							#fi
							##########SF##############
							if [ $SF -eq 1 ]; then
							rm qfile
#							awk -v qfile="qfile" -v prop=$curprop -v LITERAL="" -v URI="" ' NR==FNR{ref[$1]=$2;next} 
#							{
#							# 1 URI, 1 SMALL LITERAL
#							
#								if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" || $1 == prop)
#									next
#								else if ($2 ~ /^</ )
#								{
#									if (URI == "")
#									URI=$1													
#									else if(URI != $1 && ref[$2]>U)
#										{URI=$1; U=ref[$2]}
#											
#								}
#								else if ($2 !~ /####/ && LITERAL != $1)
#								{
#									if (LITERAL == "") LITERAL=$1
#									else if(ref[$2]>L)
#										{LITERAL=$1;L=ref[$2]}
#								}
#								
#							}
#							END {
#							if (URI != "")
#							{
#								print "?s2 " URI " ?URI ." >> qfile
#								print URI >> "SF"
#							}
#							if(LITERAL!= "")
#							{
#								print "?s2 " LITERAL " ?LITERAL ." >> qfile
#								print LITERAL >> "SF"
#							}
#							}' $outputdir/OCP qresprop
#							echo " } " >> qfile
#								cat qfile  >> $outputdir/query
#								if [ $service != "-" ]; then
#									echo " } " >> qfile
#									cat qfile >> $outputdir/queryservice
#									
#								fi
#								rm qfile
#							
#							./calcSF.sh $outputdir
							###################hybrid query################################
							rm hybrid	
									
							awk -v qfile="qfile" -v prop=$curprop -v LITERAL="" -v URI="" -v HYBIRD="" -v s1=$s1 -v optional=$Optional -v filter=$filter '{
							if(FNR ==1) f++
							if(NR==FNR){ref[$1]=$2;next}
							else if(f==2){ref2[$1]=1;next}
							# 1 URI, 1 SMALL LITERAL
							
								if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" || $1 == prop)
									next
								else if ($2 ~ /^</ )
								{
									if (ref2[$1] && s1!=$2 && HYBIRD =="")
										{HYBIRD=$1
										s3=$2
										}									
									else if (URI == "")
							URI=$1													
									else if(URI != $1 && ref[$2]>U)
										{URI=$1; U=ref[$2]}
										
											
								}
								else if ($2 !~ /####/ && LITERAL != $1)
								{
									if (LITERAL == "") { LITERAL=$1; myfilter=$2}
									else if(ref[$2]>L)
										{LITERAL=$1;L=ref[$2];myfilter=$2}
									
								}
								
							}
							END {
							if( HYBIRD != "")
								print s3  >> "hybridtemp"
							if (URI != "")
							{
								print "?s2 " URI " ?URI ." >> qfile
								print URI >> "SF"
								if( HYBIRD != "" && HYBIRD != URI)
								print "?s2 " URI " ?URI ." >> "hybrid" ; print URI >> "hsf"
							}
							if(LITERAL!= "")
							{
								if(optional==1)
										print "OPTIONAL {" >> qfile
								print "?s2 " LITERAL " ?LITERAL ." >> qfile
							
								if(optional==1)
										print "}" >> qfile
								if(myfilter ~ /^[0-9]+/ && filter==1)
								print "FILTER (?LITERAL >= " myfilter " )" >> qfile	
								if( HYBIRD != "")
								print "?s2 " LITERAL " ?LITERAL ." >> "hybrid"; print LITERAL >> "hsf"
							}
							if( HYBIRD != "")
								print "?s2 " HYBIRD " ?s3 ."  >> "hybrid"; print HYBIRD >> "hsf"
							
							}' $outputdir/OCP $outputdir/interlinks qresprop
							
							echo " } " >> qfile
								cat qfile  >> $outputdir/query
								if [ $service != "-" ]; then
									echo " } " >> qfile
									cat qfile >> $outputdir/queryservice
									
								fi
								rm qfile
							
							./calcSF.sh $outputdir
							
							###############################################################
							
							else
							rm hybrid
							rm qfile
							
							awk -v qfile="qfile" -v prop=$curprop  -v HYBIRD="" -v s1=$s1 -v optional=$Optional -v filter=$filter ' BEGIN {URI=""; LITERAL="" }
							{
								if(NR==FNR){ref[$1]=1;next}
								if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" || $1 == prop)
									next
								else if ($2 ~ /^</ )
								{
									#print $1 " H " HYBIRD " U " URI >> "/tmp/testing"
									if (ref[$1]==1 && s1!=$2 && HYBIRD =="")
									{
									print $2  >> "hybridtemp"
									HYBIRD=$1
									
									}									
									else if(URI=="")
									{									
									print "?s2 " $1 " ?URI ." >> qfile
									print $1 >> "SF"
									URI=$1
									}
									
								}
								else if ($2 !~ /####/ && LITERAL =="")
								{
									if(optional==1)
										print "OPTIONAL {" >> qfile
									print "?s2 " $1 " ?LITERAL ." >> qfile
									if(optional==1)
										print "}" >> qfile
									if($2 ~ /^[0-9]+/ && filter==1)
										print "FILTER (?LITERAL  >= " $2 " )" >> qfile	
									LITERAL=$1
									print LITERAL >> "SF"
								}
								
							}
							END {
							if( HYBIRD != "")
							{
								if(URI!="")								
								print "?s2 " URI " ?URI ." >> "hybrid" ; print URI >> "hsf"
								if(LITERAL !="")
								print "?s2 " LITERAL " ?LITERAL ." >> "hybrid"; print LITERAL >> "hsf"
								print "?s2 " HYBIRD " ?s3 ."  >> "hybrid"; print HYBIRD >> "hsf"
								
							}
							}' $outputdir/interlinks qresprop
							echo " } " >> qfile
								cat qfile  >> $outputdir/query
							
								if [ $service != "-" ]; then
									echo " } " >> qfile
									cat qfile >> $outputdir/queryservice
									#echo ${newline} >> $outputdir/queryservice
								fi
								rm qfile
								./calcSF.sh $outputdir
							
							fi
							
							#cat hybrid >> $outputdir/query
							#echo "hybrid $s1" >> /tmp/testing
							#cat qresprop >> $outputdir/query
							((qid++))
							echo $qid > qid
							echo "${arr[1]}" >> propnolink
							#if [ $Optional -eq 1 ]; then
							#	echo "}" >> $outputdir/query
							#fi
							if [ $service != "-" ]; then
								echo "LIMIT 2${newline}" >> $outputdir/queryservice
							fi
							echo ${newline} >> $outputdir/query
							#####processing hybrid
							####
							if [ -f hybrid ]
							then
																
								#echo "$datasetname $otherdatasetname" >> hybridtemp
								if [ $service != "-" ]; then
									echo "service<$urldataset> {" >> hybridtemps
									echo "$s1 ${arr[1]} ?o . }" >> hybridtemps
									echo "service<$urlotherdataset> ${newline} { ?s2 a ${class[1]} ." >> hybridtemps
									echo "?s2 ${arr[3]} ?o ." >> hybridtemps
									cat hybrid >> hybridtemps
									echo "}" >> hybridtemps
								fi
	    					 		echo "$s1 ${arr[1]} ?o ." >> hybridtemp
								echo "?s2 a ${class[1]} ." >> hybridtemp
								echo "?s2 ${arr[3]} ?o ." >> hybridtemp
								cat hybrid >> hybridtemp
								
	    							
								mv hybridtemp hybrid
								mv hybridtemps hybrids
								echo ${arr[1]} >> hsf
								echo ${class[1]} >> hsf
								echo ${arr[3]} >> hsf
								./hybrid.sh $outputdir $SF $service
								qid=`cat qid`
							fi
						
			##### subject constant query
				else
					echo "select * { ${newline} ${arr[0]} ${arr[1]} ?o . ${newline} ?s2 a ${class[1]} . ${newline} ?s2 ${arr[3]} ?o .  " >> $outputdir/query
							if [ $service != "-" ]; then
							cat qfile >> $outputdir/queryservice
							echo "select * { ${newline} service<$urldataset> {${newline} ${arr[0]} ${arr[1]} ?o  . }" >> $outputdir/queryservice														
							echo "service<$urlotherdataset> ${newline} {  ${newline} ?s2 ${arr[3]} ?o .  " >>  $outputdir/queryservice
							fi
					echo "objentity" >> countqueries
						echo ${arr[1]} > SF					
							echo ${class[1]} >> SF	
							echo ${arr[3]} >> SF
		
							curprop=${arr[3]}
							##########SF##############
							if [ $SF -eq 1 ]; then
							rm qfile
							awk -v qfile="qfile" -v prop=$curprop -v big=$BIGLITERAL -v LITERAL="" -v URI="" -v BIGLITERAL="" -v filter=$filter ' NR==FNR{ref[$1]=$2;next} 
							{
							# 1 URI, 1 SMALL LITERAL
							#	print $1 
								if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" || $1 == prop)
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
									if (LITERAL == "") { LITERAL=$1; myfilter=$2}
									else if(ref[$2]>L)
										{LITERAL=$1;L=ref[$2];myfilter=$2}
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
									if(myfilter ~ /^[0-9]+/ && filter==1)
									print "FILTER (?LITERAL >= " myfilter " )" >> qfile	
									print LITERAL >> "SF"
								}
								if(BIGLITERAL!= "")
								{
									print "?s2 " BIGLITERAL " ?BIGLITERAL ." >> qfile
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
							awk -v qfile="qfile" -v prop=$curprop -v big=$BIGLITERAL -v filter=$filter' BEGIN {URI=""; LITERAL=""; BIGLITERAL="" }
							{
							# 1 URI, 1 SMALL LITERAL
							#	print $1 
								if(tolower($1) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" || $1 == prop)
									next
								else if ($2 ~ /^</) 
								{if(URI =="")
									{
									print "?s2 " $1 " ?URI ." >> qfile
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
									print "?s2 " LITERAL " ?LITERAL ." >> qfile
									if(myfilter ~ /^[0-9]+/ && filter==1)
									print "FILTER (?LITERAL >= " myfilter " )" >> qfile	
									print LITERAL >> "SF"
								}
								if(BIGLITERAL!= "")
								{
									print "?s2 " BIGLITERAL " ?BIGLITERAL ." >> qfile
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
							echo "${arr[1]}" >> propnolink
							#if [[ $numberofqueries -eq qid ]]; then
								break
							#fi
				fi	

			done < qres
	
			done < nolink		

		fi

	done

done
rm qresprop qres

sort -u sameproperties > samepropertiestemp
mv samepropertiestemp  sameproperties

while read line 
do
if [ $qid -gt 1 ]; then
	echo "${newline}#$qid#" > qfile
else
	echo "#$qid#" > qfile
fi
cat qfile >> $outputdir/query

arr=(${line//'\t'/ })
echo "${arr[0]}" >> SF


echo "select * { ${newline} ?s $line .} ${newline}  " >> $outputdir/query

if [ $service != "-" ]; then
		cat qfile >> $outputdir/queryservice
		echo "select * { ${newline} ?d <http://rdfs.org/ns/void#sparqlEndpoint> ?endpoint . "  >> $outputdir/queryservice		
		echo " SERVICE ?endpoint {${newline} ?s $line  . }} ${newline} " >> $outputdir/queryservice					
	fi

	
./calcSF.sh $outputdir	
echo "nolinksameprops" >> countqueries	
((qid++))
done < sameproperties

echo $qid > qid	
