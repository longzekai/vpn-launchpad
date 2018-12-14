#!/bin/sh

DIR=`dirname $0`
DIR="$(cd $DIR; pwd)"

ARCH=`uname -m`
IMGNAME="samuelhbne/proxy-ssllibev"
CTNNAME="proxy-ssllibev"

. $DIR/ssslibev.env
. $DIR/proxy-ssllibev.env.out

case $ARCH in
	armv6l|armv7l)
		TARGET=arm
		;;
	x86_64|i686|i386)
		TARGET=amd64
		;;
	*)
		echo "Unsupported arch"
		exit
		;;
esac
echo "Building local proxy image..."
docker build -t $IMGNAME:$TARGET -f $DIR/Dockerfile.$TARGET $DIR
echo "Done."
echo

BEXIST=`docker ps -a| grep $CTNNAME|wc -l`
if [ $BEXIST -gt 0 ]; then
        docker stop $CTNNAME >/dev/null
	docker rm $CTNNAME >/dev/null
fi

echo "Starting up local proxy daemon..."
docker run --name $CTNNAME -p $SOCKSPORT:1080 -p $DNSPORT:53/udp -p $HTTPPORT:8123 -d $IMGNAME:$TARGET -s ${SSHOST} -p ${SSPORT} -b ${LISTENADDR} -l ${SOCKSPORT} -k "${SSPASS}" -m "${SSMTHD}" >/dev/null
echo "Done."
echo
