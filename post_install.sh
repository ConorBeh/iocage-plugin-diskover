#!/usr/local/bin/bash
########################################################################
# Type: Installation file for shirosaidevÂ´s Diskover
# ----------------------------------------------------------------------
# Summary: Batch file to run inside a Jail @ FreeNAS or FreeBSD
# ----------------------------------------------------------------------
# Warning: I have NOT tighten the security of the jail
# ----------------------------------------------------------------------
# Description:
#    This is installes all Elasticsearch 5.6 , Redis 4.x , Python 3.7
#    with required modules , and PHP 7.2 with extenshions, and modules.
#    It also creates a Nginx webserver for the diskover-web module. 
#    You must run #pkg install bash and use bash to run the script.
#    
#    diskover is written and maintained by Chris Park (shirosai) 
#    and runs on Linux and OS X/macOS using Python 2/3.
#    
#    This sh file for FreeBSD is made by Andreas M Aanerud ( Aanerud )
# ----------------------------------------------------------------------
# changelist:
#    2019/02/18: 1st version
########################################################################
uri='$uri'
HOSTNAME='$HOSTNAME'
fastcgi_script_name='$fastcgi_script_name'
document_root='$document_root'
##############################################################################################
# This will install diskover, and itÂ´s dependenscies. 
##############################################################################################
# Installing Python
    clear
    echo '--------------------------------------------------------------------------------'
    echo ' INSTALLING  PYTHON 3.7 and git'
    echo '--------------------------------------------------------------------------------'
    echo
    ##pkg install -y python3
    ##pkg install -y py37-pip
    ##pkg install -y git
    ##pkg install -y py37-scandir
    ##pkg install -y py37-rq
    ##pkg install -y py37-progressbar2

	sleep 5  # Waits 5 seconds.
# Installing Elasticsearch 5.6 and Redis 4.0.11_1
    clear
    echo '--------------------------------------------------------------------------------'
    echo ' INSTALLING  Elasticsearch 5.6 and Redis'
    echo '--------------------------------------------------------------------------------'
    echo
    ##pkg install -y elasticsearch5
    ##pkg install -y redis
	sleep 5  # Waits 5 seconds.
# Adding services to rc.conf
    clear
    echo '--------------------------------------------------------------------------------'
    echo ' INSTALLING  Adding Elasticsearch and Redis to startup'
    echo '--------------------------------------------------------------------------------'
    echo
    echo "# Enable redis and elasticsearch" >> /etc/rc.conf
    echo 'redis_enable="YES"' >> /etc/rc.conf
    echo 'elasticsearch_enable="YES"' >> /etc/rc.conf
    echo 'elasticsearch_login_class="root"' >> /etc/rc.conf
	sleep 5  # Waits 5 seconds.
# Installing diskover
    clear
    echo '--------------------------------------------------------------------------------'
    echo ' INSTALLING  ShirosaidevÂ´s Diskover'
    echo '--------------------------------------------------------------------------------'
    echo
    cd /usr/local/
    mkdir diskover
    cd diskover/
    git clone https://github.com/shirosaidev/diskover.git
    cd diskover
    cp /usr/local/diskover/diskover/diskover.cfg.sample /usr/local/diskover/diskover/diskover.cfg
    pip-3.7 install -r requirements.txt
# Changing the Diskover Bot Launcher with FreeBSD Variables.
    sed -i '' 's+PYTHON=python+PYTHON=python3.7+g' /usr/local/diskover/diskover/diskover-bot-launcher.sh
    sed -i '' 's+DISKOVERBOT=./diskover_worker_bot.py+DISKOVERBOT=/usr/local/diskover/diskover/diskover_worker_bot.py+g' /usr/local/diskover/diskover/diskover-bot-launcher.sh
    sed -i '' 's+KILLREDISCONN=./killredisconn.py+KILLREDISCONN=/usr/local/diskover/diskover/killredisconn.py+g' /usr/local/diskover/diskover/diskover-bot-launcher.sh
	sleep 5  # Waits 5 seconds.
# Installing Screen
    clear
    echo '--------------------------------------------------------------------------------'
    echo ' INSTALLING  Screen, so you can run the crawler as a own terminal.'
    echo '--------------------------------------------------------------------------------'
    echo
    #pkg install -y screen
	sleep 5  # Waits 5 seconds.
##############################################################################################
# Now we can install the Diskover-web application dependencies 
##############################################################################################
# Installing PHP 7.2
    clear
    echo '--------------------------------------------------------------------------------'
    echo ' INSTALLING  PHP 7.2'
    echo '--------------------------------------------------------------------------------'
    echo
    #pkg install -y php72 php72-curl php72-extensions php72-composer php72-gd php72-json
	sleep 5  # Waits 5 seconds.
# Installing Nginx
    clear
    echo '--------------------------------------------------------------------------------'
    echo ' INSTALLING  Nginx'
    echo '--------------------------------------------------------------------------------'
    echo
    #pkg install -y nginx
    mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.bak
    echo "
