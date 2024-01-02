echo "### Installing dependencies ###"
sudo apt update
# 3 different install lines to remove dependencies bug between packages
sudo apt install -y dialog openjdk-19-jdk mariadb-server make unzip gunicorn build-essential  python-dev-is-python3 python3-pip libffi-dev nginx
sudo apt install -y libcairo2-dev libjpeg62-dev libpng-dev libtool-bin uuid-dev libpango1.0-dev libssh2-1-dev libssl-dev
sudo apt install -y libjpeg-turbo8-dev

start_location = pwd

# retrieving instance informations for configuration purpose
echo "Starting configuration of MariaDB for Guacamole and CTFd"
read -s -p $'What \e[31mpassword\e[0m do you want for \e[31mroot\e[0m DB User ? '
rootpass=$REPLY
echo ''

read -p $'What \e[31musername\e[0m do you want for \e[31mGuacamole\e[0m DB User ? '
guacuser=$REPLY

read -s -p $'What \e[31mpassword\e[0m do you want for \e[31mGuacamole\e[0m DB User ? '
guacpass=$REPLY
echo ''

read -p $'What \e[31musername\e[0m do you want for \e[31mctfd\e[0m DB User ? '
ctfduser=$REPLY

read -s -p $'What \e[31mpassword\e[0m do you want for \e[31mctfd\e[0m DB User ? '
echo ''
ctfdpass=$REPLY

read -p $'What \e[31mServerName\e[0m do you want for \e[31myour server\e[0m (FQDN) ? '
servername=$REPLY

read -p $'What\'s the \e[31mIp Adress\e[0m of \e[31myour server\e[0m ? '
server_ip=$REPLY

# starting configuration

## database configuration
echo "Creating Databases and DBUser for both apps"
echo "Adding privileges to DBUser on BDD"
sudo mariadb <<_EOF_
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$rootpass');
FLUSH PRIVILEGES;
CREATE DATABASE guacamole_db;
CREATE USER '$guacuser'@'localhost' IDENTIFIED BY '$guacpass';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO '$guacuser'@'localhost';
CREATE DATABASE ctfd;
CREATE USER '$ctfduser'@'localhost' IDENTIFIED BY '$ctfdpass';
GRANT ALL privileges ON ctfd.* TO '$ctfduser'@'localhost';
FLUSH PRIVILEGES;
_EOF_

