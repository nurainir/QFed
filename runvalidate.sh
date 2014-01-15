
kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
sleep 10s
rm -Rf data
mkdir data
java -jar  fuseki-server.jar --update --loc=data /mydata &
sleep 10
./s-put http://localhost:3030/mydata/data default endpoint.ttl
sleep 50s
rm -Rf dailymed
mkdir dailymed
java -jar  fuseki-server.jar --port 8001 --update --loc=dailymed /dailymed &
sleep 50s
./s-put http://localhost:8001/dailymed/data default ~/dataset/drug/dailymed_dump.nt

rm -Rf drugbank
mkdir drugbank
java -jar  fuseki-server.jar --port 8000 --update --loc=drugbank /drugbank &
sleep 50s
./s-put http://localhost:8000/drugbank/data default ~/dataset/drug/drugbank_dump.nt


rm -Rf disease
mkdir disease
java -jar  fuseki-server.jar --port 8002 --update --loc=disease /disease &
sleep 50s
./s-put http://localhost:8002/disease/data default ~/dataset/drug/diseasome.nt

rm -Rf sider
mkdir sider
java -jar  fuseki-server.jar --port 8003 --update --loc=sider /sider &
sleep 50s
./s-put http://localhost:8003/sider/data default ~/dataset/drug/sider_dump.nt



for qService in $1/*Service 
do
echo "validate $qService" >> log
./validate.sh $qService http://localhost:3030/mydata/query
res=`wc -l < $qService-failed`
echo "$res queries failed" >> log
done
