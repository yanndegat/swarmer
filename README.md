<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#orgheadline1">1. Description</a></li>
<li><a href="#orgheadline6">2. Pre-Requisites</a>
<ul>
<li><a href="#orgheadline4">2.1. With docker [Recommanded]</a>
<ul>
<li><a href="#orgheadline2">2.1.1. Use the image</a></li>
<li><a href="#orgheadline3">2.1.2. Build the image</a></li>
</ul>
</li>
<li><a href="#orgheadline5">2.2. Without docker</a></li>
</ul>
</li>
<li><a href="#orgheadline31">3. Getting Started</a>
<ul>
<li><a href="#orgheadline9">3.1. Swarmer Components</a>
<ul>
<li><a href="#orgheadline7">3.1.1. Architecture guidelines</a></li>
<li><a href="#orgheadline8">3.1.2. Swarmer is architectured with the following components :</a></li>
</ul>
</li>
<li><a href="#orgheadline19">3.2. Try Swarmer on your box with Vagrant</a>
<ul>
<li><a href="#orgheadline13">3.2.1. Building the boxes</a></li>
<li><a href="#orgheadline14">3.2.2. Booting the swarm cluster</a></li>
<li><a href="#orgheadline18">3.2.3. Troubleshootings</a></li>
</ul>
</li>
<li><a href="#orgheadline30">3.3. Try Swarmer on your Amazon AWS Account</a>
<ul>
<li><a href="#orgheadline20">3.3.1. Init S3, Keypair and AMIs</a></li>
<li><a href="#orgheadline21">3.3.2. Create the VPC</a></li>
<li><a href="#orgheadline22">3.3.3. Create the Swarm!</a></li>
<li><a href="#orgheadline27">3.3.4. Configure your access to your swarm cluster</a></li>
<li><a href="#orgheadline28">3.3.5. Destroy the cluster and the vpc</a></li>
<li><a href="#orgheadline29">3.3.6. Debugging</a></li>
</ul>
</li>
</ul>
</li>
<li><a href="#orgheadline37">4. Play with your swarm cluster</a>
<ul>
<li><a href="#orgheadline32">4.1. Configure DNS resolution</a></li>
<li><a href="#orgheadline33">4.2. Using the swarm cluster</a></li>
<li><a href="#orgheadline34">4.3. Using a custom private registry with vagrant</a></li>
<li><a href="#orgheadline35">4.4. Deploy a docker container</a></li>
<li><a href="#orgheadline36">4.5. Using the private registry</a></li>
</ul>
</li>
<li><a href="#orgheadline47">5. Considerations &amp; Roadmap</a>
<ul>
<li><a href="#orgheadline38">5.1. CoreOS alpha channel</a></li>
<li><a href="#orgheadline39">5.2. Use docker-machine</a></li>
<li><a href="#orgheadline40">5.3. Run consul and swarm services as docker containers</a></li>
<li><a href="#orgheadline41">5.4. Monitoring</a></li>
<li><a href="#orgheadline42">5.5. Server.yml to bootstrap AWS</a></li>
<li><a href="#orgheadline43">5.6. Running on GCE</a></li>
<li><a href="#orgheadline44">5.7. Running on Azure</a></li>
<li><a href="#orgheadline45">5.8. Running on premise</a></li>
<li><a href="#orgheadline46">5.9. How to do rolling upgrades of the infrastructure with terraform&#x2026;?</a></li>
</ul>
</li>
</ul>
</div>
</div>

Note: you should prefer reading the <README.html> file in your browser. 

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

# Pre-Requisites<a id="orgheadline6"></a>

To use this project you will need at least this list of tools properly installed on your box:

-   docker 1.10
-   gnu make 4.1
-   vagrant 1.8
-   virtualbox 5.0

## With docker [Recommanded]<a id="orgheadline4"></a>

You can then use the provided docker [container](Dockerfile) to avoid installing the entire toolbox on your computer by either using the image available on the docker hub or by building it yourself.

### Use the image<a id="orgheadline2"></a>

    docker run --rm -it yanndegat/swarmer
    bash-4.3# ...

### Build the image<a id="orgheadline3"></a>

    make latest
    docker run --rm -it swarmer
    bash-4.3# ...

## Without docker<a id="orgheadline5"></a>

