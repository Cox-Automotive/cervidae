#!/usr/bin/env bash

ELASTICSEARCH_VERSION="1.7.0"
LOGSTASH_VERSION="1.5.3"
KIBANA_VERSION="4.1.1"
PYTHON_VERSION="3.4.3"

ROOT=$(pwd)
MKDIR=$(which mkdir)
TAR=$(which tar)
WGET=$(which wget)

echo "Running pre-flight checklist"
echo "----------------------------"
echo "Determining architecture"
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
echo "Verifying Java"
java -version >&- 2>&-
if [[ $? -ne 0 ]]
then
	echo "    Java not found. Exiting!"
	exit
fi
echo "Complete"
echo

ELASTICSEARCH_SRC="https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz"
LOGSTASH_SRC="https://download.elastic.co/logstash/logstash/logstash-${LOGSTASH_VERSION}.tar.gz"
KIBANA_SRC="https://download.elastic.co/kibana/kibana/kibana-${KIBANA_VERSION}-linux-${ARCH}.tar.gz"
PYTHON_SRC="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"

# set up directories
echo "Setting up skeleton structure"
$MKDIR -p ${ROOT}/bin
$MKDIR -p ${ROOT}/etc/kibana
$MKDIR -p ${ROOT}/etc/logstash
$MKDIR -p ${ROOT}/etc/elasticsearch
$MKDIR -p ${ROOT}/lib
$MKDIR -p ${ROOT}/logs
$MKDIR -p ${ROOT}/share
$MKDIR -p ${ROOT}/tmp
$MKDIR -p ${ROOT}/var
$MKDIR -p ${ROOT}/packages
echo "Complete"
echo

# Download software
echo "Retrieving packages"
PACKAGE_ROOT="${ROOT}/packages"

$WGET -nc -P $PACKAGE_ROOT $ELASTICSEARCH_SRC
$WGET -nc -P $PACKAGE_ROOT $LOGSTASH_SRC
$WGET -nc -P $PACKAGE_ROOT $KIBANA_SRC
$WGET -nc -P $PACKAGE_ROOT $PYTHON_SRC
echo "Complete"
echo

# Extract
echo "Extracting packages"
ELASTICSEARCH_PKG_ROOT="${PACKAGE_ROOT}/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz"
LOGSTASH_PKG_ROOT="${PACKAGE_ROOT}/logstash-${LOGSTASH_VERSION}.tar.gz"
KIBANA_PKG_ROOT="${PACKAGE_ROOT}/kibana-${KIBANA_VERSION}-linux-${ARCH}.tar.gz"
PYTHON_PKG_ROOT="${PACKAGE_ROOT}/Python-${PYTHON_VERSION}.tgz"
$TAR -xzf $ELASTICSEARCH_PKG_ROOT -C $PACKAGE_ROOT		# Everyone uses GNU tar, right? Right???
$TAR -xzf $LOGSTASH_PKG_ROOT -C $PACKAGE_ROOT
$TAR -xzf $KIBANA_PKG_ROOT -C $PACKAGE_ROOT
$TAR -xzf $PYTHON_PKG_ROOT -C $PACKAGE_ROOT
echo "Complete"
echo


# Installing 
ELASTICSEARCH_PKG_SRC="${PACKAGE_ROOT}/elasticsearch-${ELASTICSEARCH_VERSION}"
LOGSTASH_PKG_SRC="${PACKAGE_ROOT}/logstash-${LOGSTASH_VERSION}"
KIBANA_PKG_SRC="${PACKAGE_ROOT}/kibana-${KIBANA_VERSION}-linux-${ARCH}"
PYTHON_PKG_SRC="${PACKAGE_ROOT}/Python-${PYTHON_VERSION}"

echo "Installing Elasticsearch"
cp -R $ELASTICSEARCH_PKG_SRC/bin/* ${ROOT}/bin
mv ${ROOT}/bin/plugin ${ROOT}/bin/elasticsearch-plugin
mv ${ROOT}/bin/plugin.bat ${ROOT}/bin/elasticsearch-plugin.bat
cp -R $ELASTICSEARCH_PKG_SRC/lib/* ${ROOT}/lib

echo "Installing Logstash"
cp -R $LOGSTASH_PKG_SRC/bin/* ${ROOT}/bin
mv ${ROOT}/bin/plugin ${ROOT}/bin/logstash-plugin
mv ${ROOT}/bin/plugin.bat ${ROOT}/bin/logstash-plugin.bat
cp -R $LOGSTASH_PKG_SRC/lib/* $ROOT/lib
cp -R $LOGSTASH_PKG_SRC/Gemfile* $ROOT/
cp -R $LOGSTASH_PKG_SRC/vendor $ROOT/

echo "Installing Kibana"
cp -R $KIBANA_PKG_SRC/bin/* $ROOT/bin
cp -R $KIBANA_PKG_SRC/node $ROOT/
cp -R $KIBANA_PKG_SRC/src $ROOT/

echo "Installing Python"
(cd $PYTHON_PKG_SRC && $PYTHON_PKG_SRC/configure -q --prefix=$ROOT --enable-shared) && make -C $PYTHON_PKG_SRC && make install -C $PYTHON_PKG_SRC
cd $ROOT

if [ ! -e "${ROOT}/bin/python" ]
then
	echo "Setting up symlinks"
	if [ -e "${ROOT}/bin/python3" ]			# python3 preferred
	then
		ln -s ${ROOT}/bin/python3 ${ROOT}/bin/python
	else if [ -e "${ROOT}/bin/python2" ]
	then
		ln -s ${ROOT}/bin/python2 ${ROOT}/bin/python
	else
		echo ""
		echo "                     WARNING                     "
		echo "The python binary could not be found, even though"
		echo "it has been installed. Check your installation."
		echo ""
	fi
fi
