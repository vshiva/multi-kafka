#!/bin/bash

props_file=$KAFKA_HOME/config/$1

$KAFKA_HOME/bin/config.py $props_file ${KAFKA_HOSTNAME:-"localhost"} ${KAFKA_TLS:-"PLAINTEXT"} ${JKS_PASSWD:-"na"}

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $props_file
