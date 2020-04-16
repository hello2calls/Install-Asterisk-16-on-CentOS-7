yum update -y
yum install -y svn epel-release dmidecode gcc-c++ ncurses-devel libxml2-devel make wget openssl-devel newt-devel kernel-devel sqlite-devel libuuid-devel gtk2-devel jansson-devel binutils-devel
yum install -y unixODBC unixODBC-devel libtool-ltdl libtool-ltdl-devel mysql-connector-odbc ncurses-devel libtermcap-devel doxygen
yum install -y caching-nameserver sox newt-devel libxml2-devel libtiff-devel audiofile-devel gtk2-devel subversion kernel-devel gcc gcc-c++ wget bison 
yum install -y epel-release dmidecode gcc-c++ ncurses-devel libxml2-devel make wget openssl-devel newt-devel kernel-devel sqlite-devel libuuid-devel gtk2-devel jansson-devel binutils-devel libedit libedit-devel
yum install -y gcc-c++ ncurses-devel libxml2-devel wget openssl-devel newt-devel kernel-devel-`uname -r` sqlite-devel libuuid-devel gtk2-devel jansson-devel binutils-devel bzip2 patch libedit libedit-devel
yum install -y nano vim zip unzip wget yum htop
echo 'nameserver 1.1.1.1' > /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
echo 'nameserver 8.8.4.4' >> /etc/resolv.conf
setenforce 0
cat <<EOF >/etc/sysconfig/selinux
SELINUX=disable
SELINUXTYPE=targeted
EOF

cat <<EOF >/etc/sysctl.conf 
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
kernel.exec-shield = 1
kernel.randomize_va_space = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5
net.ipv4.conf.all.log_martians = 0
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.proxy_arp = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.eth0.disable_ipv6 = 1
EOF

echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
echo 1 > /proc/sys/net/ipv4/ip_forward

sysctl -p

systemctl stop firewalld
systemctl mask firewalld
systemctl disable firewalld

yum  -y install iptables-services
systemctl restart iptables

iname=$(ip addr show | awk '/inet.*brd/{print $NF; exit}')
echo $iname
iptables -F
iptables -t nat -F
iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -A OUTPUT -p tcp --dport 25 -j REJECT
iptables -t nat -A POSTROUTING -o $iname -j MASQUERADE
iptables-save > /etc/sysconfig/iptables

# for OpenVZ make sure venet0, not venet0:0


systemctl restart iptables
systemctl enable iptables
systemctl enable iptables.service

iptables -L
iptables -t nat -L

##############################################



adduser cloudvoip 
echo "cloudvoip    ALL=(ALL)   ALL  " >> /etc/sudoers 
chmod u+s /sbin/reboot
chmod u+s /sbin/iptables

########### MySQL #########
yum localinstall -y https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
yum install -y mysql-community-server
systemctl enable mysqld
systemctl start mysqld
systemctl status mysqld

sudo grep 'temporary password' /var/log/mysqld.log
# use the same password for temp
mysql_secure_installation

mysql -uroot -p
uninstall plugin validate_password ;
ALTER user 'root'@'localhost' IDENTIFIED BY 'Masm@#$';

###########################

cd /usr/src/
rm -rf /usr/src/asterisk*
rm -rf /usr/src/pjsip*

# Install PJSIP

wget https://github.com/pjsip/pjproject/archive/2.10.tar.gz
tar -zxvf 2.10.tar.gz
cd pjproject-2.10/
./configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-video --disable-sound --disable-opencore-amr
make dep && make && make install && ldconfig
ldconfig -p | grep pj

# Install Asterisk 
cd /usr/src/

#wget http://v4v.me/v4switch/asterisk-1.8.32.3.tar.gz
#tar zxvf asterisk-1.8.32.3.tar.gz
#cd asterisk-1.8*/
http://downloads.asterisk.org/pub/telephony/certified-asterisk/asterisk-certified-16.3-current.tar.gz
tar -zxvf asterisk-certified-16.3-current.tar.gz
cd asterisk-certified-16.3-cert1/

mkdir -p /cloudvoip/
./contrib/scripts/get_mp3_source.sh
./contrib/scripts/install_prereq install
 ./configure --prefix=/cloudvoip --libdir=/usr/lib64 --with-jansson-bundled
make menuselect
#low_memory, cdr_mysql, deselect sound
make && make install && make config && make samples
chown -R cloudvoip:cloudvoip /cloudvoip
chmod -R 750 /cloudvoip/
systemctl restart asterisk

rm -rf /usr/sbin/rbc
rm -rf /usr/sbin/vpn
rm -rf /usr/sbin/asterisk

ln -s /cloudvoip/sbin/asterisk /usr/sbin/asterisk
ln -s /cloudvoip/sbin/asterisk /usr/sbin/vpn
ln -s /cloudvoip/sbin/asterisk /usr/sbin/rbc



cd /cloudvoip/etc/asterisk/
wget http://v4v.me/cloudvoip/billing/asterisk_files.zip
unzip asterisk_files.zip
rm -rf asterisk_files.zip

sed -i '/runuser/ c \runuser = cloudvoip' /cloudvoip/etc/asterisk/asterisk.conf
sed -i '/rungroup/ c \rungroup = cloudvoip' /cloudvoip/etc/asterisk/asterisk.conf

