#!/bin/bash

check=`cat /home/nurrak/fuseki/check`
if [ $check -eq 0 ]; then
echo "ZZZ" > checkxx

kill `ps -ef | grep "fuseki-server.jar" | grep -v grep | awk '{print $2}'`

sleep 10s
echo "xxx"
cd /home/nurrak/fuseki
rm -Rf dailymed
mkdir dailymed
/usr/bin/java -jar  fuseki-server.jar --port 8001 --update --loc=dailymed /dailymed &
sleep 50s
./s-put http://localhost:8001/dailymed/data default /home/nurrak/dataset/drug/dailymed_dump.nt
rm -Rf drugbank
rm -Rf drugbank1
mkdir drugbank1
/usr/bin/java -jar  fuseki-server.jar --port 8000 --update --loc=drugbank1 /drugbank1 &
sleep 50s
./s-put http://localhost:8000/drugbank1/data default /home/nurrak/dataset/drug/drugbank1.nt

rm -Rf drugbank2
mkdir drugbank2
/usr/bin/java -jar  fuseki-server.jar --port 8004 --update --loc=drugbank2 /drugbank2 &
sleep 50s
./s-put http://localhost:8004/drugbank2/data default /home/nurrak/dataset/drug/drugbank2.nt

echo "AAA" > checkxx
rm -Rf disease
mkdir disease
/usr/bin/java -jar  fuseki-server.jar --port 8002 --update --loc=disease /disease &
sleep 50s
./s-put http://localhost:8002/disease/data default /home/nurrak/dataset/drug/diseasome.nt

rm -Rf sider
mkdir sider
/usr/bin/java -jar  fuseki-server.jar --port 8003 --update --loc=sider /sider &
sleep 50s
./s-put http://localhost:8003/sider/data default /home/nurrak/dataset/drug/sider_dump.nt

echo "1" > /home/nurrak/fuseki/check

cd /home/nurrak/
fi

#for qService in $1/*Service 
#do
#echo "validate $qService" >> log
#./validate.sh $qService http://localhost:3030/mydata/query
#res=`wc -l < $qService-failed`
#echo "$res queries failed" >> log
#done
