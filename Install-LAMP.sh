yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install mariadb-server mariadb -y

yum install httpd yum-utils epel-release
systemctl restart httpd.service
systemctl start mariadb
systemctl enable mariadb.service
mysql_secure_installation

yum install php php-mysql -y
yum -y install centos-release-scl.noarch

systemctl restart httpd
yum-config-manager --enable remi-php73
yum install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo
yum install php php-common php-opcache php-mcrypt php-cli php-gd php-curl php-mysqlnd

systemctl restart httpd
