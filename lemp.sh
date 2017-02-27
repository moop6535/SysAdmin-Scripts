#!/bin/bash

# Copyright (C) 2017 Moop <mpaxmei@gmail.com>
# Permission to use, copy, modify, and distribute this software and
# its documentation for any purpose and without fee is hereby granted,
# without any conditions or restrictions. This software is provided
# "as is" without express or implied warranty.

#
# Lemp.sh -- Automated LEMP install for Ubuntu 
# Author: Moop
# Version: 1.0.0
# Note: Only designed for Ubuntu 14 & 16!
#


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
ORAN='\033[0;33m'
NC='\033[0m' # NO COLOR

#GET DISTRIBUTION AND RELEASE
DIST=`lsb_release -d | cut -d $'\t' -f2 | cut -d ' ' -f1`
RELEASE=`lsb_release -r | cut -d $'\t' -f2 | cut -d '.' -f1`

#UBUNTU + VERSION CHECK
if [ "$DIST" != "Ubuntu" ] || [ $RELEASE -lt 14 ]; then
    echo -e "${RED}Not Ubuntu -- or not a high enough version${NC}"
    exit
fi

#NOT SUSTAINABLE
CODENAME=`lsb_release -c | cut -d $'\t' -f2`

#PROMT FOR PHP VERSION IF ON 14.04
PHPVER=""
PHP=""
if [ "$CODENAME" == "xenial" ] || [ $RELEASE -gt 15 ]; then
    PHPVER=7
    PHP="php7.0"
else
    while [[ ! $PHPVER =~ ^[5|7]+$ ]]; do
        read -p $'\e[35mEnter PHP version [5|7]:\e[0m' PHPVER
    done
fi

if [ $PHPVER == 5 ]; then
    PHP="php5"
fi

#PROMPT FOR WEB DIRECTORY
while true; do

    read -p $'\e[35mEnter site name (example.org) or leave blank to skip:\e[0m ' SITE

    if [ "$SITE" == "none" ] || [ "$SITE" == "" ]; then
        read -p $'\e[32mYou have chosen to skip dir build. Is this correct \e[1;33m[y/N]:\e[0m ' BUILDCONF
    
        if [[ "$BUILDCONF" =~ ^[Yy]$ ]]; then
            break
        fi
    else
        echo -e "${GREEN}You have entered: ${ORAN}${SITE}${NC}" 
        read -p $'\e[32mIs this correct \e[1;33m[y/N]:\e[0m ' BUILDCONF
        if [[ "$BUILDCONF" =~ ^[Yy]$ ]]; then
            break
        fi
    fi
done

#PROMPT FOR MYSQL INSTALL AND PASSWORD
while true; do

    read -p $'\e[35mENTER SQL root Password or leave blank to skip:\e[0m ' SQLPASSWD

    if [ "$SQLPASSWD" == "nosql" ] || [ "$SQLPASSWD" == "" ]; then
         read -p $'\e[32mYou have chosen to skip mysql install. Is this correct \e[1;33m[y/N]:\e[0m ' MYSQLCONF
    
        if [[ "$MYSQLCONF" =~ ^[Yy]$ ]]; then
            break
        fi
    else
        echo -e "${GREEN}MySQL root Password: ${ORAN}${SQLPASSWD}${NC}" 
        read -p $'\e[32mIs this correct \e[1;33m[y/N]:\e[0m ' MYSQLCONF
        if [[ "$MYSQLCONF" =~ ^[Yy]$ ]]; then
            break
        fi
    fi
done

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' dialog|grep "install ok installed")
if [ "install ok installed" != "$PKG_OK" ]; then 
    apt-get -y install dialog
fi

#PREP & INSTALL NEWEST STABLE NGINX
NGINX_OK=$(dpkg-query -W --showformat='${Status}\n' nginx|grep "install ok installed")
if [ "install ok installed" != "$NGINX_OK" ]; then 
    wget http://nginx.org/keys/nginx_signing.key

    apt-key add nginx_signing.key

    if [ -z `grep "deb http://nginx.org/packages/ubuntu/" /etc/apt/sources.list` ]
    then
        echo "deb http://nginx.org/packages/ubuntu/ ${CODENAME} nginx" >> /etc/apt/sources.list
        echo "deb-src http://nginx.org/packages/ubuntu/ ${CODENAME} nginx" >> /etc/apt/sources.list
    fi
    apt-get update
    apt-get install nginx -y
    NGINX_INSTALLED=true
else
  echo -e "${ORAN}NGINX is already installed${NC}"
fi



#PREP PHP7 if selected and not on 16
if [ "$CODENAME" != "xenial" ] && [ $PHPVER -eq 7 ]; then
  add-apt-repository ppa:ondrej/php -y
fi

apt-get update

#APT-GET UPDATE && INSTALL
PHP_OK=$(dpkg-query -W --showformat='${Status}\n' "${PHP}"-fpm | grep "install ok installed")
if [ "install ok installed" != "$PHP_OK" ]; then
  apt-get install -y $PHP-fpm
  PHPFPM_INSTALLED=true
else
  echo -e "${ORAN}"${PHP}"-fpm is already installed${NC}"
fi

#SUPER BAD ASS AND COOL DIALOG PROMPT
cmd=(dialog --separate-output --keep-tite --checklist "Select options:" 22 76 5)
options=(1 "PHP-MySQL" on
         2 "PHP-GD" on
         3 "PHP-CURL" on
         4 "PHP-MCRYPT" on
         5 "PHP-DEV" off
)

choice=$("${cmd[@]}" "${options[@]}" 2>&1 > /dev/tty )

