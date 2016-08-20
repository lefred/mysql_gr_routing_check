# mysql_gr_routing_check
MySQL Group Replication Routing/Heath Check script

This script can be used with HA Proxy for example.

You need to call it via xinetd, this is an example::

    # default: on
    # description: check to see if the node is a viable routing candidate
    service mysql_gr_routing_check_write
    {
        disable = no
        flags = REUSE
        socket_type = stream
        port = 6446
        wait = no
        user = mysql
        server = /usr/local/bin/mysql_gr_routing_check.sh
        server_args = 100 write
        log_on_failure += USERID
        only_from = localhost 192.168.90.0/24
        per_source = UNLIMITED
    }

The script can take two optional arguments: 

- amount of max transactions in queue to be processed by the Group Member (trx behind), default is 100
- the role, READ or WRITE, default is WRITE

Usage example::

    [root@mysql1 bin]# telnet 192.168.90.2 6446
    Trying 192.168.90.2...
    Connected to 192.168.90.2.
    Escape character is '^]'.
    HTTP/1.1 200 OK
    Content-Type: text/plain
    Connection: close
    Content-Length: 40

    Group Replication member is a viable routing candidate for write.
    Connection closed by foreign host.


    [root@mysql1 bin]# telnet 192.168.90.2 6447
    Trying 192.168.90.2...
    Connected to 192.168.90.2.
    Escape character is '^]'.
    HTTP/1.1 200 OK
    Content-Type: text/plain
    Connection: close
    Content-Length: 40

    Group Replication member is a viable routing candidate for read.
    Connection closed by foreign host.


