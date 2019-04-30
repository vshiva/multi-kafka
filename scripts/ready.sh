#!/usr/bin/env bash

set -eo pipefail

create_topic() {
  zkroot="$1"; shift
  topic="$1"; shift
  partitions="$1"; shift
  repl="$1"; shift
  
  echo zkhost=$zkhost zkroot=$zkroot topic=$topic partitions=$partitions replfactor=$repl

  kafka-topics.sh \
    --create --if-not-exists \
    --zookeeper $zkhost:2181/$zkroot \
    --replication-factor $repl \
    --partitions $partitions \
    --topic $topic "$@"
}

create_default_topics() {
  # one or more topics which are comma seperated in the format
  # zkroot1:topic1:partitions:replication,zkroot2:topic2:partitions:replication
  topics="$1"

  for i in $(echo $topics | sed "s/,/ /g")
  do
      local _a=($(echo "$i" | tr ':' '\n'))
      create_topic ${_a[0]} ${_a[1]} ${_a[2]} ${_a[3]}
  done
}

check_tries() {
  local max_tries=60
  if [ ${1} -ge ${max_tries} ]; then
    fail 'Max tries reached'
  fi
}

zookeeper_shell() {
  local zkhost=${1?}
  local zk_shell="zookeeper-shell.sh"

  echo ls /one/brokers/ids | ${zk_shell} ${zkhost}:2181 | tail -n 1
}

await_zookeeper() {
  local zkhost=${1:?}
  if which nc > /dev/null 2>&1; then
    tries=0
    while true; do
      tries=$((tries + 1))
      check_tries ${tries}

      echo "Waiting for Zookeeper (${tries})"
      if [ "$(echo 'ruok' | nc ${zkhost} 2181)" = "imok" ]; then
          echo "Zookeeper up"
          break
      fi
      sleep 1
    done
  else
    wait_for_it ${zkhost}:2181
  fi
}

await_kafka_up() {
  local zkhost=${1:?}
  for b in one two; do
    tries=0
    while true; do
      tries=$((tries + 1))
      check_tries ${tries}

      echo "Waiting for Kafka broker ${b} (${tries})"
      ids=$(zookeeper_shell ${zkhost})
      if [ "${ids}" = "[1]" ]; then
        echo "Kafka broker ${b} up"
        break
      fi
      sleep 1
    done
  done
}

wait_for_it() {
  $(dirname $0)/wait-for-it "$@"
}

zkhost=${1:-localhost}
await_zookeeper ${zkhost}
await_kafka_up ${zkhost}

create_default_topics $DEFAULT_TOPICS