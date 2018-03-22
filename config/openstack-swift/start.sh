#!/bin/bash
debug=false
file="/tmp/checkfile"
function run_command {
    text=$1" - "
    shift
    command=$@
    echo
    $command > /tmp/run.log 2>&1
    rc=$?

    if [ $rc == 0 ]; then
        if [ $debug == true ]; then
            echo "Running command : $command"
            if [ -s /tmp/run.log ]; then echo $(cat /tmp/run.log); fi
        fi
        echo $text"PASSED"
    else
        echo "Running command : $command"
        if [ -s /tmp/run.log ]; then echo $(cat /tmp/run.log); fi
        echo $text"FAILED"
    fi
}

if [ ! -f $file ]; then 

    run_command "Starting Apache server" /usr/sbin/httpd -k start
    run_command "Configuring the Keystone environment variables" chmod 755 /root/admin-openrc
    run_command "Setting up the Keystone environment variables" source /root/admin-openrc
    echo -e "\nPopulate the Identity service database" ; /bin/sh -c "keystone-manage db_sync" keystone
    #run_command "Populate the Identity service database" /bin/sh -c \"/usr/bin/keystone-manage db_sync\" keystone
    run_command "Initialize Fernet key repositories" keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
    run_command "Initialize Fernet key repositories" keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
    run_command "Bootstrap the Identity service" keystone-manage bootstrap --bootstrap-password Password123 --bootstrap-admin-url http://localhost:35357/v3/ --bootstrap-internal-url http://localhost:5000/v3/ --bootstrap-public-url http://localhost:5000/v3/ --bootstrap-region-id RegionOne
    run_command "Create a link to the /usr/share/keystone/wsgi-keystone.conf file" ln -sf /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/wsgi-keystone.conf
    
    run_command "Create the service project" openstack project create --domain default --description ServiceProject service
    run_command "Create the user role" openstack role create user
    run_command "Unset the temporary OS_AUTH_URL and OS_PASSWORD environment variable" unset OS_AUTH_URL OS_PASSWORD
    run_command "Setting up the Keystone environment variables" source /root/admin-openrc
    run_command "Request an authentication token" openstack token issue
    run_command "As the admin user, request an authentication token" openstack --os-password Password123 --os-auth-url http://localhost:35357/v3 --os-project-domain-name default --os-user-domain-name default --os-project-name admin --os-username admin token issue
    run_command "Create the service credentials for the user swift" openstack user create --domain default --password Password123 swift
    run_command "Add the admin role to the swift user and service project" openstack role add --project service --user swift admin
    run_command "Create the swift service entity" openstack service create --name swift --description OpenStackObjectStorage object-store
    run_command "Create the Object Store service API endpoints Public" openstack endpoint create --region RegionOne object-store public http://localhost:8080/v1/AUTH_\%\(tenant_id\)s
    run_command "Create the Object Store service API endpoints Internal" openstack endpoint create --region RegionOne object-store internal http://localhost:8080/v1/AUTH_\%\(tenant_id\)s
    run_command "Create the Object Store service API endpoints Admin" openstack endpoint create --region RegionOne object-store admin http://localhost:8080/v1
    run_command "Setting up the Keystone environment variables" source /root/admin-openrc
    
    run_command "Pre-configuration for Swift" mkdir -p /var/cache/swift
    run_command "Pre-configuration for Swift" chown -R root:swift /var/cache/swift
    run_command "Pre-configuration for Swift" chmod -R 775 /var/cache/swift
    run_command "Pre-configuration for Swift" mkdir -p /srv/node/objstore
    run_command "Pre-configuration for Swift" chown -R swift:swift /srv/node/objstore
#################################    
#    run_command "Change to Swift directory" cd /etc/swift
#    run_command "Create the base account.builder file" swift-ring-builder account.builder create 10 1 1
#    run_command "Create the base container.builder file" swift-ring-builder container.builder create 10 1 1
#    run_command "Create the base object.builder file" swift-ring-builder object.builder create 10 1 1

