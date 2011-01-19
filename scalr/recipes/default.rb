#
# Cookbook Name:: scalr
# Recipe:: default
#
# Copyright 2011, 40 North LLC
#
# All rights reserved - Do Not Redistribute
#

cookbook_file "/etc/apt/preferences.d/php" do
  source "php"
  owner "root"
  group "root"
  mode 0755
   
  not_if { File.exists?("/tmp/scalrlock") }
end

template "/tmp/grants" do
  source "grants.erb"
  owner "root"
  group "root"
  mode 0700

  not_if { File.exists?("/tmp/scalrlock") }
end


remote_file "/tmp/php5-mcrypt_5.2.6-0ubuntu2_amd64.deb" do
  source "http://free.nchc.org.tw/ubuntu/pool/universe/p/php-mcrypt/php5-mcrypt_5.2.6-0ubuntu2_amd64.deb" 
  mode 755
   not_if {File.exists?("/tmp/php5-mcrypt_5.2.6-0ubuntu2_amd64.deb") }
end

remote_file "/tmp/scalr.zip" do
  source "http://scalr.googlecode.com/files/scalr-2.1.1.zip" 
  mode 755
     not_if {File.exists?("/tmp/scalr.zip") }

end

remote_file "/tmp/php_rrdtool.tar.gz" do
  source "http://oss.oetiker.ch/rrdtool/pub/contrib/php_rrdtool.tar.gz" 
  mode 755
     not_if {File.exists?("/tmp/php_rrdtool.tar.gz") }

end



bash "install scalr" do
  cwd "/tmp"
  code <<-EOH
  
  sudo apt-get install -q -y openssh-server
  sudo add-apt-repository ppa:txwikinger/php5.2
  
  sudo apt-get -q -y update
  sudo apt-get -q -y upgrade
  sudo apt-get -q -y install php5
  
  sudo apt-get -q -y install php5-mysql
  
  sudo apt-get -q -y install libssh2-1 openssl libsnmp-base libsnmp15 snmp snmpd bind9
sudo apt-get -q -y install curl php5-curl php5-cli gettext libltdl7 libmcrypt4


sudo dpkg --force-all -i /tmp/php5-mcrypt_5.2.6-0ubuntu2_amd64.deb  
sudo apt-get -q -y -f install
sudo apt-get install -q -y mcrypt

sudo apt-get install -q -y libmhash2 php5-mhash php5-snmp snmp snmpd libsnmp15 php-pear php5-dev libssh2-1-dev 
sudo pecl install -f ssh2
sudo apt-get install -q -y libcurl3-openssl-dev
sudo pecl install pecl_http
sudo echo "extension=http.so" | sudo tee -a /etc/php5/apache2/php.ini
sudo echo "extension=ssh2.so" | sudo tee -a /etc/php5/apache2/php.ini
sudo echo "extension=http.so" | sudo tee -a /etc/php5/cli/php.ini
sudo echo "extension=ssh2.so" | sudo tee -a /etc/php5/cli/php.ini
sudo mkdir /var/www
sudo echo "<? phpinfo(); ?>" | sudo tee -a /var/www/info.php

sudo service apache2 restart
cd /tmp

sudo wget localhost/info.php | sudo tee out.txt
sudo cat out.txt

sudo apt-get install -q -y unzip  
sudo unzip scalr.zip
sudo rm -fr /var/scalr
sudo mkdir /var/scalr
cd 2.1.1
sudo mv * /var/scalr
cd /var
sudo chown -R www-data:www-data /var/scalr/app/cache /var/scalr/app/cron/cron.pid /var/scalr/app/etc/.passwd
sudo chmod 700 -R /var/scalr/app/cache /var/scalr/app/cron/cron.pid /var/scalr/app/etc/.passwd
sudo mv www www_old
sudo rm -fr /var/www
sudo ln -s /var/scalr/app/www /var/www
sudo chmod a+rX -R /var/www
sudo chmod 755 -R /var/scalr/sql

mysql -u root --password=#{node[:mysql][:server_root_password]} -e "create database scalr;"
mysql -u root -D scalr --password=#{node[:mysql][:server_root_password]} < /var/scalr/sql/scalr-2.1-structure.sql
mysql -u root -D scalr --password=#{node[:mysql][:server_root_password]} < /var/scalr/sql/scalr-2.1-init-data.sql


