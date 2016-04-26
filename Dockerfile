FROM docker:1.10

ENV TERRAFORM_VERSION 0.6.14
ENV PACKER_VERSION 0.10.0

#update
RUN set -ex \
    && apk update \
    && apk add --no-cache --virtual .fetch-deps curl gnupg git openssh-client py-pip jq make bash gpgme \
    && pip install docker-compose awscli \
    && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
&& unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip packer_${PACKER_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && mkdir $HOME/.gnupg \
    && echo "pinentry-program /usr/bin/pinentry-tty" > $HOME/.gnupg/gpg-agent.conf \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip packer_${PACKER_VERSION}_linux_amd64.zip \
    /usr/local/bin/terraform-provider-atlas \
    /usr/local/bin/terraform-provider-azure \
    /usr/local/bin/terraform-provider-azurerm \
    /usr/local/bin/terraform-provider-chef \
    /usr/local/bin/terraform-provider-cloudflare \
    /usr/local/bin/terraform-provider-cloudstack \
    /usr/local/bin/terraform-provider-consul \
    /usr/local/bin/terraform-provider-digitalocean \
    /usr/local/bin/terraform-provider-dme \
    /usr/local/bin/terraform-provider-dnsimple \
    /usr/local/bin/terraform-provider-docker \
    /usr/local/bin/terraform-provider-dyn \
    /usr/local/bin/terraform-provider-google \
    /usr/local/bin/terraform-provider-heroku \
    /usr/local/bin/terraform-provider-mailgun \
    /usr/local/bin/terraform-provider-mysql \
    /usr/local/bin/terraform-provider-openstack \
    /usr/local/bin/terraform-provider-packet \
    /usr/local/bin/terraform-provider-postgresql \
    /usr/local/bin/terraform-provider-powerdns \
    /usr/local/bin/terraform-provider-rundeck \
    /usr/local/bin/terraform-provider-statuscake \
    /usr/local/bin/terraform-provider-template \
    /usr/local/bin/terraform-provider-tls \
    /usr/local/bin/terraform-provider-vcd \
    /usr/local/bin/terraform-provider-vsphere \
    /usr/local/bin/terraform-provisioner-chef

RUN ln -s /usr/local/bin/packer /usr/local/bin/packer-io

ENV AWS_ACCESS_KEY_ID "your aws access key"
ENV AWS_SECRET_ACCESS_KEY "your aws secret access key"
ENV AWS_DEFAULT_REGION "your aws default region"
ENV STACK_NAME "The Name of your stack"
ENV AWS_ACCOUNT "The ID of your AWS Account"
ENV KEYPAIR_PASSPHRASE "The passphrase of your keypair"

ADD . /src
WORKDIR /src

ENTRYPOINT ["/bin/bash"]