If you chose not to use the docker image, you will have to install those additional tools :

-   terraform 0.6.14
-   packer 0.8.6
-   python 2.7
-   awscli (pip install awscli)
-   gnupg 2.1
-   jq 1.5
-   curl

# Getting Started<a id="orgheadline31"></a>

Once you have all the required tools installed on your box, you can follow this guide to setup a swarm cluster on your machine or on your AWS account.

## Swarmer Components<a id="orgheadline9"></a>

### Architecture guidelines<a id="orgheadline7"></a>

-   Every component of the system must be able to boot/reboot without having to be provisionned with configuration elements other than via cloud init.
-   Every component of the system must be able to discover its pairs and join them
-   If a component can't boot properly, it must be considered as dead. Don't try to fix it.

### Swarmer is architectured with the following components :<a id="orgheadline8"></a>

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

## Try Swarmer on your box with Vagrant<a id="orgheadline19"></a>

Things shouldn't be harder than a single vagrant up. Nodes configuration is located in the [servers.yml.example](servers.yml.example) file. By default it will boot 3 servers with 1cpu/1g ram. You can edit this file to adjust it to your needs. But before booting any server, you will need to build the vagrant boxes!

### Building the boxes<a id="orgheadline13"></a>

There are 3 boxes which have to be built: 

-   a base box,
-   a consul box which inherits from the base box
-   a swarm box which inherits from the consul box

IMPORTANT! To build the vagrant boxes, you can't use the container toolbox, you have to install packer on your machine.

1.  Base box

    The base box is based on the 991.0.0 coreos iso image. This box will be used as a parent box for the consul and swarm boxes. As its build is pretty long and isn't very reliable, this basebox is mainly useful to speed the build phase of the consul and swarm boxes.
    
    It contains the vagrant insecure public key.
    
        cd packer/consul
        make coreos-ovf

2.  Consul box

    The consul box is based on the coreos-ovf base image previously built. It contains :
    
    -   a systemd consul service that will boot a consul agent, configured through a cloud-init userdata configuration.
    -   a systemd docker configurator service to ease the configuration of the docker engine through cloud-init
    
        cd packer/consul
        make vbox

3.  Swarm box

    The swarm box is based on the consul base ovf image previously built. It contains :
    
    -   a systemd swarm service that will boot a swarm agent, configured through a cloud-init userdata configuration.
    -   a systemd docker registrator service that will declare every running docker container to its local consul agent.
    
        cd packer/swarm
        make vbox

### Booting the swarm cluster<a id="orgheadline14"></a>

    cp servers.yml.example servers.yml
    vi servers.yml
    ...
    vagrant up
    ...
    export DOCKER_HOST=192.168.101.101:4000
    docker info
    Containers: 20
     Running: 17
     Paused: 0
     Stopped: 3
    Images: 25
    Server Version: swarm/1.1.3
    Role: replica
    Primary: 192.168.101.102:4000
    Strategy: spread
    Filters: health, port, dependency, affinity, constraint
    Nodes: 3
     swarm-01: 192.168.101.101:2375
      └ Status: Healthy
      └ Containers: 6
      └ Reserved CPUs: 0 / 2
      └ Reserved Memory: 0 B / 3.09 GiB
      └ Labels: executiondriver=native-0.2, kernelversion=4.4.6-coreos, operatingsystem=CoreOS 991.0.0 (Coeur Rouge), storagedriver=overlay
      └ Error: (none)
      └ UpdatedAt: 2016-03-22T15:36:34Z
     swarm-02: 192.168.101.102:2375
      └ Status: Healthy
      └ Containers: 7
      └ Reserved CPUs: 0 / 2
      └ Reserved Memory: 0 B / 3.09 GiB
      └ Labels: executiondriver=native-0.2, kernelversion=4.4.6-coreos, operatingsystem=CoreOS 991.0.0 (Coeur Rouge), storagedriver=overlay
      └ Error: (none)
      └ UpdatedAt: 2016-03-22T15:36:13Z
     swarm-03: 192.168.101.103:2375
      └ Status: Healthy
      └ Containers: 7
      └ Reserved CPUs: 0 / 2
      └ Reserved Memory: 0 B / 3.09 GiB
      └ Labels: executiondriver=native-0.2, kernelversion=4.4.6-coreos, operatingsystem=CoreOS 991.0.0 (Coeur Rouge), storagedriver=overlay
      └ Error: (none)
      └ UpdatedAt: 2016-03-22T15:36:41Z
    Plugins:
     Volume:
     Network:
    Kernel Version: 4.4.6-coreos
    Operating System: linux
    Architecture: amd64
    CPUs: 6
    Total Memory: 9.269 GiB
    Name: 8e081c5df4b9