for answer in $choice
do
# DECISION TIME 
case $answer in
    1) 
       PHPMY_OK=$(dpkg-query -W --showformat='${Status}\n' "${PHP}"-mysql|grep "install ok installed")
       if [ "install ok installed" != "$PHPMY_OK" ]; then
          apt-get install -y $PHP-mysql
          PHPMYSQL_INSTALLED=true
       else
          echo -e "${ORAN}"${PHP}"-mysql is already installed${NC}"
       fi
       ;;
    2) 
       PHPGD_OK=$(dpkg-query -W --showformat='${Status}\n' "${PHP}"-gd|grep "install ok installed")
       if [ "install ok installed" != "$PHPGD_OK" ]; then
          apt-get install -y $PHP-gd
          PHPGD_INSTALLED=true
       else
          echo -e "${ORAN}"${PHP}"-gd is already installed${NC}"
       fi
       ;;
    3) 
       PHPCURL_OK=$(dpkg-query -W --showformat='${Status}\n' "${PHP}"-curl|grep "install ok installed")
       if [ "install ok installed" != "$PHPCURL_OK" ]; then
          apt-get install -y $PHP-curl
          PHPCURL_INSTALLED=true
       else
          echo -e "${ORAN}"${PHP}"-curl is already installed${NC}"
       fi
       ;;
    4) 
       PHPCRYPT_OK=$(dpkg-query -W --showformat='${Status}\n' "${PHP}"-mcrypt|grep "install ok installed")
       if [ "install ok installed" != "$PHPCRYPT_OK" ]; then
          apt-get install -y $PHP-mcrypt
          PHPMCRYPT_INSTALLED=true
       else
          echo -e "${ORAN}"${PHP}"-mcrypt is already installed${NC}"
       fi
       ;; 
    5) 
       PHPDEV_OK=$(dpkg-query -W --showformat='${Status}\n' "${PHP}"-dev|grep "install ok installed")
       if [ "install ok installed" != "$PHPDEV_OK" ]; then
          apt-get install -y $PHP-dev
          PHPDEV_INSTALLED=true
       else
          echo -e "${ORAN}"${PHP}"-dev is already installed${NC}"
       fi
       ;;
esac
done

#REMOVE DIALOG PACKAGE
apt-get remove --purge dialog -y

#MAKE WWW DIRECTORY
if [ "$SITE" != "none" ] || [ "$SITE" != "" ]; then
    mkdir -p /var/www/$SITE/htdocs
fi

if [ "$SQLPASSWD" != "nosql" ] || [ "$SQLPASSWD" != "" ]; then
    
    SQL_OK=$(dpkg-query -W --showformat='${Status}\n' mysql-server|grep "install ok installed")
       if [ "install ok installed" != "$SQL_OK" ]; then
            debconf-set-selections <<< "mysql-server mysql-server/root_password password ${SQLPASSWD}"
            debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${SQLPASSWD}"
            apt-get install -y mysql-server
            MYSQL_INSTALLED=true
       else
            echo -e "${ORAN}MYSQL is already installed${NC}"
            if [ "$SQLPASSWD" != "" ]; then
              echo -e "${GREEN}**********************${NC}"
              echo -e "${RED}MYSQL password did NOT change${NC}"
              echo -e "${GREEN}**********************${NC}"
            fi
       fi
fi

#PRINT OUT LIST OF WHAT WAS INSTALLED ON YOUR SYSTEM
echo
if [[ ! -z $MYSQL_INSTALLED || ! -z $PHPDEV_INSTALLED || ! -z $PHPGD_INSTALLED || ! -z $PHPMYSQL_INSTALLED || ! -z $PHPMCRYPT_INSTALLED || ! -z $PHPCURL_INSTALLED || ! -z $PHPFPM_INSTALLED || ! -z $NGINX_INSTALLED ]]; then
  echo -e "${GREEN}INSTALLED LIST:${NC}"
  if [[ ! -z $NGINX_INSTALLED ]]; then
    echo -e "${ORAN}NGINX Installed${NC}"
  fi
  if [[ ! -z $PHPFPM_INSTALLED ]]; then
    echo -e "${ORAN}"${PHP}"-fpm Installed${NC}"
  fi
  if [[ ! -z $PHPMYSQL_INSTALLED ]]; then
    echo -e "${ORAN}"${PHP}"-mysql Installed${NC}"
  fi
  if [[ ! -z $PHPGD_INSTALLED ]]; then
    echo -e "${ORAN}"${PHP}"-gd Installed${NC}"
  fi
  if [[ ! -z $PHPCURL_INSTALLED ]]; then
    echo -e "${ORAN}"${PHP}"-curl Installed${NC}"
  fi
  if [[ ! -z $PHPMCRYPT_INSTALLED ]]; then
    echo -e "${ORAN}"${PHP}"-mcrypt Installed${NC}"
  fi
  if [[ ! -z $PHPDEV_INSTALLED ]]; then
    echo -e "${ORAN}"${PHP}"-dev Installed${NC}"
  fi
  if [[ ! -z $MYSQL_INSTALLED ]]; then
    echo -e "${ORAN}MySql-Server Installed${NC}"
  fi
fi

#FINAL LEAVINGS
echo
echo -e "${RED}Don't forget to:${NC}"
echo
echo -e "${GREEN}Install and configure unattended-upgrades:${NC}"
if [ "$CODENAME" == "xenial" ]; then
  echo -e "${ORAN}https://help.ubuntu.com/lts/serverguide/automatic-updates.html${NC}"
else
  echo -e "${ORAN}dpkg-reconfigure --priority=low unattended-upgrades${NC}"
fi
echo
echo -e "${GREEN}And secure MySQL:${NC}"
echo -e "${ORAN}mysql_secure_installation${NC}"
echo