#    run_command "Add each storage node to the ring: Account" swift-ring-builder account.builder add --region 1 --zone 1 --ip localhost --port 6202 --device objstore --weight 1
#    run_command "Add each storage node to the ring: Container" swift-ring-builder container.builder add --region 1 --zone 1 --ip localhost --port 6201 --device objstore --weight 1
#    run_command "Add each storage node to the ring: Object" swift-ring-builder object.builder add --region 1 --zone 1 --ip localhost --port 6200 --device objstore --weight 1
#################################
    run_command "Change to Swift directory" cd /etc/swift
    run_command "Create the base account.builder file" swift-ring-builder account.builder create 10 3 1
    run_command "Create the base container.builder file" swift-ring-builder container.builder create 10 3 1
    run_command "Create the base object.builder file" swift-ring-builder object.builder create 10 3 1

    run_command "Add each storage node to the ring: Account" swift-ring-builder account.builder add --region 1 --zone 1 --ip localhost --port 6202 --device objstore --weight 1
    run_command "Add each storage node to the ring: Container" swift-ring-builder container.builder add --region 1 --zone 1 --ip localhost --port 6201 --device objstore --weight 1
    run_command "Add each storage node to the ring: Object" swift-ring-builder object.builder add --region 1 --zone 1 --ip localhost --port 6200 --device objstore --weight 1
    run_command "Add each storage node to the ring: Account" swift-ring-builder account.builder add --region 1 --zone 1 --ip 172.16.33.179 --port 6202 --device objstore --weight 1
    run_command "Add each storage node to the ring: Container" swift-ring-builder container.builder add --region 1 --zone 1 --ip 172.16.33.179 --port 6201 --device objstore --weight 1
    run_command "Add each storage node to the ring: Object" swift-ring-builder object.builder add --region 1 --zone 1 --ip 172.16.33.179 --port 6200 --device objstore --weight 1
    run_command "Add each storage node to the ring: Account" swift-ring-builder account.builder add --region 1 --zone 1 --ip 172.16.33.180 --port 6202 --device objstore --weight 1
    run_command "Add each storage node to the ring: Container" swift-ring-builder container.builder add --region 1 --zone 1 --ip 172.16.33.180 --port 6201 --device objstore --weight 1
    run_command "Add each storage node to the ring: Object" swift-ring-builder object.builder add --region 1 --zone 1 --ip 172.16.33.180 --port 6200 --device objstore --weight 1
###################################     
    run_command "Verify the ring contents" swift-ring-builder account.builder
    run_command "Verify the ring contents" swift-ring-builder container.builder
    run_command "Verify the ring contents" swift-ring-builder object.builder
    
    run_command "Rebalance the ring" swift-ring-builder account.builder rebalance
    run_command "Rebalance the ring" swift-ring-builder container.builder rebalance
    run_command "Rebalance the ring" swift-ring-builder object.builder rebalance
    
    run_command "Post-configuration for Swift" chown -R root:swift /etc/swift
    run_command "Post-configuration for Swift" chown -R root:root /etc/swift/account.builder /etc/swift/container.builder /etc/swift/object.builder
    run_command "Post-configuration for Swift" chown -R root:root /etc/swift/account.ring.gz /etc/swift/container.ring.gz /etc/swift/object.ring.gz
    run_command "Starting Swift" swift-init all start
    
    run_command "Create the s3test project" openstack project create s3test
    run_command "Create the s3test credentials for the user testuser1" openstack user create --project s3test --password Passw0rd testuser1
    echo -e "\nCreate credentials for the user testuser1" ; openstack credential create --type ec2 --project s3test testuser1 '{"access":"testuser1","secret":"Passw0rd"}'
    #run_command "Create credentials for the user testuser1" openstack credential create --type ec2 --project s3test testuser1 \'\{\"access\":\"testuser1\",\"secret\":\"Passw0rd\"\}\'
    run_command "Create the s3test credentials for the user testuser1" openstack user create --project s3test --password Passw0rd testuser2
    echo -e "\nCreate credentials for the user testuser2" ; openstack credential create --type ec2 --project s3test testuser2 '{"access":"testuser2","secret":"Passw0rd"}'
    #run_command "Create credentials for the user testuser2" openstack credential create --type ec2 --project s3test testuser2 \'\{\"access\":\"testuser2\",\"secret\":\"Passw0rd\"\}\'
    run_command "Add the user role to the testuser1 user" openstack role add --project s3test --user testuser1 user
    run_command "Add the user role to the testuser2 user" openstack role add --project s3test --user testuser2 user
    
    run_command "Creating file to check the run of the script" touch /tmp/checkfile

else
    run_command "Starting Apache server" /usr/sbin/httpd -k start
    run_command "Starting Swift" swift-init all start  

fi

/usr/bin/rsync --daemon
./tmp/check_restart_porcesses.sh
/usr/sbin/sshd &
