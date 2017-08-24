#!/bin/bash
 
# changes the permissions to user-readable only
ACCOUNTS=$(ls /home/*/public_html -d | awk -F/ '{print $3}')
 
for ACCOUNT in $ACCOUNTS; do
    find /home/$ACCOUNT/public_html -name \*\.php | xargs -I file chmod -v 600 file
    find /home/$ACCOUNT/public_html -type d | xargs -I file chmod -v 755 file
    chmod -v 750 /home/$ACCOUNT/public_html
done
