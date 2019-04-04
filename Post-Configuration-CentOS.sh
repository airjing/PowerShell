# orginal post on https://www.tecmint.com/things-to-do-after-minimal-rhel-centos-7-installation/
# enable NIC
sudo vi /etc/sysconfig/network-scirpt/ifcfg-eth0
# set ONBOOT="yes"
# restart network service to apply change on above
service network restart
# show ip address
ip addr show
# install ifconfig tool in package net-tools
yum -y install net-tools
# show hostname
echo $hostname
# change hostname
sudo vi /etc/hostname
#change yum source to 163.com
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
sudo yum clean all
sudo yum makecache
# update system
sudo yum -y update && yum -y upgrade
# Install and configure SSH Server
# check currently installed SSH version
SSH -V
# change SSH settings
sudo vi /etc/ssh/sshd_config
# force to use Protocal 2
# Protocol 2
# Disable SSH root login
# PermitRootLogin no
sudo systemctl restart sshd.service
# install Apache HTTP Server
sudo yum -y install httpd
# binding listen port to 80
sudo vi /etc/httpd/conf/httpd.conf
# LISTEN 80
# allow http service through firewall
firwall-cmd --add-service=http
# allow port
firwall-cmd --add-port=8080/tcp
# reload firewall
firewall-cmd --reload
# restart httpd service
systemctl restart httpd.service
# Add httpd service to system-wide to start automatically when system boots.
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
# install PHP
sudo yum -y install php
# after install php, restart httpd to render php in web browser
sudo systemctl restart httpd.service
echo -e "<?php\nphpinfo();\n?>"  > /var/www/html/phpinfo.php
php /var/www/html/phpinfo.php
curl http://127.0.0.1/phpinfo.php
# install MariaDB database
sudo yum -y install mariadb-server mariadb
# start and configure MariaDB to start automatically at boot
sudo systemctl start mariadb.service
sudo systemctl enable mariadb.service
# allow service mysql through firewall
sudo firewall-cmd --add-service=mysql
# secure MariaDB server
sudo /usr/bin/mysql_secure_installation
# refer to LAMP and Apache virtual host
# https://www.tecmint.com/install-lamp-in-centos-7/
# https://www.tecmint.com/apache-virtual-hosting-in-centos/
# install GCC compiler
sudo yum -y install gcc
# check the version of installed gcc
gcc --version
# install java
sudo yum -y install java
# check the versionof java installed
java -version
# install Apache Tomcat
# Tomcat is a servlet container designed by Apache to run Java HTTP web server.
# install Tomcat as below but it is necessary to point out that you must have
# installed Java prior of installing tomcat.
sudo yum -y install tomcat
# check version of tomcat
/usr/sbin/tomcat version
# Add service tomcat and default port through firewall and reload settings
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload
# create username and password for tomcat
sudo vi /etc/tomcat/tomcat-users.xml
# <role username="tomcatadmin" password="tomcatuserpassword" roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>
systemctl stop tomcat
systemctl start tomcat
systemctl enable tomcat.service
# https://www.tecmint.com/install-apache-tomcat-in-centos/
# Install Nmap to Monitor Open Ports
sudo yum -y install nmap
# list all open ports and corresponding service
namp 127.0.0.1
# or use firewall-cmd to list all the ports
firewall-cmd --list-ports
# firewalld is a firewall service which manages the server dynamically. 
# Firewalld removed iptables in CentOS 7. with iptables every change 
# in order to be taken into effect needs to flush all the old rules 
# and create new rules.
# However with firewalld, no flushing and recreating of new rules
# required and only changes are applied on the fly.
# check if firewalld is running or not.
systemctl status firewalld
firewall-cmd --state
# get a list of all the zones
firewall-cmd --get-zones
# to get details on a zone before switching
firewall-cmd --zone=work --list-all
# to get default zone
firewall-cmd --get-default-zone
# to switch a different zone say work
firewall-cmd --set-default-zone=work
# to remove a service as http, temporarily
firewall-cmd --remove-service=http
# to remove a service as http, permantely
firewall-cmd --remove-service=http --permanent
firewall-cmd --reload
# install wget
sudo yum -y install wget
sudo yum -y install p7zip
# install and configure sudo
# the following command will open the file /etc/sudoers for editing...
visudo
# Give all the permission(equal to root) to a user, that has already been created
# shaojc ALL=(ALL) ALL
# Give all the permission(equal to root) to a user, except reboot and shutdown
# cmnd_Alias nopermit = /sbin/shutdown, /sbin/reboot
# then add alias with Logical (!) operator
# shaojc ALL=(ALL) ALL,!nopermit
# Enable virtualization with Virtualbox
sudo yum -y groupinstall 'Development Tools' SDL kernel-devel kernel-headers dkms
cd /etc/yum.repos.d/
sudo wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc
sudo rpm --import oracle_vbox.asc
sudo yum update && yum install virtualbox-4.3
sudo wget http://download.virtualbox.org/virtualbox/4.3.12/Oracle_VM_VirtualBox_Extension_Pack-4.3.12-93733.vbox-extpack
VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-4.3.12-93733.vbox-extpack
# create user vbox to manage virtualbox and add it to group vboxusers
adduser vbox
passwd vbox
usermod -G vboxusers vbox
# install php with soap extension
yum install php php-devel php-common php-soap php-gd
wget http://sourceforge.net/projects/phpvirtualbox/files/phpvirtualbox-4.3-1.zip
unzip phpvirtualbox-4.*.zip
cp phpvirtualbox-4.3-1 -R /var/www/html
mv config.php.example config.php
vi config.php
service vbox-service restart
service httpd restart
# http://192.168.0.15/phpvirtualbox-4.3-1/

