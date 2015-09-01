#!/usr/bin/env bash

APPLICATION="myapp"

if [ -n "$1" ]
then
    APPLICATION="$1"
fi

ELASTICSEARCH_VERSION="1.7.0"
LOGSTASH_VERSION="1.5.3"
KIBANA_VERSION="4.1.1"
PYTHON_VERSION="3.4.3"

ROOT=$(pwd)
MKDIR=$(which mkdir)
TAR=$(which tar)
WGET=$(which wget)
HN=$(hostname)
SED=$(which sed)

PACKAGE_ROOT="$ROOT/packages"

preflight_checklist()
{
    echo "Running pre-flight checklist"
    echo "  Determining architecture"
    case $(uname -m) in
    x86_64)
        ARCH="x64"
        ;;
    i*86)
        ARCH="x86"
        ;;
    *)
        echo "    Unrecognizable architecture. Exiting!"
        exit
        ;;
    esac
    echo "    $ARCH"
    echo "  Verifying Java"
    java -version >&- 2>&-		# Fun fact: ```java -version``` prints to stderr
    if [[ $? -ne 0 ]]
    then
        echo "    Java not found. Exiting!"
        exit
    fi

    ELASTICSEARCH_SRC="https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz"
    LOGSTASH_SRC="https://download.elastic.co/logstash/logstash/logstash-${LOGSTASH_VERSION}.tar.gz"
    KIBANA_SRC="https://download.elastic.co/kibana/kibana/kibana-${KIBANA_VERSION}-linux-${ARCH}.tar.gz"
    PYTHON_SRC="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
    ELASTICSEARCH_PKG_SRC="${PACKAGE_ROOT}/elasticsearch-${ELASTICSEARCH_VERSION}"
    LOGSTASH_PKG_SRC="${PACKAGE_ROOT}/logstash-${LOGSTASH_VERSION}"
    KIBANA_PKG_SRC="${PACKAGE_ROOT}/kibana-${KIBANA_VERSION}-linux-${ARCH}"
    PYTHON_PKG_SRC="${PACKAGE_ROOT}/Python-${PYTHON_VERSION}"

    echo "  Complete"
    echo
}

setup_directories()
{
    echo "Setting up skeleton structure"
    $MKDIR -p $ROOT/bin
    $MKDIR -p $ROOT/etc/kibana/conf
    $MKDIR -p $ROOT/etc/kibana/plugins
    $MKDIR -p $ROOT/etc/logstash/conf
    $MKDIR -p $ROOT/etc/logstash/patterns
    $MKDIR -p $ROOT/etc/elasticsearch/conf
    $MKDIR -p $ROOT/etc/elasticsearch/plugins
    $MKDIR -p $ROOT/lib
    $MKDIR -p $ROOT/logs
    $MKDIR -p $ROOT/share
    $MKDIR -p $ROOT/tmp
    $MKDIR -p $ROOT/var/run
    $MKDIR -p $ROOT/packages
    echo "  Complete"
    echo
}

download_packages()
{
    echo "Retrieving packages"
    $WGET --no-check-certificate -nc -P $PACKAGE_ROOT $ELASTICSEARCH_SRC
    $WGET --no-check-certificate -nc -P $PACKAGE_ROOT $LOGSTASH_SRC
    $WGET --no-check-certificate -nc -P $PACKAGE_ROOT $KIBANA_SRC
    $WGET --no-check-certificate -nc -P $PACKAGE_ROOT $PYTHON_SRC
    echo "  Complete"
    echo
}

extract_packages()
{
    echo "Extracting packages"
    ELASTICSEARCH_PKG_ROOT="${PACKAGE_ROOT}/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz"
    LOGSTASH_PKG_ROOT="${PACKAGE_ROOT}/logstash-${LOGSTASH_VERSION}.tar.gz"
    KIBANA_PKG_ROOT="${PACKAGE_ROOT}/kibana-${KIBANA_VERSION}-linux-${ARCH}.tar.gz"
    PYTHON_PKG_ROOT="${PACKAGE_ROOT}/Python-${PYTHON_VERSION}.tgz"
    $TAR -xzf $ELASTICSEARCH_PKG_ROOT -C $PACKAGE_ROOT
    $TAR -xzf $LOGSTASH_PKG_ROOT -C $PACKAGE_ROOT
    $TAR -xzf $KIBANA_PKG_ROOT -C $PACKAGE_ROOT
    $TAR -xzf $PYTHON_PKG_ROOT -C $PACKAGE_ROOT
    echo "  Complete"
    echo
}

