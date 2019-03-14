#!/bin/bash

DIR=`dirname $0`
DIR="$(cd $DIR; pwd)"

ARCH=`uname -m`
SVCID="v2ray"
CTNNAME="proxy-$SVCID"
IMGNAME="samuelhbne/proxy-$SVCID"

case $ARCH in
	armv6l|armv7l)
		TARGET=arm
		;;
	x86_64|i686|i386)
		TARGET=amd64
		;;
	aarch64)
		TARGET=arm64
		;;
	*)
		echo "Unsupported arch"
		exit
		;;
esac

DOCKERVER=`docker --version|awk '{print $3}'`
DKVERMAJOR=`echo $DOCKERVER|cut -d. -f1`
DKVERMINOR=`echo $DOCKERVER|cut -d. -f2`
if (("$DKVERMAJOR" < 17)) || ( (("$DKVERMAJOR" == 17)) && (("$DKVERMINOR" < 05 )) ); then
	TARGET=$TARGET"1s"
fi

while [[ $# > 0 ]]; do
	case $1 in
		--from-src)
			echo "Building local proxy image..."
			docker build -t $IMGNAME:$TARGET -f $DIR/Dockerfile.$TARGET $DIR
			echo "Done."
			echo
			break
			;;
		*)
			shift
			;;
	esac
done

. $DIR/server-$SVCID.env
. $DIR/proxy-$SVCID.env.out

if [ -z "$VHOST" ] || [ -z "$V2RAYPORT" ] || [ -z "$V2RAYUUID" ]; then
	echo "V2ray service not found."
	echo "Abort."
	exit 1
fi

if [ `docker ps -a| grep $CTNNAME|wc -l` -gt 0 ]; then
        docker stop $CTNNAME >/dev/null
	docker rm $CTNNAME >/dev/null
fi

echo "Starting up local proxy daemon..."
docker run --name $CTNNAME -p $SOCKSPORT:1080 -p $DNSPORT:53/udp -p $HTTPPORT:8123 -d $IMGNAME:$TARGET -h ${VHOST} -p ${V2RAYPORT} -u ${V2RAYUUID} -v ${V2RAYLEVEL} -a ${V2RAYAID} -s ${V2RSYSECURITY} -l ${LSTNADDR} -k 1080 >/dev/null
echo "Done."
echo