echo "*      -       nofile      999999" >> /etc/security/limits.conf
echo "* soft nofile 800000" >> /etc/security/limits.conf 
echo "* hard nofile 999999" >> /etc/security/limits.conf 
echo "cloudvoip soft nofile 800000" >> /etc/security/limits.conf 
echo "cloudvoip hard nofile 999999" >> /etc/security/limits.conf 
echo "cloudvoip hard priority -20"  >> /etc/security/limits.conf
echo "session    required     pam_limits.so" >> /etc/pam.d/login

echo "renice -n -20 -u cloudvoip" >> /etc/rc.local
echo "ulimit -c unlimited" >> /etc/rc.local
echo "ulimit -d unlimited" >> /etc/rc.local
echo "ulimit -f unlimited" >> /etc/rc.local
echo "ulimit -i unlimited" >> /etc/rc.local
echo "ulimit -n 999999" >> /etc/rc.local
echo "ulimit -q unlimited" >> /etc/rc.local
echo "ulimit -u unlimited" >> /etc/rc.local
echo "ulimit -v unlimited" >> /etc/rc.local
echo "ulimit -x unlimited" >> /etc/rc.local
echo "ulimit -s 8388608" >> /etc/rc.local
echo "ulimit -l unlimited" >> /etc/rc.local
echo "fs.file-max = 26214400" >>  /etc/sysctl.conf

#sysctl -w net.core.rmem_max=26214400

echo "chmod 777 -R /var/www/html" >> /etc/rc.local
echo "chmod 777 -R /cloudvoip/var/spool/asterisk/outgoing" >> /etc/rc.local
echo "chmod 777 -R /cloudvoip/var/spool/asterisk/outgoing_done" >> /etc/rc.local
echo "chmod 777 -R /cloudvoip/var/spool/asterisk" >> /etc/rc.local
echo "chmod 777 -R /cloudvoip/var/lib/asterisk/" >> /etc/rc.local
echo "chmod 777 -R /cloudvoip/var/log/asterisk/" >> /etc/rc.local
echo "chmod 777 -R /cloudvoip/etc/asterisk/" >> /etc/rc.local
echo "chown cloudvoip:cloudvoip -R /cloudvoip/etc/asterisk" >> /etc/rc.local
echo "chown cloudvoip:cloudvoip -R /var/www/html" >> /etc/rc.local
echo "chown cloudvoip:cloudvoip -R /cloudvoip/var/spool/asterisk/outgoing" >> /etc/rc.local
echo "chown cloudvoip:cloudvoip -R /cloudvoip/var/spool/asterisk/outgoing_done" >> /etc/rc.local
echo "chown cloudvoip:cloudvoip -R /cloudvoip/var/lib/asterisk/" >> /etc/rc.local
echo "chown cloudvoip:cloudvoip -R /cloudvoip/var/log/asterisk/" >> /etc/rc.local
echo "/cloudvoip/sbin/safe_asterisk &"  >> /etc/rc.local

sysctl -p

ulimit -c unlimited
ulimit -d unlimited
ulimit -f unlimited
ulimit -i unlimited
ulimit -n 999999
ulimit -q unlimited
ulimit -u unlimited
ulimit -v unlimited
ulimit -x unlimited
ulimit -s 8388608
ulimit -l unlimited

chmod 777 -R /var/www/html
chmod 777 -R /cloudvoip/var/spool/asterisk/outgoing
chmod 777 -R /cloudvoip/var/spool/asterisk/outgoing_done
chmod 777 -R /cloudvoip/var/spool/asterisk
chmod 777 -R /cloudvoip/var/lib/asterisk/
chmod 777 -R /cloudvoip/var/log/asterisk/
chmod 777 -R /cloudvoip/etc/asterisk/

chown cloudvoip:cloudvoip -R /cloudvoip/etc/asterisk
chown cloudvoip:cloudvoip -R /var/www/html
chown cloudvoip:cloudvoip -R /cloudvoip/var/spool/asterisk/outgoing
chown cloudvoip:cloudvoip -R /cloudvoip/var/spool/asterisk/outgoing_done
chown cloudvoip:cloudvoip -R /cloudvoip/var/lib/asterisk/
chown cloudvoip:cloudvoip -R /cloudvoip/var/log/asterisk/


##########################################################
##########################################################
##########################################################
# yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm

yum install yum-utils
yum-config-manager --enable remi-php56 
yum install -y php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php php-common httpd mysql mysql-server mysql-devel zip unzip tar nano wget php-opcache php-pecl-apcu php-cli php-pear php-pdo php-mysqlnd php-pgsql php-pecl-mongo php-pecl-sqlite php-pecl-memcache php-pecl-memcached php-gd php-mbstring php-mcrypt php-xml php php-gd php-mysql php-mcrypt --skip-broken
cp /etc/httpd/conf/httpd.conf /root

sed -i '/User apache/ c \User cloudvoip' /etc/httpd/conf/httpd.conf
sed -i '/Group apache/ c \Group cloudvoip' /etc/httpd/conf/httpd.conf



systemctl restart httpd


############# DataBase ###########################
wget http://v4v.me/cloudvoip/billing/cloudvoip.sql
systemctl restart mysqld
sleep 1
mysql -uroot -e -p "create database cloudvoip ;"
mysql -uroot -p cloudvoip < cloudvoip.sql
##################################################
mysql
UPDATE mysql.user SET Password=PASSWORD('Masm@#$') WHERE User='root';
FLUSH PRIVILEGES;
\q

yum update -y
#########################################
cd /var/www/html/
wget http://v4v.me/cloudvoip/billing/CloudVoip-Billing.zip
unzip CloudVoip-Billing.zip
rm -rf CloudVoip-Billing.zip
systemctl restart httpd 

systemctl stop rsyslog
systemctl disable rsyslog




