#/bin/bash
# _                               
#| |_ _ _ ___ ___ ___ ___ ___ _ _ 
#|   | | | . | -_|  _|_ -|  _| | |
#|_|_|_  |  _|___|_| |___|_|  \_/ 
#    |___|_|                      
#
# hypersrv.com | Web at scale solutions
#
# update_cpanel_passwords.sh Stephen Martin <sm@hypersrv.com>
# ------------------------------------------
# Script to update cpanel passwords on mass
# Will update the account password and try its best to update the FTP and 
# mysql against the really bad documentation for the commands by CPanel
# It will create a file with the new passwords in
# Copyright (c) 2015, Stephen Martin <sm@hypersrv.com>
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
# DAMAGE

which pwgen >> update_cpanel_passwords.log 2>&1 || yum install pwgen -y >> update_cpanel_passwords.log 2>&1
export ALLOW_PASSWORD_CHANGE=1
for D in `find /home/ -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' | egrep -v '(virtfs|cPanelInstall|centos|ubuntu|ukfastsupport)'`
do
        THISUSER=$(basename $D)
        NEWPASS=$(pwgen -N 1 15)
        echo "[+] Working on $THISUSER" >> update_cpanel_passwords.log 2>&1
        echo $THISUSER $NEWPASS >> new_passwords.txt
        /scripts/realchpass $THISUSER $NEWPASS  >> update_cpanel_passwords.log 2>&1
        /scripts/mysqlpasswd $THISUSER $NEWPASS  >> update_cpanel_passwords.log 2>&1
done
/scripts/ftpupdate  >> update_cpanel_passwords.log 2>&1