### Troubleshootings<a id="orgheadline18"></a>

1.  Check the consul agents

    Try to connect to any of your nodes through ssh and list the members of your consul cluster.
    
    The status of each node should be "alive". If its not the case, try to reboot the failing nodes.
    
        vagrant ssh swarm-01
        CoreOS alpha (991.0.0)
        core@swarm-01 ~ $ /opt/scripts/consul/consul members
        Node        Address               Status  Type    Build  Protocol  DC
        'swarm-01'  192.168.101.101:8301  alive   server  0.6.3  2         vagrant
        'swarm-02'  192.168.101.102:8301  alive   server  0.6.3  2         vagrant
        'swarm-03'  192.168.101.103:8301  alive   server  0.6.3  2         vagrant

2.  Check the swarm agents

    Try to connect to your nodes and check if every node has its swarm agents running. 
    Each node shall have at least one registrator and one swarm-agent containers running. Server nodes have an additional swarm-manager container running.
    
    If every agents are present on every node, but the swarm cluster is failing, try to inspect the logs of the agents.
    
        vagrant ssh swarm-01
        CoreOS alpha (991.0.0)
        core@swarm-01 ~ $ docker ps
        CONTAINER ID        IMAGE                           COMMAND                  CREATED             STATUS              PORTS                                                   NAMES
        585c091b4295        gliderlabs/registrator:latest   "/bin/registrator -in"   22 hours ago        Up 22 hours                                                                 registrator
        138437cf7740        swarm:latest                    "/swarm join --advert"   22 hours ago        Up 22 hours         2375/tcp                                                swarm-agent
        8e081c5df4b9        swarm:latest                    "/swarm manage -H :40"   22 hours ago        Up 22 hours         2375/tcp, 192.168.101.101:4000->4000/tcp                swarm-manager
        core@swarm-01 ~ $ 
        core@swarm-01 ~ $ docker logs swarm-manager
        ...
        time="2016-03-21T17:21:50Z" level=info msg="Leader Election: Cluster leadership lost"
        time="2016-03-21T17:21:50Z" level=info msg="New leader elected: 192.168.101.102:4000"
        time="2016-03-21T17:22:00Z" level=info msg="Registered Engine swarm-03 at 192.168.101.103:2375"
        time="2016-03-21T17:22:00Z" level=info msg="Registered Engine swarm-01 at 192.168.101.101:2375"
        time="2016-03-21T17:22:25Z" level=info msg="Registered Engine swarm-02 at 192.168.101.102:2375"

3.  Check the systemd services

    If the agents aren't running, check for any systemd service error with journalctl and systemctl.

## Try Swarmer on your Amazon AWS Account<a id="orgheadline30"></a>

Things should be a "little bit harder" than a single vagrant up ;)
Before booting the instances, we will have to create an ssh keypair and then install a brand new multi-az VPC, with its nat gateways and public and private subnets. We will also add a bastion+vpn instance to ease interactions with the services deployed within your VPC.

Then we can boot the Swarmer instances on the proper subnets.

We provide scripts to allow different kind of setups. Feel free to customize them to better suit your needs.

IMPORTANT: All of these actions will be performed by terraform. As your setup on AWS could be more than just a "dev environment", terraform store the state of our infrastructure in S3, allowing multiple users to retrieve/update the infrastructure.

### Init S3, Keypair and AMIs<a id="orgheadline20"></a>

A script is provided to initialize the creation of the required resources: 

-   a s3 bucket
-   a keypair
-   the amis

The keypair will be encrypted with gpg and uploaded to the s3 bucket, so that it can be shared with other members of a team.

