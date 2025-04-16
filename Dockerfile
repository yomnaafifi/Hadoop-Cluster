FROM ubuntu:22.04

RUN apt update -y && apt upgrade -y
RUN apt install -y openjdk-8-jdk
RUN apt install -y ssh
RUN apt install -y sudo
RUN apt install -y nano 

RUN mv  /usr/lib/jvm/java-8-openjdk-amd64/ /usr/lib/jvm/java

#dont know where to put this line
# Set JAVA_HOME and update PATH in bashrc
ENV JAVA_HOME=/usr/lib/jvm/java
ENV PATH=$PATH:$JAVA_HOME/bin


RUN groupadd hadoop 
RUN adduser --disabled-password --ingroup hadoop hduser
RUN echo "hduser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


ADD https://archive.apache.org/dist/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz /usr/local
RUN tar -xzf /usr/local/hadoop-3.3.6.tar.gz -C /usr/local
RUN mv /usr/local/hadoop-3.3.6 /usr/local/hadoop
RUN chown -R hduser:hadoop /usr/local/hadoop
RUN chmod -R 755 /usr/local/hadoop

#create the files for hdfs (tmp,hdfs,namenode, datanode)
RUN mkdir -p /usr/local/hadoop/hdfs/namenode && \
    mkdir -p /usr/local/hadoop/hdfs/datanode && \
    mkdir -p /usr/local/hadoop/hdfs/journals && \
    mkdir -p /usr/local/hadoop/tmp && \
    chown -R hduser:hadoop /usr/local/hadoop/hdfs/namenode && \
    chown -R hduser:hadoop /usr/local/hadoop/hdfs/datanode && \
    chown -R hduser:hadoop /usr/local/hadoop/hdfs/journals && \
    chown -R hduser:hadoop /usr/local/hadoop/tmp && \
    chmod -R 777 /usr/local/hadoop/hdfs/namenode && \
    chmod -R 777 /usr/local/hadoop/hdfs/datanode && \
    chmod -R 777 /usr/local/hadoop/hdfs/journals && \
    chmod -R 777 /usr/local/hadoop/tmp 

ADD https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz /usr/local
RUN tar -xzf /usr/local/apache-zookeeper-3.8.4-bin.tar.gz -C /usr/local
RUN mv /usr/local/apache-zookeeper-3.8.4-bin /usr/local/zookeeper
RUN chown -R hduser:hadoop /usr/local/zookeeper
RUN chmod -R 755 /usr/local/zookeeper

RUN mkdir -p /usr/local/zookeeper/data 
RUN chown -R hduser:hadoop /usr/local/zookeeper/data
RUN chmod -R 777 /usr/local/zookeeper/data
RUN touch /usr/local/zookeeper/data/myid
RUN chmod -R 777 /usr/local/zookeeper/data/myid

RUN mkdir -p /usr/local/shared_data
RUN chown -R hduser:hadoop /usr/local/shared_data
RUN chmod -R 777 /usr/local/shared_data

# this for bashrc and not hadoop.env, hadoop.env should be written manually
ENV HADOOP_HOME /usr/local/hadoop
ENV PATH=$PATH:/usr/local/hadoop/bin
ENV PATH=$PATH:/usr/local/hadoop/sbin

ENV PATH=$PATH:/usr/local/zookeeper/bin 

#RUN echo "hduser:123" | chpasswd

USER hduser
WORKDIR /home/hduser
RUN ssh-keygen -t rsa -P "" -f /home/hduser/.ssh/id_rsa
RUN cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys
RUN chmod 600 /home/hduser/.ssh/authorized_keys


COPY sshd_config /etc/ssh/sshd_config
COPY hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh
COPY yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
COPY core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
COPY hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
COPY stscript.sh /home/hduser/
COPY zoo.cfg /usr/local/zookeeper/conf/zoo.cfg
COPY workers /usr/local/hadoop/etc/hadoop/workers
RUN sudo chmod +x /home/hduser/stscript.sh


ENTRYPOINT [ "./stscript.sh" ]