# install GUI
sudo yum group list
# yum groupinfo "Server with GUI" AND # yum groupinfo "GNOME Desktop"
yum group install 'GNOME Desktop' 
systemctl enable graphical.target --force rm '/etc/systemd/system/default.target'
ln -s '/usr/lib/systemd/system/graphical.target' '/etc/systemd/system/default.target'

# upgrade kernel
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
sudo yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
sudo yum --enablerepo=elrepo-kernel install kernel-ml
sudo reboot
#reboot to apply the latest kernel, and then select latest kernel from the menu as shown.
# set default kernel verion in GRUB
sudo vi /etc/default/GRUB
# set GRUB_DEFAULT=0
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
reboot

# install .net core
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
sudo yum -y update
sudo yum -y install dotnet-sdk-2.2

# install vs code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
yum check-update
sudo yum -y install code

# compile and install latest git
sudo yum -y group install "Development Tools"
sudo yum -y install zlib-devel perl-ExtUtils-MakeMaker asciidoc xmlto openssl-devel wget 7pzip
wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.20.1.tar.gz
tar -zxvf git-2.20.1.tar.gz
cd git-2.20.1
autoconf
./configure
sudo make -j8 && sudo make -j8 install
ln -s /usr/local/bin/git /usr/bin/

# Install DNS server
sudo yum -y install bind bind-utils
sudo vi /etc/named.conf
options {
        listen-on port 53 { any; };
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        recursing-file  "/var/named/data/named.recursing";
        secroots-file   "/var/named/data/named.secroots";
        allow-query     { any; };              

        /*
         - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
         - If you are building a RECURSIVE (caching) DNS server, you need to enable
           recursion.
         - If your recursive DNS server has a public IP address, you MUST enable access
           control to limit queries to your legitimate users. Failing to do so will
           cause your server to become part of large scale DNS amplification
           attacks. Implementing BCP38 within your network would greatly
           reduce such attack surface
        */
        recursion yes;

        dnssec-enable no;
        dnssec-validation no;

        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.iscdlv.key";

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};
zone "azure.io" {
        type master;
        file "azure.io.zone";
}; 

# add DNS zone file
 sudo cp /var/named/named.empty /var/named/azure.io.zone
 sudo vi /var/named/azure.io.zone
 $TTL 3H
@       IN SOA  @ azure.io. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        NS      @
        A       127.0.0.1
        AAAA    ::1
saltmaster      IN      A       192.168.2.131

sudo chown root:named /var/named/azure.io.zone
sudo systemctl restart named
sudo firewall-cmd
nslookup saltmaster.azure.io

firewall-cmd --zone=public --add-port=4505/tcp --permanent
firewall-cmd --zone=public --add-port=4506/tcp --permanent

# install saltstack
# Redhat/CentOS7 PY2
sudo yum -y install https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm 
sudo yum clean expire-cache
sudo yum install salt-master
sudo yum install salt-minion
sudo yum install salt-ssh
sudo yum install salt-syndic
sudo yum install salt-cloud
sudo yum install salt-api
# auto start for salt-master
sudo systemctl enable salt-master.service
sudo systemctl start salt-master.service
# auto start for salt-minion
sudo systemctl enable salt-minion.service
sudo systemctl start salt-minion.service
service salt-minion start
# install Google chrome by yum
sudo vi /etc/yum.repos.d/google-chrome.repo

                [google-chrome]
                name=google-chrome
                baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch
                enabled=1
                gpgcheck=1
                gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub

yum info google-chrome-stable
yum install google-chrome-stable
#install docker
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io