We will show an example using the docker swarmer image.

    docker run --rm -it \ 
      -v $(pwd):/tmp/output \
      -e AWS_SECRET_ACCESS_KEY="[AWS_SECRET_ACCESS_KEY]" \
      -e AWS_ACCESS_KEY_ID="[AWS_ACCESS_KEY_ID]" \
      -e AWS_DEFAULT_REGION="[AWS_REGION]" \
      -e STACK_NAME="myswarmer" \
      -e AWS_ACCOUNT="[AWS_ACCOUNT]" \
      -e PASSPHRASE="[a passphrase]"
       swarmer terraform/aws/scripts/dc-init.sh -A init
    ...
    1458667162,,ui,say,==> aws: No volumes to clean up%!(PACKER_COMMA) skipping
    1458667162,,ui,say,==> aws: Deleting temporary security group...
    1458667163,,ui,say,==> aws: Deleting temporary keypair...
    1458667163,,ui,say,Build 'aws' finished.
    1458667163,,ui,say,\n==> Builds finished. The artifacts of successful builds are:
    1458667163,aws,artifact-count,1
    1458667163,aws,artifact,0,builder-id,mitchellh.amazonebs
    1458667163,aws,artifact,0,id,eu-west-1:ami-c79e1ab4
    1458667163,aws,artifact,0,string,AMIs were created:\n\neu-west-1: ami-c79e1ab4
    1458667163,aws,artifact,0,files-count,0
    1458667163,aws,artifact,0,end
    1458667163,,ui,say,--> aws: AMIs were created:\n\neu-west-1: ami-c79e1ab4
    make: Leaving directory '/src/packer/swarmer'

IMPORTANT! As this step builds severals AMIs it can be pretty long. Coffee time.

### Create the VPC<a id="orgheadline21"></a>

A script is provided to create a VPC and all its associated resources.

    docker run --rm -it \ 
      -e AWS_SECRET_ACCESS_KEY="[AWS_SECRET_ACCESS_KEY]" \
      -e AWS_ACCESS_KEY_ID="[AWS_ACCESS_KEY_ID]" \
      -e AWS_DEFAULT_REGION="[AWS_REGION]" \
      -e STACK_NAME="myswarmer" \
      -e AWS_ACCOUNT="[AWS_ACCOUNT]" \
       swarmer terraform/aws/scripts/dc-multi-az-vpc.sh bootstrap
    ...
    
    Apply complete! Resources: 30 added, 0 changed, 0 destroyed.
    
    The state of your infrastructure has been saved to the path
    below. This state is required to modify and destroy your
    infrastructure, so keep it safe. To inspect the complete state
    use the `terraform show` command.
    
    State path: .terraform/terraform.tfstate
    
    Outputs:
    
      availability_zones        = eu-west-1a,eu-west-1b
      bastion_ip                = 53.40.250.156
      dns_domain_name           = myswarmer
      dns_zone_id               = Z31337FAKAECW63O
      key_name                  = myswarmer-keypair
      security_group            = sg-2c2d3048
      subnet_id_zone_a          = subnet-3f0ff45b
      subnet_id_zone_b          = subnet-ebfc1f9d
      subnet_ids                = subnet-3f0ff45b,subnet-ebfc1f9d
      swarmer_access_key_id     = FAKEI7WKFAKEIUIFAKE
      swarmer_access_key_secret = +FAK+FAKEFAKES75Eb5FAKE5LSZFAKE5nq1ypOGFAKE
      vpc_id                    = vpc-aa2e3ecf

This step takes normally less than 5 minutes.

### Create the Swarm!<a id="orgheadline22"></a>

Now that you have a proper VPC bootstrapped, you can deploy your swarm instance into it. 

You have several choices of deployment :

-   separated consul servers from swarm nodes
-   separated swarm managers from swarm nodes
-   single/multi availability zones deployment

It is commonly accepted that, for small clusters (up to 10 nodes), you can colocate your swarm managers with your swarm agents and have as many managers as agents.
Yet, it is not recommanded to have a lot of consul servers. From 3 to 6 is a good choice for reliability. More and the gossip protocol and sync process will start downgrading performances.

Here we will boot a 6 nodes swarm clusters spanned on 2 availability zones, with one consul server by swarm node. That way, if an avaibility zone goes down, consul still has 3 nodes to make a quorum for master election.

