#!/bin/sh

# change /etc/keystone/keystone.conf --> connection = mysql+pymysql://keystone:Gramlabs123@mariadb-keystone/keystone
source /root/admin-openrc

# start httpd
/usr/sbin/httpd -k start

# Configuration for keystone
chmod 755 /root/admin-openrc
source /root/admin-openrc

# Keystone sync with database mariadb
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-password Gramlabs123 --bootstrap-admin-url http://localhost:35357/v3/ --bootstrap-internal-url http://localhost:5000/v3/ --bootstrap-public-url http://localhost:5000/v3/ --bootstrap-region-id RegionOne
ln -sf /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/wsgi-keystone.conf
source /root/admin-openrc

# Configuration for Openstack
openstack project create --domain default --description "Service Project" service
openstack role create user
unset OS_AUTH_URL OS_PASSWORD
source /root/admin-openrc

openstack token issue
openstack --os-password Gramlabs123 --os-auth-url http://localhost:35357/v3 --os-project-domain-name default --os-user-domain-name default --os-project-name admin --os-username admin token issue

openstack user create --domain default --password Gramlabs123 swift
openstack role add --project service --user swift admin
openstack service create --name swift --description "OpenStack Object Storage" object-store
openstack endpoint create --region RegionOne object-store public http://localhost:8080/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region RegionOne object-store internal http://localhost:8080/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region RegionOne object-store admin http://localhost:8080/v1

source /root/admin-openrc

bash

# Create the Rings for SWIFT
mkdir -p /var/cache/swift
chown -R root:swift /var/cache/swift
chmod -R 775 /var/cache/swift
mkdir -p /srv/node/objstore
chown -R swift:swift /srv/node/objstore

cd /etc/swift
swift-ring-builder account.builder create 10 1 1
swift-ring-builder account.builder add --region 1 --zone 1 --ip localhost --port 6202 --device objstore --weight 1
swift-ring-builder account.builder
swift-ring-builder account.builder rebalance
swift-ring-builder container.builder create 10 1 1
swift-ring-builder container.builder add --region 1 --zone 1 --ip localhost --port 6201 --device objstore --weight 1
swift-ring-builder container.builder
swift-ring-builder container.builder rebalance
swift-ring-builder object.builder create 10 1 1
swift-ring-builder object.builder add --region 1 --zone 1 --ip localhost --port 6200 --device objstore --weight 1
swift-ring-builder object.builder
swift-ring-builder object.builder rebalance
chown -R root:swift /etc/swift
chown -R root:root /etc/swift/account.builder /etc/swift/container.builder /etc/swift/object.builder
chown -R root:root /etc/swift/account.ring.gz /etc/swift/container.ring.gz /etc/swift/object.ring.gz

swift-init main start
#/usr/bin/swift-proxy-server /etc/swift/proxy-server.conf

# Create s3test project and testuser1 & testuser2 for Testing with s3curl
openstack project create s3test
openstack user create --project s3test --password Passw0rd testuser1
openstack credential create --type ec2 --project s3test testuser1 '{"access":"testuser1","secret":"Passw0rd"}'
openstack user create --project s3test --password Passw0rd testuser2
openstack credential create --type ec2 --project s3test testuser2 '{"access":"testuser2","secret":"Passw0rd"}'
# Create a role and use that role to give the user access to the account:
openstack role add --project s3test --user testuser1 user
openstack role add --project s3test --user testuser2 user

bash
##################################
# Get s3curl and install the requird packets for perl using cpan
#cd /root
#git clone https://github.com/rtdp/s3curl
#yum install -y cpan
#cpan Digest::HMAC_SHA1
#yum install -y perl-Digest-HMAC
#yum install -y perl-Digest-HMAC_SHA1

