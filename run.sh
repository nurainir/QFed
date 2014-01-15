#Outputdir="/tmp/"
#SF=`cat $Outputdir/SF`
#q=`cat qid`
#AvgSF=`echo "scale=2;$SF / $q" | bc -l` 
#echo $AvgSF


#########SF#############
#########NO B###########
###T2 N2#####
 ./querysetinit.sh -i $1 -o /tmp/out -D -n 2 -T 2 -s endpoints
mv query queryset/qDn2T2
mv queryservice queryserviceset/qDn2T2Service
###T3 N3#####
 ./querysetinit.sh -i $1 -o /tmp/out -D -n 3 -T 3 -s endpoints 
mv query queryset/qDn3T3
mv queryservice queryserviceset/qDn3T3Service
##########B#############
###T2 N2#####
 ./querysetinit.sh -i $1 -o /tmp/out -D -n 2 -T 2 -s endpoints -B
mv query queryset/qDn2T2B
mv queryservice queryServiceset/qDn2T2BService
###T3 N3#####
 ./querysetinit.sh -i $1 -o /tmp/out -D -n 3 -T 3 -s endpoints -B
mv query queryset/qDn3T3B
mv queryservice queryServiceset/qDn3T3BService

#########NOSF###########

#########NO B###########
###T2 N2#####
 ./querysetinit.sh -i $1 -o /tmp/out  -n 2 -T 2 -s endpoints
mv query queryset/qn2T2
mv queryservice queryserviceset/qn2T2Service
###T3 N3#####
 ./querysetinit.sh -i $1 -o /tmp/out  -n 3 -T 3 -s endpoints 
mv query queryset/qn3T3
mv queryservice queryserviceset/qn3T3Service
##########B#############
###T2 N2#####
 ./querysetinit.sh -i $1 -o /tmp/out  -n 2 -T 2 -s endpoints -B
mv query queryset/qn2T2B
mv queryservice queryserviceset/qn2T2BService
###T3 N3#####
 ./querysetinit.sh -i $1 -o /tmp/out  -n 3 -T 3 -s endpoints -B
mv query queryset/qn3T3B
mv queryservice queryserviceset/qn3T3BService


#######OPTIONAL#############

#########SF#############
#########NO B###########
###T2 N2#####
 ./querysetinit.sh -i $1 -o /tmp/out -D -n 2 -T 2 -s endpoints -O
mv query queryset/qDn2T2O
mv queryservice queryserviceset/qDn2T2OService
###T3 N3#####
 ./querysetinit.sh -i $1 -o /tmp/out -D -n 3 -T 3 -s endpoints -O ## running
mv query queryset/qDn3T3O
mv queryservice queryserviceset/qDn3T3OService
##########B#############
###T2 N2#####
 ./querysetinit.sh -i $1 -o /tmp/out -D -n 2 -T 2 -s endpoints -B -O
mv query queryset/qDn2T2BO
mv queryservice queryServiceset/qDn2T2BOService
###T3 N3#####
 ./querysetinit.sh -i $1 -o /tmp/out -D -n 3 -T 3 -s endpoints -B -O
mv query queryset/qDn3T3BO
mv queryservice queryServiceset/qDn3T3BOService

#########NOSF###########

#########NO B###########
###T2 N2#####
 ./querysetinit.sh -i $1 -o /tmp/out  -n 2 -T 2 -s endpoints -O
mv query queryset/qn2T2O
mv queryservice queryServiceset/qn2T2OService
###T3 N3#####
 ./querysetinit.sh -i $1 -o /tmp/out  -n 3 -T 3 -s endpoints -O 
mv query queryset/qn3T3O
mv queryservice queryServiceset/qn3T3OService
##########B#############
###T2 N2#####
 ./querysetinit.sh -i $1 -o /tmp/out  -n 2 -T 2 -s endpoints -B -O
mv query queryset/qn2T2BO
mv queryservice queryServiceset/qn2T2BOService
###T3 N3#####
 ./querysetinit.sh -i $1 -o /tmp/out  -n 3 -T 3 -s endpoints -B -O
mv query queryset/qn3T3BO
mv queryservice queryserviceset/qn3T3BOService







########NO THRESHOLD####
# ./querysetinit.sh -i $1 -o /tmp/out -n 2 -s endpoints
#mv query unlimited2
#mv queryservice unlimited2Service
# ./querysetinit.sh -i $1 -o /tmp/out -n 3 -s endpoints
#mv query unlimited3
#mv queryservice unlimited3Service