Terraform is the tool used to bootstrap the instance. Also several building blocks are available to help you quickly bootstrap a cluster. Some example bash scripts demonstrate how to use those terraform building blocks. Feel free to add/create/modify them to get the infrastructure that better suits your requirements.

    docker run --rm -it \ 
      -e AWS_SECRET_ACCESS_KEY="[AWS_SECRET_ACCESS_KEY]" \
      -e AWS_ACCESS_KEY_ID="[AWS_ACCESS_KEY_ID]" \
      -e AWS_DEFAULT_REGION="[AWS_REGION]" \
      -e STACK_NAME="myswarmer" \
      -e AWS_ACCOUNT="[AWS_ACCOUNT]" \
       swarmer terraform/aws/scripts/dc-multi-az-simple-swarm.sh bootstrap
    ...
    
    Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
    
    The state of your infrastructure has been saved to the path
    below. This state is required to modify and destroy your
    infrastructure, so keep it safe. To inspect the complete state
    use the `terraform show` command.
    
    State path: .terraform/terraform.tfstate

### Configure your access to your swarm cluster<a id="orgheadline27"></a>

Your cluster is located on a private subnet with no public facing IP. To be able to target it or simply connect to it, you have two options:

-   through ssh tunnels
-   through the VPN

1.  SSH tunnels

    This section describes how to establish ssh connections or tunnels through the bastion instance of the VPC. As it can be quite an annoying step, we've made a simple script which generates an ssh config and download the private key that you'll have to copy in your local ssh directory ( probably ~/.ssh ).
    
        docker run --rm -it \ 
          -e AWS_SECRET_ACCESS_KEY="[AWS_SECRET_ACCESS_KEY]" \
          -e AWS_ACCESS_KEY_ID="[AWS_ACCESS_KEY_ID]" \
          -e AWS_DEFAULT_REGION="[AWS_REGION]" \
          -e STACK_NAME="myswarmer" \
          -e AWS_ACCOUNT="[AWS_ACCOUNT]" \
          -e PASSPHRASE="[a passphrase]" \
          -v /tmp:/output
           swarmer terraform/aws/scripts/dc-multi-az-simple-swarm.sh config-ssh 
        ...
        cat /tmp/config >> ~/.ssh/config
        #the docker container generates files that belong to the root user
        sudo cp /tmp/myswarmer.key ~/.ssh
        sudo chown $USER ~/.ssh/myswarmer.key
        cat ~/.ssh/config
        ...
        Host myswarmer-swarm-zone-a-swarm_manager-0
           HostName 10.233.1.205
           IdentityFile ~/.ssh/myswarmer.key
           ProxyCommand ssh -l ec2-user -i ~/.ssh/myswarmer.key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null "52.48.24.59" nc %h %p
        
        Host myswarmer-swarm-zone-a-swarm_manager-1
           HostName 10.233.1.254
           IdentityFile ~/.ssh/myswarmer.key
           ProxyCommand ssh -l ec2-user -i ~/.ssh/myswarmer.key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null "52.48.24.59" nc %h %p
        
        Host myswarmer-swarm-zone-a-swarm_manager-2
           HostName 10.233.1.253
           IdentityFile ~/.ssh/myswarmer.key
           ProxyCommand ssh -l ec2-user -i ~/.ssh/myswarmer.key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null "52.48.24.59" nc %h %p
        
        Host myswarmer-swarm-zone-b-swarm_manager-0
           HostName 10.233.3.8
           IdentityFile ~/.ssh/myswarmer.key
           ProxyCommand ssh -l ec2-user -i ~/.ssh/myswarmer.key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null "52.48.24.59" nc %h %p
        
        Host myswarmer-swarm-zone-b-swarm_manager-1
           HostName 10.233.3.54
           IdentityFile ~/.ssh/myswarmer.key
           ProxyCommand ssh -l ec2-user -i ~/.ssh/myswarmer.key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null "52.48.24.59" nc %h %p
        
        Host myswarmer-swarm-zone-b-swarm_manager-2
           HostName 10.233.3.45
           IdentityFile ~/.ssh/myswarmer.key
           ProxyCommand ssh -l ec2-user -i ~/.ssh/myswarmer.key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null "52.48.24.59" nc %h %p
        
        Host "10.233.*"
           IdentityFile ~/.ssh/myswarmer.key
           ProxyCommand ssh -l ec2-user -i ~/.ssh/myswarmer.key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null "52.48.24.59" nc %h %p
    
    You will notice that there is one entry per host, plus one global entry matching every ip beginning with 10.233.\*. This uncommon /16 subnet has been chosen to avoid IP overlapping with your privates subnets. It can be configured if it doesn't suits you. See <terraform/aws/vpc/variables.tf>. 
    
    IMPORTANT! Only the hosts that are "up" are added to the config. By "up", we mean that they have at least joined the consul cluster. If you have no host in the config, retrieve the privates ips of your instances through the aws console and ssh into them using their private IP; the global "10.233.\*" is dedicated to this.
    
    You'll also notice that each entry refers to a "myswarmer.key". This is the private ssh key that has been generated during the init phase and uploaded to s3.

