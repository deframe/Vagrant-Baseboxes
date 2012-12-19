#
# Import VM settings and copy them to the guest
#

source /vagrant/provision/vm-settings.sh
cp /vagrant/provision/vm-settings.sh /etc/vm-settings.sh

#
# Use non-interactive mode for package installation
#

export DEBIAN_FRONTEND=noninteractive

#
# Update & upgrade packages
#

apt-get -y update
apt-get -y upgrade

#
# Create a shortcut function to help determine if a package is installed or not
#

function packageInstalled {
    if dpkg --get-selections "$1" 2>/dev/null | grep -qE '\<install$' > /dev/null; then
        return 0
    else
        return 1
    fi
}

#
# Install Debconf utils
#

if ! packageInstalled "debconf-utils"; then
    apt-get -y install debconf-utils
fi

#
# Install cURL
#

if ! packageInstalled "curl"; then
    apt-get -y install curl
fi

#
# Install and configure MySQL
#

if ! packageInstalled "mysql-server" && packageInstalled "debconf-utils"; then
    echo "mysql-server-5.1 mysql-server/root_password password $vm_mysql_root_password" > /tmp/mysql.preseed
    echo "mysql-server-5.1 mysql-server/root_password_again password $vm_mysql_root_password" >> /tmp/mysql.preseed
    echo "mysql-server-5.1 mysql-server/start_on_boot boolean true" >> /tmp/mysql.preseed
    cat /tmp/mysql.preseed | debconf-set-selections
    rm /tmp/mysql.preseed
    apt-get -y install mysql-server
    if packageInstalled "mysql-server"; then
        mysql --user=root --password=$vm_mysql_root_password --execute="GRANT ALL PRIVILEGES ON *.* TO '$vm_mysql_standard_user_username'@'localhost' IDENTIFIED BY '$vm_mysql_standard_user_password' WITH GRANT OPTION"
    fi
fi

#
# Install and configure Apache & mods
#

if ! packageInstalled "apache2"; then
    apt-get -y install apache2
    if packageInstalled "apache2"; then
        echo "" >> /etc/apache2/apache2.conf
        echo "# Set Server Name" >> /etc/apache2/apache2.conf
        echo "ServerName localhost" >> /etc/apache2/apache2.conf
        echo "" >> /etc/apache2/apache2.conf
        echo "# Set Application Environment" >> /etc/apache2/apache2.conf
        echo "SetEnv ENVIRONMENT_TYPE development" >> /etc/apache2/apache2.conf
        a2enmod rewrite        
        echo "<h1>There's nothing here yet!</h1><p>Try creating a website...</p>" > /var/www/index.html
        chown -R vagrant:vagrant /web
        cp -f /vagrant/provision/templates/etc/apache2/sites-available/default /etc/apache2/sites-available/default
        rm /etc/apache2/sites-available/default-ssl
        service apache2 restart
    fi
fi

if ! packageInstalled "libapache2-mod-auth-mysql" && packageInstalled "apache2" && packageInstalled "mysql-server"; then
    apt-get -y install libapache2-mod-auth-mysql
    if packageInstalled "libapache2-mod-auth-mysql"; then
        a2enmod auth_mysql
        echo "Auth_MySQL_Info localhost $vm_mysql_standard_user_username $vm_mysql_standard_user_password" >> /etc/apache2/mods-enabled/auth_mysql.load
        service apache2 restart
    fi
fi

#
# Install and configure PHP & extensions
#

if ! packageInstalled "php5" && packageInstalled "apache2"; then
    apt-get -y install php5
    if packageInstalled "php5"; then
        find / -name php.ini | xargs sed -i "s/;\s*date.timezone\s*=\s*/date.timezone = Europe\/London/g"
        mkdir /usr/share/phpinfo
        echo "<?php phpinfo();" > /usr/share/phpinfo/phpinfo.php
        cp /vagrant/provision/templates/etc/apache2/conf.d/phpinfo /etc/apache2/conf.d/phpinfo
    fi
fi

if ! packageInstalled "php5-suhosin" && packageInstalled "php5"; then
    apt-get -y install php5-suhosin
    if packageInstalled "php5-suhosin"; then
        find / -name suhosin.ini | xargs sed -i "s/;\s*suhosin.executor.include.whitelist\s*=\s*/suhosin.executor.include.whitelist = phar/g"
    fi
fi

if ! packageInstalled "php-apc" && packageInstalled "php5"; then
    apt-get -y install php-apc
    if packageInstalled "php-apc"; then
        if [ -f "/usr/share/doc/php-apc/apc.php.gz" ]; then   
            gunzip /usr/share/doc/php-apc/apc.php.gz
        fi
        sed -i "s/defaults[(]'USE_AUTHENTICATION',1[)];/defaults('USE_AUTHENTICATION',0);/g" /usr/share/doc/php-apc/apc.php
        cp /vagrant/provision/templates/etc/apache2/conf.d/apc /etc/apache2/conf.d/apc
        service apache2 restart
    fi
fi

