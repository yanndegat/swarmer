FROM haproxy:alpine

ENV CONSUL_TEMPLATE_VERSION=0.14.0

RUN apk --update add bash curl

RUN curl --silent https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip > /run/consul-template.zip
RUN cd /run && unzip /run/consul-template.zip

ADD ./start.sh /run/start.sh
RUN chmod +x /run/start.sh

ENTRYPOINT ["/run/start.sh"]
