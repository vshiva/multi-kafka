#!/bin/bash

_jks_passwd="na"
_protocol="PLAINTEXT"

TLS_KEY="${TLS_KEY:-/etc/kafka/certs/tls.key}"
TLS_CERT="${TLS_CERT:-/etc/kafka/certs/tls.crt}"
TLS_CA_CERT="${TLS_CA_CERT:-/etc/kafka/certs/ca.crt}"
TLS_CLIENT_CA_CERT="${TLS_CLIENT_CA_CERT:-/etc/kafka/certs/client-ca.crt}"

if [ "$ENABLE_TLS" == "true" ]; then

    _jks_passwd=`openssl rand -base64 6`
    _jks_dir=/etc/kafka/jks
    _tmpdir=$(mktemp -d)
    _protocol="SSL"
    rm -rf ${_jks_dir}

    if [[ -f "$TLS_KEY" && -f "$TLS_KEY" && -f "$TLS_CA_CERT" ]]; then

        # Export TLS certs in PKCS12 format
        openssl pkcs12 -export -name "kafka" -password pass:${_jks_passwd} \
            -inkey ${TLS_KEY} -in ${TLS_CERT} \
            -CAfile ${TLS_CA_CERT} -caname "kafka-ca" \
            -out ${_tmpdir}/kafka-tls.p12

        # server keystore
        mkdir -p ${_jks_dir}
        keytool -importkeystore -srckeystore ${_tmpdir}/kafka-tls.p12 -srcstoretype PKCS12 -srcstorepass ${_jks_passwd} \
            -deststorepass ${_jks_passwd} -destkeypass ${_jks_passwd} -destkeystore ${_jks_dir}/server-keystore.jks \
            -alias "kafka"

        if [[ -f "$TLS_CLIENT_CA_CERT" ]]; then
            # server truststore - trust only clients signed by this CA
            keytool -keystore ${_jks_dir}/server-truststore.jks \
                -alias "kafka-client-ca" -import -file ${TLS_CLIENT_CA_CERT} \
                -storepass ${_jks_passwd} -noprompt
        fi

        rm -rf ${_tmpdir}
    fi
fi

props_file=$KAFKA_HOME/config/$1

$KAFKA_HOME/bin/config.py $props_file ${KAFKA_HOSTNAME:-"localhost"} ${_protocol} ${_jks_passwd}

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $props_file
