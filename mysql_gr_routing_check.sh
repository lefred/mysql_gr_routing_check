#!/bin/bash
#
# Script to make HAProxy capable of determining the routing candidate viability for MySQL Group Replication members
# version: 0.2
# Author: Matt Lord <matt.lord@oracle.com>
#         Frederic -lefred- Descamps <frederic.descamps@oracle.com>
# Based on the original script from Unai Rodriguez and later work by Olaf van Zandwijk and Raghavendra Prabhu
#
# version 0.1 - first release
# version 0.2 - add read & write check + queue length check

# mysql_gr_routing_check.sh <MAX_QUEUE> <READ|WRITE>

# This password method is insecure and should not be used in a production environment!
MYSQL_USERNAME="check"
MYSQL_PASSWORD="fred"
MYSQL_HOST=localhost
MYSQL_PORT=3306

MAXQUEUE=${1-100}
ROLE=${2-WRITE}

if ! [ "$MAXQUEUE" -eq "$MAXQUEUE" ] 2>/dev/null;
then
    # Member is not a vaiable routing candidate => return HTTP 503
    # Shell return-code is 1
    echo -en "HTTP/1.1 503 Service Unavailable\r\n"
    echo -en "Content-Type: text/plain\r\n"
    echo -en "Connection: close\r\n"
    echo -en "Content-Length: 44\r\n"
    echo -en "\r\n"
    echo -en "Group Replication member is not a viable routing candidate:\r\n"
    echo -en "maxqueue argument is not a valid value: ($MAXQUEUE).\r\n"
    exit 1
fi

echo $(mysql --no-defaults -BN --connect-timeout=10 --host=$MYSQL_HOST --port=$MYSQL_PORT --user="$MYSQL_USERNAME" --password="$MYSQL_PASSWORD" -e 'SELECT * FROM sys.gr_member_routing_candidate_status' 2>/dev/null) | while read candidate readonly queue
do

if [ "$candidate" == "YES" ]
then
   if [ "${ROLE^^}" == "READ" ]
   then
       if [ $queue -lt $MAXQUEUE ]
       then
	    # Member is a viable routing candidate => return HTTP 200
	    # Shell return-code is 0
	    echo -en "HTTP/1.1 200 OK\r\n"
	    echo -en "Content-Type: text/plain\r\n"
	    echo -en "Connection: close\r\n"
	    echo -en "Content-Length: 40\r\n"
	    echo -en "\r\n"
	    echo -en "Group Replication member is a viable routing candidate for $ROLE.\r\n"
	    exit 0
       else
	    # Member is not a vaiable routing candidate => return HTTP 503
	    # Shell return-code is 1
	    echo -en "HTTP/1.1 503 Service Unavailable\r\n"
	    echo -en "Content-Type: text/plain\r\n"
	    echo -en "Connection: close\r\n"
	    echo -en "Content-Length: 44\r\n"
	    echo -en "\r\n"
	    echo -en "Group Replication member is not a viable routing candidate:\r\n"
            echo -en "queue exceeds ($queue) threshold ($MAXQUEUE).\r\n"
    	    exit 1
       fi
   elif [ "${ROLE^^}" == "WRITE" ]
   then
       if [ "$readonly" == "YES" ]
       then
	    # Member is not a vaiable routing candidate => return HTTP 503
	    # Shell return-code is 1
	    echo -en "HTTP/1.1 503 Service Unavailable\r\n"
	    echo -en "Content-Type: text/plain\r\n"
	    echo -en "Connection: close\r\n"
	    echo -en "Content-Length: 44\r\n"
	    echo -en "\r\n"
	    echo -en "Group Replication member is not a viable routing candidate:\r\n"
            echo -en "$ROLE cannot be routed to a readonly member.\r\n"
    	    exit 1
       else
	       if [ $queue -lt $MAXQUEUE ]
	       then
		    # Member is a viable routing candidate => return HTTP 200
		    # Shell return-code is 0
		    echo -en "HTTP/1.1 200 OK\r\n"
		    echo -en "Content-Type: text/plain\r\n"
		    echo -en "Connection: close\r\n"
		    echo -en "Content-Length: 40\r\n"
		    echo -en "\r\n"
		    echo -en "Group Replication member is a viable routing candidate for $ROLE.\r\n"
		    exit 0
	       else
		    # Member is not a vaiable routing candidate => return HTTP 503
		    # Shell return-code is 1
		    echo -en "HTTP/1.1 503 Service Unavailable\r\n"
		    echo -en "Content-Type: text/plain\r\n"
		    echo -en "Connection: close\r\n"
		    echo -en "Content-Length: 44\r\n"
		    echo -en "\r\n"
		    echo -en "Group Replication member is not a viable routing candidate:\r\n"
		    echo -en "queue exceeds ($queue) threshold ($MAXQUEUE).\r\n"
		    exit 1
	       fi
       fi
   else
       # Member is not a vaiable routing candidate => return HTTP 503
       # Shell return-code is 1
       echo -en "HTTP/1.1 503 Service Unavailable\r\n"
       echo -en "Content-Type: text/plain\r\n"
       echo -en "Connection: close\r\n"
       echo -en "Content-Length: 44\r\n"
       echo -en "\r\n"
       echo -en "Group Replication member is not a viable routing candidate:\r\n"
       echo -en "$ROLE is not a valid argument.\r\n"
       exit 1
   fi
fi

done