sudo chmod 777 /tmp/grants


mysql -u root --password=#{node[:mysql][:server_root_password]} < /tmp/grants

sudo rm /tmp/grants


sudo sed -i 's/pass = ""/pass="#{node[:scalrDbPass]}"/g' /var/scalr/app/etc/config.ini
sudo sed -i 's/user = "root"/user="#{node[:scalrDbUser]}"/g' /var/scalr/app/etc/config.ini


sudo sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/sites-enabled/000-default

cat /var/scalr/app/etc/config.ini


sudo mkdir /var/scalr/app/cache/smarty_bin/en_US 
sudo chmod 777 /var/scalr/app/cache/smarty_bin/en_US 
sudo chmod 0777 /var/scalr/app/etc/.passwd 
sudo chmod 0777 /var/scalr/app/etc/.cryptokey 

service apache2 restart

sudo wget localhost/testenvironment.php | sudo tee out.txt
sudo cat out.txt

sudo touch /tmp/scalrlock
sudo chmod 755 /tmp/scalrlock

sudo apt-get -q -y install librrd2-dev php5-dev rrdtool
cd /tmp
sudo tar zxvf /tmp/php_rrdtool.tar.gz
sudo cp -R /tmp/rrdtool /usr/include/php5/ext
cd /usr/include/php5/ext/rrdtool
sudo phpize
sudo ./configure -with-php-config=/usr/bin/php-config -with-rrdtool=/usr
sudo make ; sudo make install
cd /etc/php5/conf.d/


sudo echo "extension=rrdtool.so" | sudo tee -a rrdtool.ini
sudo service apache2 restart

sudo echo "extension=rrdtool.so" | sudo tee -a /etc/php5/apache2/php.ini
sudo echo "extension=rrdtool.so" | sudo tee -a /etc/php5/cli/php.ini

sudo chown -R www-data /var/scalr/app/www
sudo chgrp -R www-data /var/scalr/app/www



sudo service apache2 restart

cd /tmp
sudo wget localhost/testenvironment.php | sudo tee out.txt
sudo cat out.txt

sudo mkdir /etc/bind/client_zones
sudo touch /etc/bind/client_zones/zones.include
sudo chmod -R 777 /etc/bind/client_zones
echo "#xxxx" > sudo tee -a  /etc/bind/client_zones/zones.include
echo "/etc/bind/client_zones/zones.include" | sudo tee -a /etc/bind/named.conf

sudo sed -i 's/\/var\/named\/etc\/namedb\/client_zones/\/etc\/bind\/client_zones/g' /var/scalr/app/cronclass.DNSManagerPollProcess.php

sudo sed -i 's/throw new Exception("Zones config is empty")/;/g' /var/scalr/app/cronclass.DNSManagerPollProcess.php




  EOH
  
  not_if { File.exists?("/tmp/scalrlock") }
end



cron "usageStatsPoller" do
  minute "*/4"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --UsageStatsPoller"
   
end
cron "scheduler" do
  minute "*/2"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --Scheduler"
  
end

cron "mySQLMa" do
  minute "*/15"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --MySQLMaintenance"
 
end

cron "dnsManager" do
  minute "*"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --DNSManagerPoll"
  
end


cron "scaling" do
  minute "*/4"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --Scaling"
  
end


cron "rotateLogs" do
  minute "17"
  hour "5"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --RotateLogs"
  
end

cron "poller" do
  minute "*/4"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --Poller"
   
end
cron "dbq" do
  minute "*/5"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --DBQueueEvent"
 
end

cron "rdsMaintenance" do
  minute "*/4"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --RDSMaintenance"
  
end
cron "bundleTasksManager" do
  minute "*/2"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --BundleTasksManager"
 
end

cron "msgQ" do
  minute "*/2"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --MessagingQueue"
  
end

cron "ebsManager" do
  minute "*/2"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --EBSManager"
  
end

cron "sMsg" do
  minute "*"
  command "/usr/bin/php -q /var/scalr/app/cron/cron.php  --ScalarizrMessaging"
  
end

cron "snmpStatsPoller" do
  minute "*"
  command "/usr/bin/php -q /var/scalr/app/cron-ng/cron.php --SNMPStatsPoller"
  
end
