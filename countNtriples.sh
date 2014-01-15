# Author : Nur Aini Rakhmawati, March 1st, 2013 ... 40 Weeks of pregnancy

if [ ! -d outNtriples ]; then
   mkdir outNtriples
fi


 awk '{ if ( NR ==1 ) sentence=$0; else if (NF == 0 || $0 ~ /^T/) {kosong=1; next;} else if (kosong ==1){ sentence=sentence$0; kosong=0} else { print sentence; kosong=0; sentence=$0} }' queryrequest > queryrequest1
mv queryrequest1 queryrequest

#splitting file. limited by HTTP
csplit -z -s -f  outNtriples/tes queryrequest '/HTTP/' {*}
total=0
max=0
ntriple=0
for file in outNtriples/*
do
if [ `grep -c "results+xml" $file` -gt 0 ]; then
 
ntriple=`grep -o "<result>" $file| wc -l`
total=$(($total+$ntriple))
elif [ `grep -c "results+json" $file` -gt 0 ]; then

var=`grep -E "^ *\"vars" $file | sed  's/^ *"vars": *\[ *\(.*\) *]\$/\1/'`
var1=${var%%,*}
var1=`echo $var1 | sed 's/^"\(.*\)"$/\1/'`

ntriple=`grep -o '"'$var1'":' $file | wc -l`
total=$(($total+$ntriple))

elif [ `grep -c "rdf+xml" $file` -gt 0 ]; then

ntriple=`grep -o "<rdf:Description" $file | wc -l`
total=$(($total+$ntriple))

fi

if [ $ntriple -gt $max ]; then
	max=$ntriple	
fi

done

echo $total $max

if [ -d outNtriples ]; then
   rm -Rf outNtriples
fi

if [ -f queryrequest ]
then
   rm queryrequest
fi
