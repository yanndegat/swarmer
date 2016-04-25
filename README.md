<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#orgheadline1">1. Description</a></li>
<li><a href="#orgheadline2">2. Pre-Requisites</a></li>
<li><a href="#orgheadline3">3. Quickstart</a></li>
<li><a href="#orgheadline4">4. Getting Started on AWS</a></li>
<li><a href="#orgheadline12">5. Play with your swarm cluster</a></li>
<li><a href="#orgheadline22">6. Considerations &amp; Roadmap</a></li>
</ul>
</div>
</div>

Note: you may prefer reading the [README.html](README.html) file in your browser. 

# Description<a id="orgheadline1"></a>

Swarmer is an open source project to help people deploying proper configured docker swarm clusters on AWS.

You'll find other and simpler tutorials or github projects to deploy swarm on AWS, but if you don't want your cluster to be exposed on public facing IPs, you'll then have to get your hands dirty on a lot of other things. 

This project tries to compile a lot of resources to get a swarm cluster up and running on a private aws cloud.

Swarmer is built on top of the following components:

-   [Terraform](https://www.terraform.io/) for provisioning the infrastructure
-   [Packer](http://packer.io/) for building the boxes for various providers (Virtualbox, AWS, Kvm, &#x2026;)
-   [Consul](http://consul.io) for service discovery, DNS
-   [Docker](http://docker.io) for application container runtimes, of course
-   [Vagrant](http://vagrantup.com) for running the swarm cluster in virtualbox

# Pre-Requisites<a id="orgheadline2"></a>

To use this project you will need at least this list of tools properly installed on your box:

-   docker 1.10
-   gnu make 4.1
-   vagrant 1.8
-   virtualbox 5.0

# Quickstart<a id="orgheadline3"></a>

To quickly bootstrap a swarm cluster with vagrant on your local machine, configure the [servers.yml](servers.yml) file and type the following commands. 

    $ git clone https://github.com/yanndegat/swarmer
    $ cd swarmer
    $ vi servers.yml
    ...
    $ vagrant up
    ==> box: Loading metadata for box 'yanndegat/swarmer'
        box: URL: https://atlas.hashicorp.com/yanndegat/swarmer
    ==> box: Adding box 'yanndegat/swarmer' (v0.0.1) for provider: virtualbox
        box: Downloading: https://atlas.hashicorp.com/yanndegat/boxes/swarmer/versions/0.0.1/providers/virtualbox.box
        box: Progress: 26% (Rate: 1981k/s, Estimated time remaining: 0:02:24)
    ...
    $ ./setup.sh
    try command:
    export DOCKER_HOST=swarm-4000.service.swarmer:4000
    docker info
    
     or go to http://consul.service.swarmer:8500/ui
    $

Go to <http://consul.service.swarmer:8500/ui>

If you encounter any problem, refer to the next sections.

# Getting Started on AWS<a id="orgheadline4"></a>

Refer to the [README](terraform/aws/README.html) file.

# Play with your swarm cluster<a id="orgheadline12"></a>

Now we can play with swarm.

## Configure DNS resolution<a id="orgheadline5"></a>

To resolv names, you have to configure a dns service that will forward the requests to consul. A docker-compose file is provided (<dns-proxy-compose.yml>).

This compose file starts a dnsmasq service with net=host that will target $CONSULIP consul agent. This only works with vagrant or when the VPN is setup.

    $ # check your /etc/resolv.conf file
    $ cat /etc/resolv.conf
    nameserver 127.0.0.1
    ...
    $ # eventually run the following command for your next boot
    $ sudo su
    root $ echo "nameserver 127.0.0.1" > /etc/resolv.conf.head
    root $ exit
    $ export CONSULIP=192.168.101.101
    $ docker-compose -d -f dns-proxy-compose.yml up -d
    $ curl registry.service.swarmer:5000/v2/_catalog
    {"repositories":[]}
    $ ...

## Using the swarm cluster<a id="orgheadline6"></a>

You can now use your swarm cluster to run docker containers as simply as you would do to run a container on your local docker engine. All you have to do is 
target the IP of one of your swarm node. 

    export DOCKER_HOST=swarm-4000.service.swarmer:4000
    docker pull alpine
    docker run --rm -it alpine /bin/sh
    / # ...

## Using the private registry<a id="orgheadline7"></a>

The private insecure registry which is automatically started on the swarm cluster is registered on the "registry.service.swarmer:5000" name. So you have to tag & push docker images with this name if you want the nodes to be able to download your images.

## Run the examples<a id="orgheadline8"></a>

Examples are available in the [examples](examples) directory. You can play with them to discover how to work with docker swarm.

## Swarmer Components<a id="orgheadline11"></a>

### Architecture guidelines<a id="orgheadline9"></a>

-   Every component of the system must be able to boot/reboot without having to be provisionned with configuration elements other than via cloud init.
-   Every component of the system must be able to discover its pairs and join them
-   If a component can't boot properly, it must be considered as dead. Don't try to fix it.

### Swarmer is architectured with the following components :<a id="orgheadline10"></a>

-   a consul cluster setup, which consists of a set of consul agents running in "server" mode, and additionnal nodes running in "agent" mode.
    The consul cluster could be used :
    -   as a distributed key/value store
    -   as a service discovery
    -   as a dns server
    -   as a backend for swarm master election

-   a swarm cluster setup, which consists of a set of swarm agents running in "server" mode, and additionnal nodes running in agent mode.
    Every swarm node will also run a consul agent and a registrator service to declare every running container in consul.

-   an insecure private registry which is started automatically by a random swarm node. It's registered under the dns address registry.service.consul. If this node is down, it will be restarted by another one within a few seconds. On AWS, it is possible to configure the registry's backend to target a S3 bucket.

Some nodes could play both "consul server" and "swarm server" roles to avoid booting too many servers for small cluster setups.

# Considerations & Roadmap<a id="orgheadline22"></a>

## CoreOS alpha channel<a id="orgheadline13"></a>

Yes. Because by now, it's the only coreos version that supports docker 1.10.

## Use docker-machine<a id="orgheadline14"></a>

We may later consider using docker-machine to install & configure the swarm agents. We would then benefit proper & secured configurations.

## Run consul and swarm services as docker containers<a id="orgheadline15"></a>

There are some caveats running the system services as docker containers, even on coreos. The main problem is the process supervision with systemd, as full described in this [article](https://lwn.net/Articles/676831/). That said, the coreos rocket container engine could be considered as a suitable alternative.

## Monitoring<a id="orgheadline16"></a>

There is no monitoring yet, and no centralized log system configured either.v

## Server.yml to bootstrap AWS<a id="orgheadline17"></a>

It would be nice if the server.yml could be used as input to terraform an AWS setup.

## Running on GCE<a id="orgheadline18"></a>

## Running on Azure<a id="orgheadline19"></a>

## Running on premise<a id="orgheadline20"></a>

## How to do rolling upgrades of the infrastructure with terraform&#x2026;?<a id="orgheadline21"></a>