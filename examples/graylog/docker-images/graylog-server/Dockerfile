FROM java:8-alpine

RUN apk --update add bash

ADD ./graylog-server.tgz /graylog
ADD ./start.sh /graylog/start.sh
ADD ./wait-for-it.sh /graylog/wait-for-it.sh

RUN ln -s /graylog/graylog-* /graylog/current

RUN chmod +x /graylog/start.sh
RUN chmod +x /graylog/wait-for-it.sh

ENTRYPOINT ["/graylog/start.sh"]
