#!/bin/bash
# _                               
#| |_ _ _ ___ ___ ___ ___ ___ _ _ 
#|   | | | . | -_|  _|_ -|  _| | |
#|_|_|_  |  _|___|_| |___|_|  \_/ 
#    |___|_|                      
#
# hypersrv.com | Web at scale solutions
#
# backup_mongodb.sh Stephen Martin <sm@hypersrv.com>
# ------------------------------------------
# Script to backup mongodb and prune old backups
# 
# Copyright (c) 2018, Stephen Martin <sm@hypersrv.com>
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


MONGODUMP=/usr/bin/mongodump
MONGODUMPLOC=/home/ubuntu/dump/
MONGODUMPSLOC=/home/ubuntu/dumps/
KEEP=5
if [ ! -f $MONGODUMPSLOC ]; then
	mkdir -p $MONGODUMPSLOC
fi

if [ ! -f $MONGODUMPLOC ]; then
	mkdir -p $MONGODUMPLOC
fi

function cleanup {
if [ -d $MONGODUMPLOC ]; then
	echo "Cleaning $MONGODUMPLOC"
	rm -rf $MONGODUMPLOC/*
	rm -rf $MONGODUMPLOC/.*
else
	echo "Dump dir does not exist yet"
fi
}

#do some clean up
cleanup
echo "Dumping"
$MONGODUMP
DUMPRES=$?

if [ $DUMPRES -gt 0 ]; then
	echo "Error with dumping code was $DUMPRES, exiting"
	exit 1
	echo "Return code was $DUMPRES"
fi

tar czf $MONGODUMPSLOC/dump_$(date +"%Y_%m_%d_%I_%M_%p").tar.gz $MONGODUMPLOC
LATESTDUMP=$(ls -1t $MONGODUMPSLOC/dump_*.tar.gz | head -n 1)
echo $LATESTDUMP
rm $MONGODUMPSLOC/latest.tar.gz
ln -s $LATESTDUMP $MONGODUMPSLOC/latest.tar.gz

cleanup

if [ -d $MONGODUMPSDIR ];then
	echo "pruning"
	DUMPCOUNT=$(ls -1 $MONGODUMPSLOC/dump_*.tar.gz | wc -l)
	if [ $DUMPCOUNT -gt $KEEP ];then
		echo "[+] Over dump retention policy - Policy: $KEEP Dump Count: $DUMPCOUNT"
	 	DELETEDUMPS=$(ls -1t dumps/dump_*.tar.gz | tail -n $(($DUMPCOUNT - $KEEP)))
		for DUMP in $DELETEDUMPS
		do
			echo "[+] Delete $DUMP"
			rm $DUMP
		done
	else
		echo "[+] Under archive retention policy - Policy: $KEEP Archive Count: $DUMPCOUNT"
	fi
fi