2.  VPN access

    This section describes how to establish a vpn connection with openvpn. You need to have a proper install of openvpn on your box. You also need the private ssh key. Refer to the previous section to know how to retrieve it.
    
    The first thing you need is to generate your VPN keys and retrieve the openvpn configuration.
    
        $ # the ip of the bastion is referred in the generated ssh config, and also 
        $ ssh myswarmer-bastion /opt/ovpn-client-config.sh MYNAME > ~/MYNAME.myswarmer-ovpn.conf
        Generating a 2048 bit RSA private key
        ..........................+++
        ................+++
        writing new private key to '/etc/openvpn/pki/private/MYNAME.key.XXXXigMGgg'
        -----
        Using configuration from /usr/share/easy-rsa/openssl-1.0.cnf
        Check that the request matches the signature
        Signature ok
        The Subject's Distinguished Name is as follows
        commonName            :ASN.1 12:'MYNAME'
        Certificate is to be certified until Apr  6 15:59:42 2026 GMT (3650 days)
        
        Write out database with 1 new entries
        Data Base Updated
        
        $ sudo openvpn ~/MYNAME.myswarmer-ovpn.conf
        ...
        Fri Apr  8 17:58:48 2016 TLS Error: TLS handshake failed
        Fri Apr  8 17:58:48 2016 SIGUSR1[soft,tls-error] received, process restarting
        Fri Apr  8 17:58:50 2016 WARNING: Your certificate is not yet valid!
        Fri Apr  8 17:58:50 2016 Control Channel Authentication: tls-auth using INLINE static key file
        Fri Apr  8 17:58:50 2016 UDPv4 link local: [undef]
        Fri Apr  8 17:58:50 2016 UDPv4 link remote: [AF_INET]52.48.31.60:1194
        Fri Apr  8 17:58:50 2016 [52.48.31.60] Peer Connection Initiated with [AF_INET]52.48.31.60:1194
        Fri Apr  8 17:58:52 2016 TUN/TAP device tun0 opened
        Fri Apr  8 17:58:52 2016 do_ifconfig, tt->ipv6=0, tt->did_ifconfig_ipv6_setup=0
        Fri Apr  8 17:58:52 2016 /usr/bin/ip link set dev tun0 up mtu 1500
        Fri Apr  8 17:58:52 2016 /usr/bin/ip addr add dev tun0 local 192.168.255.6 peer 192.168.255.5
        Fri Apr  8 17:58:52 2016 Initialization Sequence Completed
        
        $ # get the internal ip of one of the members of the cluster and try to get consul info:
        
        $ curl 10.233.1.145:8500/v1/catalog
        {"consul":[],"swarm-4000":[]}%
        $ # BINGO!

3.  SSH to a node

    You can ssh to a swarm with a simple ssh command:
    
        ssh core@myswarmer-swarm-zone-a-swarm_manager-0
        CoreOS alpha (991.0.0)
        core@ip-172-233-3-45 ~ $ 
        core@ip-172-233-3-45 ~ $ docker ps
        CONTAINER ID        IMAGE                           COMMAND                  CREATED             STATUS              PORTS                                   NAMES
        f08eb5612b51        gliderlabs/registrator:latest   "/bin/registrator -in"   27 minutes ago      Up 27 minutes                                               registrator
        666dcc033b8f        swarm:latest                    "/swarm manage -H :40"   27 minutes ago      Up 27 minutes       2375/tcp, 172.233.3.45:4000->4000/tcp   swarm-manager
        14dc3ed89cb6        swarm:latest                    "/swarm join --advert"   27 minutes ago      Up 27 minutes       2375/tcp                                swarm-agent
        
        core@ip-172-233-3-45 ~ $ ...

