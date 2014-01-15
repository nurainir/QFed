timeout=600                       # in seconds
query=`cat queryval`
pid=`cat pid`
./s-query --service $2 "$query" --output=tsv | sed 1d > qres & cmdpid=$!      # Command to terminate
(sleep $timeout; echo "$3 timeout" >> $1-failed; rm qres; rm queryval; kill -9 $cmdpid
kill `ps -ef | grep tcpdump | grep -v "grep"  | awk '{print $2}'`
kill `ps -ef| grep "sleep" |  awk '{ if($8 ~/^sleep/)  print $2}'`
kill -9 $pid
) &
watchdogpid=$!
wait $cmdpid                    # wait for command
kill $watchdogpid >/dev/null 2>&1
kill `ps -ef | grep tcpdump | grep -v "grep"  | awk '{print $2}'`
kill `ps -ef| grep "sleep" |  awk '{ if($8 ~/^sleep/)  print $2}'`
kill -9 $pid
rm pid
