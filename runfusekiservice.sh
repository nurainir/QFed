
kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
sleep 10s
java -jar  fuseki-server.jar --update --loc=data /mydata &

rm cache.db
for i in 1 
do
mkdir $i
for qService in $1/C2*
do
echo "validate $qService" >> log
./validate.sh $qService http://localhost:3030/mydata/query
res=`wc -l < $qService-failed`
mv $qService-failed $i
mv $qService-fedsuccess $i
echo "$res queries failed" >> log
done
done

