#!/bin/bash

#Debian 
OLD_IP=`ifconfig | grep -o "inet addr:.* B" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
ATTEMPTS=0
MAX_ATTEMPTS=100
FINISHED=0

#Checks for connection to internet
#We use ping command here because we can test both DNS and connectivity with one command
function checkConnection {
         echo "Checking Connection"
        ping -w 1 google.com
        if [ $? -eq 0 ]; then
                echo "Connection OK" 
                return 0
        else
                echo "Connection Bad" 
                return 1
        fi
}

#Renews the IP via DHCP client
function renewIp {
        echo "Renewing IP"
                ifdown --all
                ifup --all
                checkConnection
                if [ $? -eq 0 ]; then
                        NEW_IP=`ifconfig | grep -o "inet addr:.* B" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
                        FINISHED=1
                        logger "Renew success, new IP = "$NEW_IP
                else
                        echo "Still no connection, retrying"
                        ATTEMPTS=$((ATTEMPTS+1))
                        FINISHED=0
                fi
}

logger "Starting network connection monitor"

#Main loop
while [ $FINISHED -ne 1 -a $ATTEMPTS -lt $MAX_ATTEMPTS ]
do
        checkConnection
        if [ $? -eq 0 ]; then
                logger "Conenction OK"
                ATTEMPTS=0
                FINISHED=1
        else
                logger "Renewing IP"
                renewIp
        fi
done

#Check is success
if [ $MAX_ATTEMPTS -eq $ATTEMPTS ]; then
        echo "Reached max attempts to renew IP, still no connection"
fi