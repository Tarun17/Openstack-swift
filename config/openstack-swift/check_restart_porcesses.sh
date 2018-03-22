#!/bin/bash

# Define array of processes to be checked;
check_swift_process=( "container-updater" "account-auditor" "object-replicator" "container-sync" "container-replicator" "object-auditor" "object-expirer" "container-auditor" "container-server" "object-reconstructor" "object-server" "account-reaper" "proxy-server" "account-replicator" "object-updater" "container-reconciler" "account-server" )
check_rsync_process=( "rsync" )
check_apache_process=( "httpd" )

while sleep 35; do  # Endless loop;

# check if swift processes are started and if not starting them;
   for p in "${check_swift_process[@]}"; do
       if swift-init status "$p" > /dev/null; then
         echo "Process \`$p' is running"
       else
         echo "Process \`$p' is not running"
         swift-init start all
       fi
   sleep 1
   done

# check if rsync process is started and if not starting it;
   for p in "${check_rsync_process[@]}"; do
       if pgrep "$p" > /dev/null; then
         echo "Process \`$p' is running"
       else
         echo "Process \`$p' is not running"
         rm -rf /var/run/rsyncd.pid
         /usr/bin/rsync --daemon
       fi
   sleep 1
   done

# check if Apache process is started and if not starting it;
   for p in "${check_apache_process[@]}"; do
       if pgrep "$p" > /dev/null; then
         echo "Process \`$p' is running"
       else
         echo "Process \`$p' is not running"
         /usr/sbin/httpd -k start
       fi
   sleep 1
   done
done