## Guacamole configuration
### Database configuration
echo "Sending schema with guacadmin default user to MariaDB" #TODO Add in schema script user for guac script 
cat schema/*.sql | sudo mariadb guacamole_db

echo "Sending CTFD schema with default config to MariaDB"
cat DB_EXPORT_CTFD.sql | sudo mariadb ctfd

### Server Configuration
echo "Starting configuration of Guacamole Server"
echo "Sending config folder to etc"
sudo unzip guacamole-config.zip -d /etc

echo "Configuration and build Guacamole Server with needed dependencies"
tar xzf guacamole-server-1.5.3.tar.gz
cd guacamole-server-1.5.3
./configure --with-init-dir=/etc/init.d
sudo make
sudo make install
sudo ldconfig
sudo systemctl daemon-reload
sudo systemctl enable guacd
sudo systemctl start guacd
cd ..

echo "Modifying Guacamole config to match DB account info"
sudo sed -i "/mysql-username:/ s/$/ $guacuser/" /etc/guacamole/guacamole.properties
sudo sed -i "/mysql-password:/ s/$/ $guacpass/" /etc/guacamole/guacamole.properties

Echo "Starting Guacamole GUI configuration (Tomcat...)"
echo "Sending Tomcat app to opt folder"
sudo unzip tomcat.zip -d /opt

echo "Setting default umask"
umask 022
echo "Creating Tomcat user"
sudo useradd -r -s /usr/sbin/nologin tomcat
echo "Replacing the Tomcat logs folder for a symbolic link pointing /var/logs/tomcat"
sudo mkdir /var/log/tomcat
sudo chown tomcat:adm /var/log/tomcat
sudo chmod 750 /var/log/tomcat
sudo chmod g+s /var/log/tomcat
sudo rm -rf /opt/tomcat/logs
sudo ln -s /var/log/tomcat /opt/tomcat/logs

echo "Adding just enough permission to tomcat files for it to work"
sudo chown -R root:tomcat /opt/tomcat
sudo chmod -R g+r /opt/tomcat/conf/
sudo find /opt/tomcat/bin/ -iname "*.sh" -exec chmod ug+x {} \;
sudo chmod g+w /opt/tomcat/temp /opt/tomcat/work
sudo chmod -R o-rwx /opt/tomcat/

echo "Sending Service file to systemd and starting Tomcat"
sudo cp tomcat.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now tomcat


## CTFd Configuration
echo "Time for CTFd ! (finally)"
echo "Moving CTFd Folder to opt"
sudo cp -r CTFd /opt
sudo chown -R root:root /opt/CTFd

echo "Installing python dependencies for CTFd"
sudo -H pip install -r /opt/CTFd/requirements.txt
sudo -H pip install -U pyopenssl cryptography
sudo -H pip install guacamole-api-wrapper

echo "Modifying config file to match DB account info"
sudo sed -i "/DATABASE_USER =/ s/$/ $ctfduser/" /opt/CTFd/CTFd/config.ini
sudo sed -i "/DATABASE_PASSWORD =/ s/$/ $ctfdpass/" /opt/CTFd/CTFd/config.ini

echo "Sending Service file to systemd and starting ctfd"
sudo mv ctfd.service /etc/systemd/system
sudo systemctl daemon-reload && sudo systemctl enable --now ctfd

## Nginx Reverse Proxy Configuration
echo "Install and configuration of Nginx as a reverse proxy"
sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
sudo cp default.nginx /etc/nginx/sites-available/default

echo "Creating Self-Signed Certificate"
sudo mkdir /etc/nginx/private
cd /etc/nginx/private
echo "Please enter Self Signed certificate informations"
sudo openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out certificate.pem -subj "/CN=$servername"

cd $start_location
sudo sed -i "s/your_servername/$servername/g" /etc/nginx/sites-available/default
sudo sed -i "s/your_ip/$server_ip/g" /etc/nginx/sites-available/default

sudo systemctl restart nginx

## LXD Configuration
echo "starting LXD configuration"
### Getting disk information in order to configure the disk as a ZFS pool for LXD to use
echo "Displaying disk informations"
lsblk -pdo NAME,SIZE
read -p $'Which \e[31mDisk\e[0m do you want to use for \e[31mLXD ZFS Pool\e[0m (Full path, ex: /dev/sdx) '
disklocation=${REPLY//\//\\\/} # echape les barres obliques
sudo sed -i "/source:/ s/$/ $disklocation/" ./lxd_config.yaml
cat lxd_config.yaml | sudo lxd init --preseed

### Here we force the lxd dhcp to use the mac address as an identifier to evade ip duplicates between instances
lxc profile set default cloud-init.network-config '{ "version": 2, "ethernets": { "enp5s0": { "dhcp4": true, "dhcp-identifier": "mac" } } }'

### Téléchargement de l'instance de jeu -> TODO ajouter un read qui permet de donner le lien de téléchargement
echo "Téléchargement de l'instance de jeu"
wget -O ctf-instance.tar.gz https://www.grosfichiers.com/uQD5UwRixDP_qZQxhWGdEUV

echo "Importation de l'image téléchargée"
lxc image import ctf-instance.tar.gz --alias ctf-instance

### Here we launch a container to test the correct operation of the instance and add the instance in cache so player can start their instances faster
echo "Launching one container for testing purpose"
lxc launch ctf-instance testvm
lxc list
lxc rm -f testvm

echo "Finished !"
