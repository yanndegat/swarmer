FROM java:8-alpine

ENV CONSUL_TEMPLATE_VERSION=0.14.0
ENV GRAYLOG_VERSION=1.3.4

RUN apk --update add bash wget

RUN mkdir /graylog

RUN wget -O /graylog/consul-template.zip https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip

RUN cd /graylog && unzip /graylog/consul-template.zip
RUN rm /graylog/*.zip

RUN wget -O /graylog/graylog.tgz https://packages.graylog2.org/releases/graylog2-web-interface/graylog-web-interface-${GRAYLOG_VERSION}.tgz
RUN cd /graylog && tar -xzf ./graylog.tgz && rm graylog.tgz

ADD ./entrypoint.sh /graylog/entrypoint.sh
ADD ./start-graylog.sh /graylog/start-graylog.sh

RUN ln -s /graylog/graylog-* /graylog/current

RUN chmod +x /graylog/*.sh

ENTRYPOINT ["/graylog/entrypoint.sh"]