if ! packageInstalled "php5-curl" && packageInstalled "php5"; then
    apt-get -y install php5-curl
fi

if ! packageInstalled "php5-intl" && packageInstalled "php5"; then
    apt-get -y install php5-intl
fi

if ! packageInstalled "php5-mcrypt" && packageInstalled "php5"; then
    apt-get -y install php5-mcrypt
fi

if ! packageInstalled "php5-mysqlnd" && packageInstalled "php5"; then
    apt-get -y install php5-mysqlnd
fi

if ! packageInstalled "php5-pspell" && packageInstalled "php5"; then
    apt-get -y install php5-pspell
fi

if ! packageInstalled "libssh2-php" && packageInstalled "php5"; then
    apt-get -y install libssh2-php
fi

if ! packageInstalled "php5-sqlite" && packageInstalled "php5"; then
    apt-get -y install php5-sqlite
fi

if ! packageInstalled "php5-xdebug" && packageInstalled "php5"; then
    apt-get -y install php5-xdebug
fi

if ! packageInstalled "php5-xsl" && packageInstalled "php5"; then
    apt-get -y install php5-xsl
fi

if ! packageInstalled "php-pear" && packageInstalled "php5"; then
    apt-get -y install php-pear
    if packageInstalled "php-pear"; then
        pear config-set auto_discover 1
        pear channel-discover pear.phpdoc.org
        pear channel-discover pear.phing.info
        pear channel-discover components.ez.no
        pear channel-discover pear.phpunit.de
        pear channel-discover pear.phpmd.org
        pear install PHP_CodeSniffer
        pear install phpdoc/phpDocumentor-alpha
        pear install phing/phing
        pear install phpunit/PHPUnit
        pear install phpunit/phpcpd
        pear install phpunit/phpdcd-beta
        pear install phpunit/phploc
        pear install phpmd/PHP_PMD
    fi
fi

#
# Install ImageMagick
#

if ! packageInstalled "imagemagick"; then
    apt-get -y install imagemagick
fi

#
# Install GraphViz
#

if ! packageInstalled "graphviz"; then
    apt-get -y install graphviz
fi

#
# Install and configure SSMTP
#

if ! packageInstalled "ssmtp"; then
    apt-get -y install ssmtp
    if packageInstalled "ssmtp"; then
        rm /etc/ssmtp/ssmtp.conf
        cp /vagrant/provision/templates/etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf
        sed -i "s/{{smtp_server}}/$vm_smtp_server/g" /etc/ssmtp/ssmtp.conf
        sed -i "s/{{smtp_use_tls}}/$vm_smtp_use_tls/g" /etc/ssmtp/ssmtp.conf
        sed -i "s/{{smtp_use_starttls}}/$vm_smtp_use_starttls/g" /etc/ssmtp/ssmtp.conf
        sed -i "s/{{smtp_username}}/$vm_smtp_username/g" /etc/ssmtp/ssmtp.conf
        sed -i "s/{{smtp_password}}/$vm_smtp_password/g" /etc/ssmtp/ssmtp.conf
        sed -i "s/{{hostname}}/$HOSTNAME/g" /etc/ssmtp/ssmtp.conf
    fi
fi

#
# Install VCS packages
#

if ! packageInstalled "git"; then
    apt-get -y install git
fi

if ! packageInstalled "subversion"; then
    apt-get -y install subversion
fi

if ! packageInstalled "mercurial"; then
    apt-get -y install mercurial
fi

#
# Install Composer
#

if [ ! -f "/usr/local/bin/composer" ] && packageInstalled "curl"; then
    cd
    curl -s https://getcomposer.org/installer | php
    if [ -f "composer.phar" ]; then
        sudo mv composer.phar /usr/local/bin/composer
    fi
fi

#
# Install and configure phpMyAdmin
#

if [ ! -d "/usr/share/phpmyadmin" ] && packageInstalled "apache2" && packageInstalled "mysql-server"; then
    cp /vagrant/provision/resources/phpMyAdmin-3.5.2.2-english.tar.gz /usr/share
    cd /usr/share/
    tar xf phpMyAdmin-3.5.2.2-english.tar.gz
    rm phpMyAdmin-3.5.2.2-english.tar.gz
    mv ./phpMyAdmin-3.5.2.2-english ./phpmyadmin
    mysql --user=root --password=$vm_mysql_root_password < ./phpmyadmin/examples/create_tables.sql
    cp /vagrant/provision/templates/usr/share/phpmyadmin/config.inc.php /usr/share/phpmyadmin/config.inc.php
    sed -i "s/{{mysql_standard_user_username}}/$vm_mysql_standard_user_username/g" /usr/share/phpmyadmin/config.inc.php
    sed -i "s/{{mysql_standard_user_password}}/$vm_mysql_standard_user_password/g" /usr/share/phpmyadmin/config.inc.php
    cp /vagrant/provision/templates/etc/apache2/conf.d/phpmyadmin /etc/apache2/conf.d/phpmyadmin
    service apache2 restart
fi