4.  Create an ssh tunnel to swarm

    If you don't want to use the VPN, you can create an ssh tunnel to ease the deployment of a container from your box
    
        # you have to replace the 172.233.1.205 ip with the private ip of the node you selected
         ssh -fqnNT -L localhost:4000:172.233.1.205:4000 core@myswarmer-swarm-zone-a-swarm_manager-0
        
        export DOCKER_HOST=localhost:4000
        docker info
        Containers: 18
         Running: 18
         Paused: 0
         Stopped: 0
        Images: 18
        Server Version: swarm/1.1.3
        Role: replica
        Primary: 172.233.3.8:4000
        Strategy: spread
        Filters: health, port, dependency, affinity, constraint
        Nodes: 6
         ip-172-233-1-205.eu-west-1.compute.internal: 172.233.1.205:2375
          └ Status: Healthy
          └ Containers: 3
          └ Reserved CPUs: 0 / 2
          └ Reserved Memory: 0 B / 8.19 GiB
          └ Labels: executiondriver=native-0.2, kernelversion=4.4.6-coreos, operatingsystem=CoreOS 991.0.0 (Coeur Rouge), storagedriver=overlay
          └ Error: (none)
          └ UpdatedAt: 2016-03-24T10:57:49Z
         ip-172-233-1-253.eu-west-1.compute.internal: 172.233.1.253:2375
          └ Status: Healthy
          └ Containers: 3
          └ Reserved CPUs: 0 / 2
          └ Reserved Memory: 0 B / 8.19 GiB
          └ Labels: executiondriver=native-0.2, kernelversion=4.4.6-coreos, operatingsystem=CoreOS 991.0.0 (Coeur Rouge), storagedriver=overlay
          └ Error: (none)
          └ UpdatedAt: 2016-03-24T10:57:37Z
         ip-172-233-1-254.eu-west-1.compute.internal: 172.233.1.254:2375
          └ Status: Healthy
          └ Containers: 3
          └ Reserved CPUs: 0 / 2
          └ Reserved Memory: 0 B / 8.19 GiB
          └ Labels: executiondriver=native-0.2, kernelversion=4.4.6-coreos, operatingsystem=CoreOS 991.0.0 (Coeur Rouge), storagedriver=overlay
          └ Error: (none)
          └ UpdatedAt: 2016-03-24T10:57:45Z
         ip-172-233-3-8.eu-west-1.compute.internal: 172.233.3.8:2375
          └ Status: Healthy
          └ Containers: 3
          └ Reserved CPUs: 0 / 2
          └ Reserved Memory: 0 B / 8.19 GiB
          └ Labels: executiondriver=native-0.2, kernelversion=4.4.6-coreos, operatingsystem=CoreOS 991.0.0 (Coeur Rouge), storagedriver=overlay
          └ Error: (none)
          └ UpdatedAt: 2016-03-24T10:57:43Z
         ip-172-233-3-45.eu-west-1.compute.internal: 172.233.3.45:2375
          └ Status: Healthy
          └ Containers: 3
          └ Reserved CPUs: 0 / 2
          └ Reserved Memory: 0 B / 8.19 GiB
          └ Labels: executiondriver=native-0.2, kernelversion=4.4.6-coreos, operatingsystem=CoreOS 991.0.0 (Coeur Rouge), storagedriver=overlay
          └ Error: (none)
          └ UpdatedAt: 2016-03-24T10:57:26Z
         ip-172-233-3-54.eu-west-1.compute.internal: 172.233.3.54:2375
          └ Status: Healthy
          └ Containers: 3
          └ Reserved CPUs: 0 / 2
          └ Reserved Memory: 0 B / 8.19 GiB
          └ Labels: executiondriver=native-0.2, kernelversion=4.4.6-coreos, operatingsystem=CoreOS 991.0.0 (Coeur Rouge), storagedriver=overlay
          └ Error: (none)
          └ UpdatedAt: 2016-03-24T10:57:42Z
        Plugins:
         Volume:
         Network:
        Kernel Version: 4.4.6-coreos
        Operating System: linux
        Architecture: amd64
        CPUs: 12
        Total Memory: 49.14 GiB
        Name: a540944837d6

