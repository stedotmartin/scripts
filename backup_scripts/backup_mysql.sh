#!/bin/bash
# _                               
#| |_ _ _ ___ ___ ___ ___ ___ _ _ 
#|   | | | . | -_|  _|_ -|  _| | |
#|_|_|_  |  _|___|_| |___|_|  \_/ 
#    |___|_|                      
#
# hypersrv.com | Web at scale solutions
#
# export_db.sh Stephen Martin <sm@hypersrv.com>
# ------------------------------------------
# Script to backup all database to individual files
# 
# Copyright (c) 2016, Stephen Martin <sm@hypersrv.com>
# All rights reserved.

# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:

#  * Redistributions of source code must retain the above copyright notice, 
#    this list of conditions and the following disclaimer. 
#  * Redistributions in binary form must reproduce the above copyright 
#    notice, this list of conditions and the following disclaimer in the 
#    documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY 
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY 
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
# DAMAGE.

# Testing 
# docker run --name test-mysql -e MYSQL_DATABASE=mydb MYSQL_ROOT_PASSWORD=password -d mysql:latest
# docker run -name test-ubu -v /home/stm/Code/scripts/backup_scripts/backups:/home/ubuntu/backups/ -v /home/stm/Code/scripts/backup_scripts/backup_mysql.sh:/home/ubuntu/backup_mysql.sh --link test-mysql:mysql ubuntu:latest sh -c 'chmod +x /home/ubuntu/backup_mysql.sh;apt-get update && apt-get install mysql-client -y;/home/ubuntu/backup_mysql.sh mysql root password /home/ubuntu/backups 10'
# docker start test-ubu -a


# USAGE backup_mysql.sh host user password backup_home retention_count'
# backup_mysql.sh 192.168.0.1 root password /home/ubuntu/backups 10'

MYSQL_HOST=$1
MYSQL_USER=$2
MYSQL_PASS=$3
BACKUP_HOME=$4
KEEP=$5
BACKUP_TIME=$(date +%Y-%m-%dT%H_%M_%S)
DUMPLOC=$BACKUP_HOME/dump/
DUMPSLOC=$BACKUP_HOME/dumps/

if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

which mysqlldump > /dev/null 2>&1
RET=$?
if [ ! $RET -eq 0 ];then
	echo "[!] FATAL error no mysqldump"
	exit 1
fi

which mysql > /dev/null 2>&1
RET=$?
if [ ! $RET -eq 0 ];then
	echo "[!] FATAL error no mysql"
	exit 1
fi

function cleanup {
if [ -d $DUMPLOC ]; then
	echo "Cleaning $DUMPLOC"
	rm -rf $DUMPLOC/*
else
	echo "Dump dir does not exist yet"
fi
}

mygrants()
{
  mysql --ssl-mode DISABLED --host $MYSQL_HOST -B -N $@ -e "SELECT DISTINCT CONCAT(
    'SHOW GRANTS FOR \'', user, '\'@\'', host, '\';'
    ) AS query FROM mysql.user WHERE user NOT IN ('phpmyadmin','debian-sys-maint')"  | \
  mysql --ssl-mode DISABLED --host $MYSQL_HOST $@ | \
  sed 's/\(GRANT .*\)/\1;/;s/^\(Grants for .*\)/## \1 ##/;/##/{x;p;x;}'
}

#do some clean up
cleanup

if [ ! -f $DUMPSLOC ]; then
	mkdir -p $DUMPSLOC
fi

if [ ! -f $DUMPLOC ]; then
	mkdir -p $DUMPLOC
fi

export MYSQL_PWD=$MYSQL_PASS
# Get the database list, exclude information_schema
for db in $(mysql --ssl-mode DISABLED --host $MYSQL_HOST -B -s -u $MYSQL_USER  -e 'show databases' | grep -v information_schema)
do
  # dump each database in a separate file
  echo "Working on: $db.."
  mysqldump --ssl-mode DISABLED --host $MYSQL_HOST -u $MYSQL_USER  --add-drop-database --databases "$db" > $DUMPLOC/$MYSQL_HOST-$db.sql
done
# Export the privileges
echo "Exporting privileges.."
mygrants --user=$MYSQL_USER  > "$DUMPLOC/$MYSQL_HOST-privileges-$BACKUP_TIME.sql"
echo "Archiving"
tar czf $DUMPSLOC/dump_$(date +"%Y_%m_%d_%I_%M_%p").tar.gz $DUMPLOC
LATESTDUMP=$(ls -1t $DUMPSLOC/dump_*.tar.gz | head -n 1)
rm $DUMPSLOC/latest.tar.gz
ln -s $LATESTDUMP $DUMPSLOC/latest.tar.gz
unset MYSQL_PWD
cleanup

if [ -d $DUMPSDIR ];then
	echo "pruning"
	DUMPCOUNT=$(ls -1 $DUMPSLOC/dump_*.tar.gz | wc -l)
	if [ $DUMPCOUNT -gt $KEEP ];then
		echo "[+] Over dump retention policy - Policy: $KEEP Dump Count: $DUMPCOUNT"
	 	DELETEDUMPS=$(ls -1t $DUMPSLOC/dump_*.tar.gz | tail -n $(($DUMPCOUNT - $KEEP)))
		for DUMP in $DELETEDUMPS
		do
			echo "[+] Delete $DUMP"
			rm $DUMP
		done
	else
		echo "[+] Under archive retention policy - Policy: $KEEP Archive Count: $DUMPCOUNT"
	fi
fi