install_packages()
{
    echo "Installing Elasticsearch"
    cp -R $ELASTICSEARCH_PKG_SRC/bin/* ${ROOT}/bin
    mv ${ROOT}/bin/plugin ${ROOT}/bin/elasticsearch-plugin
    mv ${ROOT}/bin/plugin.bat ${ROOT}/bin/elasticsearch-plugin.bat
    cp -R $ELASTICSEARCH_PKG_SRC/lib/* ${ROOT}/lib
    
    echo "Installing Logstash"
    cp -R $LOGSTASH_PKG_SRC/bin/* $ROOT/bin
    mv ${ROOT}/bin/plugin $ROOT/bin/logstash-plugin
    mv ${ROOT}/bin/plugin.bat $ROOT/bin/logstash-plugin.bat
    cp -R $LOGSTASH_PKG_SRC/lib/* $ROOT/lib
    cp -R $LOGSTASH_PKG_SRC/Gemfile* $ROOT/
    cp -R $LOGSTASH_PKG_SRC/vendor $ROOT/
    
    echo "Installing Kibana"
    cp -R $KIBANA_PKG_SRC/bin/* $ROOT/bin
    cp -R $KIBANA_PKG_SRC/node $ROOT/
    cp -R $KIBANA_PKG_SRC/src $ROOT/
    
    echo "Installing Python"
    (cd $PYTHON_PKG_SRC && $PYTHON_PKG_SRC/configure -q --prefix=$ROOT --enable-shared) && make -s -C $PYTHON_PKG_SRC && make install -s -C $PYTHON_PKG_SRC
    cd $ROOT
    
    if [ ! -e "${ROOT}/bin/python" ]; then
        echo "Setting up symlinks"
        if [ -e "${ROOT}/bin/python3" ]; then            # python3 preferred
            echo "  Linking python3"
            ln -s ${ROOT}/bin/python3 ${ROOT}/bin/python
        elif [ -e "${ROOT}/bin/python2" ]; then
            echo "  Linking python2"
            ln -s ${ROOT}/bin/python2 ${ROOT}/bin/python
        else
            echo ""
            echo "                     WARNING                     "
            echo "The python binary could not be found, even though"
            echo "it has been installed. Check your installation."
            echo ""
        fi
    fi
    echo
    echo "If you get errors about libpython files not being found when starting Python, add $ROOT/lib to your LD_LIBRARY_PATH."
    echo " i.e.: export LD_LIBRARY_PATH=$ROOT/lib:\$LD_LIBRARY_PATH"
    echo
    echo "  Complete"
    echo
}

add_customizations()
{
    echo "Adding customizations."
    # logstash confs
    $WGET --no-check-certificate -O $ROOT/etc/logstash/conf/in.conf https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/in.conf
    $WGET --no-check-certificate -O $ROOT/etc/logstash/conf/filter.conf https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/filter.conf
    $WGET --no-check-certificate -O $ROOT/etc/logstash/conf/out.conf https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/out.conf
    
    $SED -i "s|\\\$\\\$APP\\\$\\\$|$APPLICATION|g" $ROOT/etc/logstash/conf/in.conf 
    $SED -i "s|\\\$\\\$HOSTNAME\\\$\\\$|$HN|g" $ROOT/etc/logstash/conf/in.conf 
    $SED -i "s|\\\$\\\$APP\\\$\\\$|$APPLICATION|g" $ROOT/etc/logstash/conf/filter.conf 
    $SED -i "s|\\\$\\\$ROOTDIR\\\$\\\$|$ROOT|g" $ROOT/etc/logstash/conf/filter.conf 
    $SED -i "s|\\\$\\\$HOSTNAME\\\$\\\$|$HN|g" $ROOT/etc/logstash/conf/out.conf 
    
    # logstash pattern
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/apache https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/apache
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/firewalls https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/apache
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/grok-patterns https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/apache
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/haproxy https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/haproxy
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/java https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/java
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/junos https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/junos
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/linux-syslog https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/linux-syslog
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/mcollective https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/mcollective
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/mcollective-patterns https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/mcollective-patterns
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/mongodb https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/mongodb
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/nagios https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/nagios
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/postgresql https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/postgresql
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/redis https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/redis
    $WGET --no-check-certificate -O $ROOT/etc/logstash/patterns/ruby https://raw.githubusercontent.com/andrew-sledge/cervidae/master/logstash_confs/patterns/ruby
    
    # es conf - and logging
    $WGET --no-check-certificate -O $ROOT/etc/elasticsearch/conf/elasticsearch.yml https://raw.githubusercontent.com/andrew-sledge/cervidae/master/elasticsearch_confs/elasticsearch.yml
    $WGET --no-check-certificate -O $ROOT/etc/elasticsearch/conf/logging.yml https://raw.githubusercontent.com/andrew-sledge/cervidae/master/elasticsearch_confs/logging.yml
    
    $SED -i "s|\\\$\\\$ROOTDIR\\\$\\\$|$ROOT|g" $ROOT/etc/elasticsearch/conf/elasticsearch.yml
    $SED -i "s|\\\$\\\$HOSTNAME\\\$\\\$|$HN|g" $ROOT/etc/elasticsearch/conf/elasticsearch.yml
    
    # kibana conf
    $WGET --no-check-certificate -O $ROOT/etc/kibana/conf/kibana.yml https://raw.githubusercontent.com/andrew-sledge/cervidae/master/kibana_confs/kibana.yml
    $SED -i "s|\\\$\\\$HOSTNAME\\\$\\\$|$HN|g" $ROOT/etc/kibana/conf/kibana.yml
    
    # helper files
    $WGET --no-check-certificate -O $ROOT/bin/es https://raw.githubusercontent.com/andrew-sledge/cervidae/master/helpers/es
    $WGET --no-check-certificate -O $ROOT/bin/es-reboot https://raw.githubusercontent.com/andrew-sledge/cervidae/master/helpers/es-reboot
    $SED -i "s|\\\$\\\$ROOTDIR\\\$\\\$|$ROOT|g" $ROOT/bin/es
    $SED -i "s|\\\$\\\$ROOTDIR\\\$\\\$|$ROOT|g" $ROOT/bin/es-reboot
    chmod 0755 $ROOT/bin/es
    chmod 0755 $ROOT/bin/es-reboot
    
    $WGET --no-check-certificate -O $ROOT/bin/ls https://raw.githubusercontent.com/andrew-sledge/cervidae/master/helpers/ls
    $WGET --no-check-certificate -O $ROOT/bin/ls-reboot https://raw.githubusercontent.com/andrew-sledge/cervidae/master/helpers/ls-reboot
    $SED -i "s|\\\$\\\$ROOTDIR\\\$\\\$|$ROOT|g" $ROOT/bin/ls
    $SED -i "s|\\\$\\\$ROOTDIR\\\$\\\$|$ROOT|g" $ROOT/bin/ls-reboot
    chmod 0755 $ROOT/bin/ls
    chmod 0755 $ROOT/bin/ls-reboot
    
    $WGET --no-check-certificate -O $ROOT/bin/k https://raw.githubusercontent.com/andrew-sledge/cervidae/master/helpers/k
    $WGET --no-check-certificate -O $ROOT/bin/k-reboot https://raw.githubusercontent.com/andrew-sledge/cervidae/master/helpers/k-reboot
    $SED -i "s|\\\$\\\$ROOTDIR\\\$\\\$|$ROOT|g" $ROOT/bin/k
    $SED -i "s|\\\$\\\$ROOTDIR\\\$\\\$|$ROOT|g" $ROOT/bin/k-reboot
    chmod 0755 $ROOT/bin/k
    chmod 0755 $ROOT/bin/k-reboot
    
    $WGET --no-check-certificate -O $ROOT/bin/elk https://raw.githubusercontent.com/andrew-sledge/cervidae/master/helpers/elk
    $SED -i "s|\\\$\\\$ROOTDIR\\\$\\\$|$ROOT|g" $ROOT/bin/elk
    chmod 0755 $ROOT/bin/elk
    
    export PATH=$ROOT/bin:$PATH
    echo "  Complete"
    echo
}


######### Line -15. Yes, it's a stupid hack. Do not add additional lines. Modify in
######### place. If you _have_ to add lines update the Makefile for testing. If you 
######### are not running tests you can safely ignore this jibber-jabber.



preflight_checklist
setup_directories
download_packages
extract_packages
install_packages
add_customizations

echo "Installation is now complete."
echo "Start the stack with ./bin/elk start"
