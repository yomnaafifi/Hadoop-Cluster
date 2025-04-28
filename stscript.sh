#!/bin/bash

sudo service ssh restart

if [[ "${HOSTNAME}" == *"master"* ]]; then
    NODE_ID="${HOSTNAME//[^0-9]/}"
    echo "${NODE_ID}" > /usr/local/zookeeper/data/myid

    NAMENODE_DIR="/usr/local/hadoop/hdfs/namenode"

    if [ -z "$(ls -A ${NAMENODE_DIR})" ]; then
        # Starting ZooKeeper on 3 masters
        zkServer.sh start

        if [ "${NODE_ID}" == "1" ]; then
            hdfs zkfc -formatZK
            start-all.sh 

            hdfs namenode -format -force
            hdfs --daemon start namenode
            
        else
            sleep 120
            hdfs namenode -bootstrapStandby -force
            hdfs --daemon start namenode
        fi
    else
        zkServer.sh start
        start-all.sh
    fi
else
    start-all.sh
fi

tail -f /dev/null
