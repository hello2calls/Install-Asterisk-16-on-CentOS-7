#!/bin/sh
yum -y update
hostnamectl set-hostname lite.v4switch.com
yum  -y install epel-release zip unzip nano wget curl vim net-tools patch
setenforce 0
cat <<EOF >/etc/selinux/config
SELINUX=disabled
SELINUXTYPE=targeted
EOF

#yum -y groupinstall "Development Tools"
yum -y install libedit-devel sqlite-devel psmisc gmime-devel ncurses-devel libtermcap-devel sox newt-devel libxml2-devel libtiff-devel audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel subversion kernel-devel kernel-devel-$(uname -r) git subversion kernel-devel crontabs cronie cronie-anacron
yum install -y dmidecode gcc-c++ ncurses-devel libxml2-devel make wget openssl-devel newt-devel kernel-devel sqlite-devel libuuid-devel gtk2-devel jansson-devel binutils-devel libedit libedit-devel
 
# Install jansson
cd /usr/src/
git clone https://github.com/akheron/jansson.git
cd jansson
autoreconf  -i
./configure --prefix=/usr/
make && make install
####################

# Install PJSIP
cd /usr/src/
wget https://www.pjsip.org/release/2.9/pjproject-2.9.zip
unzip pjproject-2.9.zip
cd pjproject-2.9
chmod 777 *
./configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-video --disable-sound --disable-opencore-amr
make dep
make 
make install
ldconfig
ldconfig -p | grep pj

##############################


# Install Asterisk
cd /usr/src/
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz
tar -zxvf asterisk-16-current.tar.gz
cd asterisk-16*
./contrib/scripts/get_mp3_source.sh
contrib/scripts/install_prereq install
./configure --libdir=/usr/lib64 --with-jansson-bundled

make menuselect # make select mp3
make
make install
make samples
make config


groupadd asterisk
useradd -r -d /var/lib/asterisk -g asterisk asterisk
usermod -aG audio,dialout asterisk
chown -R asterisk.asterisk /etc/asterisk
chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk
chown -R asterisk.asterisk /usr/lib64/asterisk

service asterisk start
asterisk -rvv
