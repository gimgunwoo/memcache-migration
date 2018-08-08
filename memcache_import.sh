#!/bin/bash

KEYDUMP="/root/KEY"
VALUE="/root/VALUE"
LOG="/var/log/memcache-mover"
OLDHOSTIP=$1

#cleanup log file
echo "" > $LOG

#dump data from an old memcache server
#libmemcached-tools is required
memcdump --servers="$OLDHOSTIP" > $KEYDUMP

while read -r line; do
    echo "get $line" | nc $OLDHOSTIP 11211 >> $VALUE
done <"$KEYDUMP"

#remove return carriage in value file
sed -i 's/\r$//g' $VALUE

#declare an arrry
declare -a PAIR

while read -r line
do
    #read value file, add elements in the array
        if [ "$line" != "END" ]
        then
                if [[ $line = "VALUE"* ]]
                then
                        #key
                        PAIR[0]=$(echo $line | awk '{ print $2 }')
                        #flag
                        PAIR[1]=$(echo $line | awk '{ print $3 }')
                        #TTL
                        PAIR[2]=900
                        #size in byte
                        PAIR[3]=$(echo $line | awk '{ STR=$4"\\r\\n"; print STR }')
                else
                        #values
                        LENGTH=${#PAIR[@]}
                        PAIR[$LENGTH]=$(echo -n "$line\r")
                fi
        else
        #create a memcached set command string
                SET="set "
                for ((i=0; i<${#PAIR[@]}; i++))
                do
                        if [ $i -lt 3 ]
                        then
                                SET="$SET${PAIR[$i]} "
                        else
            #values shouldn't have a whitespace at the end
                                SET="$SET${PAIR[$i]}"
                        fi
                done

                #run a memcached set command to add pairs
                echo -e "$SET" | nc localhost 11211

        #compare values in both servers
        echo ${PAIR[0]} $(diff <(echo "get ${PAIR[0]}" | nc localhost 11211) <(echo "get ${PAIR[0]}" | nc $OLDHOSTIP 11211)) >> $LOG

                #reset the command and the array
                SET=""
                unset PAIR
        fi
done <"$VALUE"

rm $KEYDUMP $VALUE
