#!/usr/bin/env bash

set -eo pipefail

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