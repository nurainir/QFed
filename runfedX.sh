
kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
sleep 10s

rm cache.db
for i in 1 2 3
do
mkdir $i-res
for qService in $1/C2*
do
echo "validate $qService" >> log
./fedX.sh $qService datasource.ttl 
res=`wc -l < $qService-failed`
mv $qService-failed $i-res
mv $qService-fedsuccess $i-res
echo "$res queries failed" >> log
done
done

