timeout=600                       # in seconds
echo "running fedX"
pid=`cat pid`
pid2=`cat pid2`
./cli.sh -d $2 @q queryfed > qres & cmdpid=$!     
echo "done "
(sleep $timeout; echo "$3 timeout" >> $1-failed; echo "$3 - - - - - - - - - - -" >> $1-fedsuccess; rm qres; rm queryfed; kill -9 $cmdpid >/dev/null 2>&1; rm queryrequest
kill `ps -ef | grep tcpdump | grep -v "grep"  | awk '{print $2}'`
kill `ps -ef| grep ngrep |  awk '{ if($8 ~/^ngrep/)  print $2}'`
kill `ps -ef| grep "sleep" |  awk '{ if($8 ~/^sleep/)  print $2}'`
kill `ps -ef | grep CLI |awk '{ if($12 ~/^com\.fluidops\.fedx\.CLI/)  print $2}'`
kill -9 $pid; kill -9 $pid2
) &
watchdogpid=$!
wait $cmdpid                    # wait for command
kill $watchdogpid >/dev/null 2>&1
kill `ps -ef | grep tcpdump | grep -v "grep"  | awk '{print $2}'`
kill `ps -ef| grep ngrep |  awk '{ if($8 ~/^ngrep/)  print $2}'`
kill `ps -ef| grep "sleep" |  awk '{ if($8 ~/^sleep/)  print $2}'`
kill `ps -ef | grep CLI |awk '{ if($12 ~/^com\.fluidops\.fedx\.CLI/)  print $2}'`
kill $pid; kill $pid2
rm pid
rm pid2

