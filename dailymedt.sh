kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
sleep 5s
rm  query8*.log
rm -Rf dailymed0
mkdir dailymed0
java -jar  fuseki-server.jar --port 8000 --update --loc=dailymed0 /dailymed &
sleep 15s
./s-put http://localhost:8000/dailymed/data default /tmp/dataset/drug.nt
rm -Rf dailymed1
mkdir dailymed1
java -jar  fuseki-server.jar --port 8001 --update --loc=dailymed1 /dailymed &
sleep 15s
./s-put http://localhost:8001/dailymed/data default /tmp/dataset/ingridient.nt
rm -Rf dailymed2
mkdir dailymed2
java -jar fuseki-server.jar --port 8002 --update --loc=dailymed2 /dailymed &
sleep 15s
./s-put http://localhost:8002/dailymed/data default /tmp/organization.nt

