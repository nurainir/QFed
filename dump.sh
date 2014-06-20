fileNT=$1
filename=${fileNT##*/}
outputdir=$2

awk -v dataset=$outputdir -v filename=$filename '
{
s=$1
p=$2
o=$3
IGNORECASE = 1

	#print p
	if(tolower(o) == "<http://www.w3.org/2000/01/rdf-schema#class>" || tolower(o) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#property>"  || tolower(p) == "<http://www.w3.org/2002/07/owl#equivalentclass>" || tolower(p) == "<http://www.w3.org/2002/07/owl#equivalentproperty>" || tolower(p) == "<http://www.w3.org/2000/01/rdf-schema#subclassof>" ) 
	next

	else if(tolower(p) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>")
	{
		
			
		listclass[o]++
		print $0 >> dataset "/dump/" filename 
		print $1 "\t" $3 >> dataset "/entities/" filename 
		
		
	}
	else if (o ~ /^</ ) 
	{
		listprop[p]++
		print $0 >> dataset "/dump/" filename  
	}	
	else if (NF < 10 || p ~ /name/ || p ~ /label/)
	{
		listprop[p]++
		print $0 >> dataset "/dump/" filename  
	}	
	else
	{
		listprop[p]++ # large literal length

		print $1 " " $2 " \"####\" ." >> dataset "/dump/" filename 
	}
	
 }
END{
	for(iclass in listclass)
	{
		#if( ) 	
		print iclass " " listclass[iclass] >> dataset "/class/" filename
	}
	for(prop in listprop)
	{
		#if(	)	
		print prop " " listprop[prop] >> dataset "/prop/" filename

	}


}' $fileNT


cat $outputdir/class/$filename >> /tmp/class
cat $outputdir/prop/$filename >> /tmp/prop