#user  nobody;
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  example.com www.example.com;
        root /usr/local/diskover/diskover-web/public/;
        index index.php index.html index.htm;

        location / {
            try_files $uri $uri/ =404;
        }

        error_page      500 502 503 504  /50x.html;
        location = /50x.html {
            root /usr/local/www/nginx-dist;
        }
    
                # Enables PHP
                location ~ \.php$ {
                        fastcgi_pass unix:/var/run/php-fpm.socket;
                        try_files $uri =404;
                        fastcgi_param HTTPS on;
                        include fastcgi_params;
                        }
    }
}
" >> /usr/local/etc/nginx/nginx.conf
    cp /usr/local/etc/nginx/fastcgi_params /usr/local/etc/nginx/fastcgi_params.bak
sed -e '7i\
fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;' /usr/local/etc/nginx/fastcgi_params > /usr/local/etc/nginx/fastcgi_params2
    mv /usr/local/etc/nginx/fastcgi_params2 /usr/local/etc/nginx/fastcgi_params
	sleep 5  # Waits 5 seconds.
# Configuration php-fpm
    clear
    echo '--------------------------------------------------------------------------------'
    echo ' Configuration php-fpm and php.ini'
    echo '--------------------------------------------------------------------------------'
    echo
    mv /usr/local/etc/php-fpm.conf /usr/local/etc/php-fpm.conf.bak
    echo "
[global]
pid = run/php-fpm.pid

[PYDIO]
listen = /var/run/php-fpm.socket
listen.owner = www
listen.group = www
listen.mode = 0666

listen.backlog = -1
listen.allowed_clients = 127.0.0.1

user = www
group = www

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500

env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
" >> /usr/local/etc/php-fpm.conf
    cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
	sleep 5  # Waits 5 seconds.
# Adding services to rc.conf
    clear
    echo '--------------------------------------------------------------------------------'
    echo ' INSTALLING  Adding php-fpm and nginx to startup'
    echo '--------------------------------------------------------------------------------'
    echo
    echo '# Enable php-fpm and nginx' >> /etc/rc.conf
    echo 'firewall_enable="NO"' >> /etc/rc.conf
    echo 'nginx_enable="YES"' >> /etc/rc.conf
    echo 'php_fpm_enable="YES"' >> /etc/rc.conf
	sleep 5  # Waits 5 seconds.
##############################################################################################
# Installing the Diskover-web application
##############################################################################################
# Installing diskover-web
    clear
    echo '--------------------------------------------------------------------------------'
    echo ' INSTALLING  diskover-web'
    echo '--------------------------------------------------------------------------------'
    echo
    cd /usr/local/diskover/
    git clone https://github.com/shirosaidev/diskover-web.git
    cd diskover-web/
    composer install
    ln -s /usr/local/diskover/diskover-web/public/dashboard.php /usr/local/diskover/diskover-web/public/index.php
    cp /usr/local/diskover/diskover-web/src/diskover/Constants.php.sample /usr/local/diskover/diskover-web/src/diskover/Constants.php
    cp /usr/local/diskover/diskover-web/public/smartsearches.txt.sample /usr/local/diskover/diskover-web/public/smartsearches.txt
    cp /usr/local/diskover/diskover-web/public/customtags.txt.sample /usr/local/diskover/diskover-web/public/customtags.txt
    cp /usr/local/diskover/diskover-web/public/extrafields.txt.sample /usr/local/diskover/diskover-web/public/extrafields.txt
    chmod -R 755 /usr/local/diskover/diskover-web/public
    sleep 5  # Waits 5 seconds.
    # Start services
    service redis start
    service elasticsearch start
    service nginx start
    service php-fpm start           
    # Start diskover
    bash /usr/local/diskover/diskover/diskover-bot-launcher.sh
    python3.7 /usr/local/diskover/diskover/diskover.py -i diskover-index -a -O
    mkdir /mnt/fnpool
    # Create crontabs
    (crontab -l 2>/dev/null; echo "@reboot bash /usr/local/diskover/diskover/diskover-bot-launcher.sh") | crontab -
    (crontab -l 2>/dev/null; echo "@reboot python3.7 /usr/local/diskover/diskover/diskover.py -i diskover-index-jail -a -O") | crontab -
    (crontab -l 2>/dev/null; echo "@daily /usr/local/bin/python3.7 /usr/local/diskover/diskover/diskover.py -d /mnt/fnpool -i diskover-`date '+%Y-%m-%d'` -a -O") | crontab -

    
    


# Output/save info
echo "Installing Diskover..."
echo "After installation, please mount your pool inside the jail to /mnt/fnpool"
echo "A daily crontab has been installed to index the storage pool. If time period is not desirable, enter the jail and run "crontab -e" to modify."

echo "Installing Diskover..." >> /root/PLUGIN_INFO
echo "After installation, please mount your pool inside the jail to /mnt/fnpool" >> /root/PLUGIN_INFO
echo "A daily crontab has been installed to index the storage pool. If time period is not desirable, enter the jail and run "crontab -e" to modify." >> /root/PLUGIN_INFO
exit