### Destroy the cluster and the vpc<a id="orgheadline28"></a>

You can destroy the resources with the same scripts used to terraform by simply replacing the "bootstrap" command with "destroy"

### Debugging<a id="orgheadline29"></a>

The best way to debug the system is to run the docker tool container with the proper env vars set, and attached to your src volume. You still have to get familiar with terraform, which is not the purpose of this guide.

    docker run --rm -it \ 
      -v $(pwd):/src
      -e AWS_SECRET_ACCESS_KEY="[AWS_SECRET_ACCESS_KEY]" \
      -e AWS_ACCESS_KEY_ID="[AWS_ACCESS_KEY_ID]" \
      -e AWS_DEFAULT_REGION="[AWS_REGION]" \
      -e STACK_NAME="myswarmer" \
      -e AWS_ACCOUNT="[AWS_ACCOUNT]" \
       swarmer 
    bash-4.3# ...

# Play with your swarm cluster<a id="orgheadline37"></a>

Now we can play with swarm.

## Configure DNS resolution<a id="orgheadline32"></a>

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
    $ curl registry.service.consul:5000/v2/_catalog
    {"repositories":[]}
    $ ...

## Using the swarm cluster<a id="orgheadline33"></a>

You can now use your swarm cluster to run docker containers as simply as you would do to run a container on your local docker engine. All you have to do is 
target the IP of one of your swarm node. 

    export DOCKER_HOST=swarm-4000.service.consul:4000
    docker pull alpine
    docker run --rm -it alpine /bin/sh
    / # ...

## Using a custom private registry with vagrant<a id="orgheadline34"></a>

If you inspect the docker engines configuration on each swarm node, you'll notice that an insecure registry targeting your private IP has been added.

If you start a local docker registry on your box, you'll ease and fasten the download of your private docker images.

    export DOCKER_HOST=
    export MYIP="$(ip route | grep default | sed 's/.*src \([0-9\.]*\).*$/\1/g')"
    docker run -d --net host --name registry registry:2
    docker tag myimage:latest $MYIP:5000/myimage:latest
    docker push $MYIP:5000/myimage:latest
    export DOCKER_HOST=192.168.101.101:4000
    docker pull $MYIP:5000/myimage:latest
    swarm-01: Pulling 192.168.0.43:5000/myimage:latest...
    swarm-03: Pulling 192.168.0.43:5000/myimage:latest... : downloaded
    swarm-02: Pulling 192.168.0.43:5000/myimage:latest... : downloaded
    ...
    docker run --rm -it myimage:latest
    ...

## Deploy a docker container<a id="orgheadline35"></a>

Quite simple&#x2026; ( don't forget to launch the ssh tunnel if you don't use VPN )

    export DOCKER_HOST=swarm-4000.service.consul:4000
    docker run --rm -it alpine /bin/sh
    / # echo "let's play with docker swarm!"

## Using the private registry<a id="orgheadline36"></a>

The private insecure registry which is automatically started on the swarm cluster is registered on the "registry.service.consul" name. So you have to tag & push docker images with this name if you want the nodes to be able to download your images. 

# Considerations & Roadmap<a id="orgheadline47"></a>

## CoreOS alpha channel<a id="orgheadline38"></a>

Yes. Because by now, it's the only coreos version that supports docker 1.10.

## Use docker-machine<a id="orgheadline39"></a>

We may later consider using docker-machine to install & configure the swarm agents. We would then benefit proper & secured configurations.

## Run consul and swarm services as docker containers<a id="orgheadline40"></a>

There are some caveats running the system services as docker containers, even on coreos. The main problem is the process supervision with systemd, as full described in this [article](https://lwn.net/Articles/676831/). That said, the coreos rocket container engine could be considered as a suitable alternative.

## Monitoring<a id="orgheadline41"></a>

There is no monitoring yet, and no centralized log system configured either.v

## Server.yml to bootstrap AWS<a id="orgheadline42"></a>

It would be nice if the server.yml could be used as input to terraform an AWS setup.

## Running on GCE<a id="orgheadline43"></a>

## Running on Azure<a id="orgheadline44"></a>

## Running on premise<a id="orgheadline45"></a>

## How to do rolling upgrades of the infrastructure with terraform&#x2026;?<a id="orgheadline46"></a>