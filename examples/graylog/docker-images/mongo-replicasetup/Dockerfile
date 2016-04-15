FROM mongo:3

ADD ./wait-for-it.sh /wait-for-it.sh
ADD ./replicaset-setup.sh /replicaset-setup.sh

RUN chmod +x /*.sh

ENTRYPOINT ["/replicaset-setup.sh"]
