#!/bin/bash
#--------------------------------------------------------------
# Purpose: Inserts traceroute files into database
# Execution: bash insertIntoDb.sh <traceroutes folder name> 
# Author: Oscar Li
#--------------------------------------------------------------

CURR_DIR=`pwd`

# Takes traceroute file and inserts it into DB 
function insert
{
	srcIP=`sed -n 2p < "$1" | cut -d "(" -f2 | cut -d ")" -f1` 
	if [ "$srcAS" = "*" ];
	then
		srcAS="AS"`whois -h whois.cymru.com " -v $srcIP" | tail -1 | cut -f1 -d" "`
	else 
		srcAS=`sed -n 2p < "$1" | cut -d "[" -f2 | cut -d "]" -f1`
	fi

	destIP=`echo $1 | awk -F"/" '{print $NF}' | cut -f1 -d "("`
	destAS="AS"`whois -h whois.cymru.com " -v $destIP" | tail -1 | cut -f1 -d" "`
	tstamp=`echo $1 | cut -d "(" -f2 | cut -d ")" -f1`
	path=`cat "$1"`

	echo $path | grep -o '\[[AS[0-9\/]*]*\]' | awk '!x[$0]++' > temp.txt
	aspath=`cat temp.txt` 
	numases=`wc -l < temp.txt | tr -d " \t\n\r"` 

	# A traceroute is invalid if it has more than 2 routers that timed out
	valid="true"
	if [ `grep -o "\* \* \*" "$1" | wc -l` -ge 2 ]; 
	then 
		valid="false"
	fi 

	# Inserts into database
	query="INSERT INTO paths (tstamp, srcip, srcas, destip, destas, path, aspath, numases, type, valid) \
		   VALUES (to_timestamp('$tstamp', 'MM-DD-YY-HH24:MI'), \
		   		   '$srcIP', '$srcAS', '$destIP', '$destAS', '$path', '$aspath', $numases, '$type', $valid);"
	# psql -U oli -d raptor -w -c "$query"

	# For debug
	echo "$1"
	echo "HOST: $host"
	echo "srcIP: $srcIP"
	echo "srcAS: $srcAS"
	echo "destIP: $destIP"
	echo "destAS: $destAS"
	echo "aspath: $aspath"
	echo "numases: $numases"
	echo "tstamp: $tstamp"
	echo "valid: $valid"
	echo	
}

cd $1

type="Entry"
if [[ $1 == *exit* ]];
then
	type="Exit"
fi

for host in *
do
	cd $host 
	for traceroute in * 
	do 
		insert "$CURR_DIR/$1/$host/$traceroute" &
		sleep 1
	done

	cd ..
	sleep 15
	# rm -rf $host
done

cd ..
# rmdir "$1"