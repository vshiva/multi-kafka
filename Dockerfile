# Kafka and Zookeeper

FROM java:openjdk-8-jre

ENV DEBIAN_FRONTEND noninteractive
ENV SCALA_VERSION 2.11
ENV KAFKA_VERSION 2.2.0
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"
ENV PATH "$PATH:$KAFKA_HOME/bin"

RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
# As suggested by a user, for some people this line works instead of the first one. Use whichever works for your case
# RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list
RUN sed -i '/deb http:\/\/deb.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list
RUN apt-get -o Acquire::Check-Valid-Until=false update

# Install Kafka, Zookeeper and other needed things
RUN apt-get install -y zookeeper wget supervisor dnsutils && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    wget -q http://apache.mirrors.spacedump.net/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

ADD scripts/start-kafka.sh /usr/bin/start-kafka.sh
ADD scripts/ready.sh /usr/bin/ready-kafka.sh
ADD scripts/wait-for-it /usr/bin/wait-for-it
ADD scripts/config.py $KAFKA_HOME/bin

# Supervisor config
ADD supervisor/kafka.conf supervisor/kafka2.conf supervisor/zookeeper.conf /etc/supervisor/conf.d/

ADD config/server.properties.template config/server2.properties.template $KAFKA_HOME/config/

# 2181 is zookeeper, 9092 is kafka 9192 is kafka2
EXPOSE 2181 9092 9192

CMD ["supervisord", "-n"]
