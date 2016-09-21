#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DATE=`date +%Y%m%d`

cd $DIR

cd windup-web
git pull
if [ $? != 0 ]; then
	echo "Git pull failed"
	exit 1
fi
mvn clean
if [ $? != 0 ]; then
	echo "Maven clean failed"
	exit 1
fi
mvn install -DskipTests
if [ $?	!= 0 ];	then
        echo "Maven build failed"
        exit 1
fi
cd ..
rm -rf image/keycloak*
rm -rf image/META-INF
rm -rf image/wildfly*
unzip -d image/ windup-web/tests/wildfly-dist/target/windup-web-tests-wildfly-dist-*-SNAPSHOT.jar
if [ $?	!= 0 ];	then
        echo "Wildfly unzip failed"
        exit 1
fi

mv image/wildfly-*.Final image/wildfly
if [ $?	!= 0 ];	then
        echo "Wildfly copy failed"
        exit 1
fi

# Copy services
cp -R windup-web/services/target/windup-web-services image/wildfly/standalone/deployments/windup-web-services.war
if [ $?	!= 0 ];	then
        echo "Windup Web Services Copy failed"
        exit 1
fi
touch image/wildfly/standalone/deployments/windup-web-services.war.dodeploy

# Copy UI
cp -R windup-web/ui/target/windup-web image/wildfly/standalone/deployments/windup-web.war
if [ $?	!= 0 ];	then
        echo "Windup Web UI Copy failed"
        exit 1
fi
touch image/wildfly/standalone/deployments/windup-web.war.dodeploy

cd image
docker build -t=docker.io/windup3/windup-web_nightly .
if [ $?	!= 0 ];	then
        echo "Docker build failed"
        exit 1
fi
docker push docker.io/windup3/windup-web_nightly
if [ $?	!= 0 ];	then
        echo "Docker push failed"
        exit 1
fi
