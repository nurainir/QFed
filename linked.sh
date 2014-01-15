data1=$1
col1=$2
voc1=$3
data2=$4
col2=$5
voc2=$6

awk -F$'\t' -v col=$col1 '{print $col} ' $data1 > data1

awk -F$'\t' -v col=$col2 '{print $col} ' $data2 > data2

awk -v voc1=$voc1 -v voc2=$voc2 'NR==FNR{ref[$0]=1;next} 
{
if(ref[$0]==1)
{
gsub(" ","_",$0); en=$0
	print "<" voc1 en ">\t<http://www.w3.org/2002/07/owl#sameAs>\t<"  voc2 en "> ." >> "link1"
 	print "<" voc2 en ">\t<http://www.w3.org/2002/07/owl#sameAs>\t<"  voc1 en "> ." >> "link2"
}}
' data1 data2 

sort -u link1 > temp
mv temp link1

sort -u link2 > temp
mv temp link2
