#need SF, OCP, OCC
#input outputdir
outputdir=$1

#check exist SF
i=0
for dump in $outputdir/dump/*
do
((i++))
done

if [ ! -f SF ];
then
echo "cannot find SF"
exit 1
fi

#calculate properties
SFP=`awk -v NT=$i ' NR==FNR{ref[$1]=$2;next}  
{
if(ref[$1])
total=total+ref[$1]
else if($1 ~ /^\?/)
total=total+NT
}END { print total }'  $outputdir/OCP SF`

#calculate classes
SFC=`awk -v NT=$i ' NR==FNR{ref[$1]=$2;next}  
{
if(ref[$1])
total=total+ref[$1]
else if($1 ~ /^\?/)
total=total+NT
}END { print total }'  $outputdir/OCC SF`



SFprev=`cat $outputdir/SF`
SFT=$((SFC+SFP+SFprev))
echo $SFT > $outputdir/SF
rm SF
