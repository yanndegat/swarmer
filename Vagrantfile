Vagrant.require_version '>= 1.6.0'

require 'yaml'
require 'tempfile'
require 'socket'

$swarmer_community_ami = "ami-88f360fb"
$certs_path = ENV['SWARMER_CERTSV_DIR'] || "#{ENV['HOME']}/.swarmer"
$nodes_yaml_path = ENV["SWARMER_NODES_YML"] || "./nodes.yml"

def compute_node_fields(spec)
  spec['nodes'].each_with_index{ |node,i|
    node['name'] = "#{spec['id']}-#{i}"
    if not node.key?('control-cert')
      node['control-cert'] = "#{$certs_path}/#{spec['stack']}/#{spec['dc']}/#{node['name']}-control.pem"
      node['control-cert-key'] = "#{$certs_path}/#{spec['stack']}/#{spec['dc']}/#{node['name']}-control-key.pem"
    elsif not File.file? node['control-cert']
      puts "File #{node['control-cert']} not found."
      exit 1
    end

    if not node.key?('node-cert')
      node['node-cert'] = "#{$certs_path}/#{spec['stack']}/cert.pem"
      node['node-cert-key'] = "#{$certs_path}/#{spec['stack']}/key.pem"
    elsif not File.file? node['node-cert']
      puts "File #{node['node-cert']} not found."
      exit 1
    end
  }
end

def init_tls_ca_certs (spec)
  init_certs_files = ["ca", "ca-key", "cert", "key" ].map{ |c| "#{$certs_path}/#{spec['stack']}/#{c}.pem"}
  if not init_certs_files.map{ |f| File.file?(f) }.reduce{|r,c| r && c }
    puts "generating ca cert and cert for client"
    init = system("./bin/init-certs #{spec['stack']}")
    if not init
      puts "failed to init ca certificates"
      exit 1
    end
  end
end

def init_ssh_keypair (spec)
  files = ["ssh-keypair", "ssh-keypair.pub"].map{ |c| "#{$certs_path}/#{spec['stack']}/#{c}"}
  if not files.map{ |f| File.file?(f) }.reduce{|r,c| r && c }
    puts "generating ssh keypair for client"
    init = system("./bin/init-ssh-keypair #{spec['stack']}")
    if not init
      puts "failed to init ssh keypair"
      exit 1
    end
  end
end

def init_tls_nodes_certs(spec)
  nodes = spec['nodes']
  nodes_without_certs = nodes.find_all{ |n| (not File.file? n['control-cert'] or not File.file? n['node-cert']) }
  if nodes_without_certs.size > 0
    puts "generating certs for nodes: #{nodes_without_certs.map{ |s| s['name'] }.join(' ')}"
    nodes_args = nodes_without_certs.map{ |n| "#{n['name']}:#{n['ip']}" }.join(' ')
    init_nodes = system("./bin/node-certs #{spec['stack']} #{spec['dc']} #{nodes_args}")
    if not init_nodes
      puts "failed to init nodes certificates"
      exit 1
    end
  end
end


def indent_file_content_for_cloud_init (file_name)
  indent_content_for_cloud_init IO.read(file_name)
end

def indent_content_for_cloud_init (content)
  content.split("\n").collect{|line| "     #{line}"}.join("\n")
end

def cert(spec, node, type)
  if node.key? 'cert' and File.file? node['cert']
    node['cert']
  else
    "#{$certs_path}/#{spec['stack']}/#{spec['dc']}/#{node['name']}-#{type}.pem"
  end
end

def cert_key(spec, node, type)
  if node.key? 'cert-key' and File.file? node['cert-key']
    node['cert-key']
  else
    "#{$certs_path}/#{spec['stack']}/#{spec['dc']}/#{node['name']}-#{type}-key.pem"
  end
end

def cacert(spec)
  if spec.key? 'ca' and File.file? spec['ca']
    spec['ca']
  else
    "#{$certs_path}/#{spec['stack']}/ca.pem"
  end
end

def client_cert(spec)
  if spec.key? 'client-cert' and File.file? spec['client-cert']
    spec['client-cert']
  else
    "#{$certs_path}/#{spec['stack']}/cert.pem"
  end
end

def client_cert_key(spec)
  if spec.key? 'client-cert-key' and File.file? spec['client-cert-key']
    spec['client-cert-key']
  else
    "#{$certs_path}/#{spec['stack']}/key.pem"
  end
end

def ssh_pubkey_content(spec)
  if spec.key? 'ssh-key' and File.file? spec['ssh-key']
    IO.read(spec['ssh-key'])
  else
    IO.read("#{$certs_path}/#{spec['stack']}/ssh-keypair.pub")
  end
end

def config_virtualbox_srv(srv, spec, node)
  srv.vm.provider :virtualbox do |v|
    v.check_guest_additions = false
    v.functional_vboxsf     = false
    v.memory = node['memory']
    v.cpus   = node['cpus']
  end
  srv.vm.synced_folder ".", "/vagrant", disabled: true
  srv.vm.box = spec['box'] || "yanndegat/swarmer-coreos"
  # Don't check for box updates
  srv.vm.box_check_update = false

  # Assign an additional static private network
  srv.vm.network 'private_network', ip: node['ip']
  userdata_file = Tempfile.new(node['name'])
  userdata_file.write userdata(spec, node )
  userdata_file.close

  srv.vm.provision :file, :source => userdata_file.path(), :destination => "/tmp/vagrantfile-user-data"
  srv.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
end

def config_aws_srv(srv, spec, node)
  srv.vm.synced_folder ".", "/vagrant", disabled: true
  srv.vm.provider :aws do |aws, override|
    aws.access_key_id = spec['aws']['access-key-id']
    aws.instance_type = spec['aws']['instance-type']
    aws.monitoring = spec['aws']['monitoring'] || false
    aws.session_token = spec['aws']['session-token']
    aws.secret_access_key = spec['aws']['secret-access-key']
    aws.security_groups = spec['aws']['security-groups']
    aws.iam_instance_profile_arn = spec['aws']['iam-instance-profile-arn']
    aws.iam_instance_profile_name = spec['aws']['iam-instance-profile-name']
    aws.tenancy = spec['aws']['tenancy'] || "default"
    aws.use_iam_profile = spec['aws']['use-iam-profile'] || false
    aws.elb = spec['aws']['elb']
    aws.ebs_optimized = spec['aws']['ebs-optimized'] || false
    aws.unregister_elb_from_az = spec['aws']['unregister-elb-from-az'] || false
    aws.terminate_on_shutdown = spec['aws']['terminate-on-shutdown'] || false
    aws.availability_zone = spec ['aws']['availability-zone']
    aws.subnet_id = spec ['aws']['subnet-id']

    aws.region = spec['aws']['region']
    aws.region_config spec['aws']['region'] do |region|
      region.ami = spec['box'] || $swarmer_community_ami
      region.keypair_name = spec['aws']['keypair-name']
    end

    aws.tags =  { 'Name' => "#{spec['stack']}-#{spec['dc']}-#{node['name']}",
                  'Stack' => spec['stack'],
                  'Datacenter' => spec['dc'],
                  'Id' => node['name'] }

    aws.user_data = userdata(spec, node)
    aws.ami = spec['box'] || $swarmer_community_ami
    aws.private_ip_address = node['ip']
    aws.elastic_ip = spec['aws']['elastic-ip'] || false
    aws.associate_public_ip = spec['aws']['associate-public-ip'] || false

    aws.ssh_host_attribute = :private_ip_address
  end
end

def flocker_agent_conf(spec)
  if spec['volume-driver'] != 'flocker' || spec['provider'] != 'aws'
    ""
  else
    conf = <<EOF
"version": 1
"control-service":
   "hostname": "flocker.service.#{spec['stack']}"
   "port": 4524
dataset:
  backend: "aws"
  region: "#{spec['aws']['region']}"
  zone: "#{spec['aws']['availability-zone']}"
  access_key_id: "#{spec['aws']['access-key-id']}"
  secret_access_key: "#{spec['aws']['secret-access-key']}"
EOF

    userdata_part = <<EOF
  - path: "/etc/swarmer/flocker-agent.yml"
    permissions: "0600"
    owner: "root"
    content: |
#{indent_content_for_cloud_init(conf)}
EOF
    return userdata_part
  end
end

def swarm_mode(node)
  if node.key? 'swarm-manager'
    node['swarm-manager'] ? 'both' : 'agent'
  else
    'both'
  end
end

def consul_mode(node)
  if node.key? 'consul-server'
    node['consul-server'] ? 'server' : 'agent'
  else
    'server'
  end
end

def flocker_mode(node)
  if node.key? 'flocker-control'
    node['flocker-control'] ? 'server' : 'agent'
  else
    'agent'
  end
end

def docker_labels_opts(spec, node)
  labels = "--label clusterid=#{spec['id']}"

  if spec.key? 'labels' and spec['labels'].size > 0
    labels << " --label "<< spec['labels'].join(' --label ')
  end

  if node.key? 'labels' and node['labels'].size > 0
    labels << "--label " << node['labels'].join(' --label ')
  end

  return labels
end

def userdata(spec, node)

  certs = {
    "ca.pem"           => IO.read(cacert(spec)),
    "node.pem"         => IO.read(cert(spec, node, 'control')),
    "node-key.pem"     => IO.read(cert_key(spec, node, 'control')),
    "api.pem"          => IO.read(cert(spec, node, 'node')),
    "api-key.pem"      => IO.read(cert_key(spec, node, 'node')),
    #"plugin.pem"       => IO.read(cert(spec, node, 'plugin')),
    #"plugin-key.pem"   => IO.read(cert_key(spec, node, 'plugin')),
    "client.pem"       => IO.read(client_cert(spec)),
    "client-key.pem"   => IO.read(client_cert_key(spec))
  }

  certs_gzip_base64_content = Dir.mktmpdir {|dir|
    certs.each { |file,content|
      open("#{dir}/#{file}", "w") { |f| f.write content }
    }
    system("cd #{dir} && tar -czf certs.tgz *.pem")
    `cat #{dir}/certs.tgz | base64`
  }

  userdata = <<EOF
#cloud-config
hostname: #{node['name']}
ssh_authorized_keys:
  - #{ssh_pubkey_content(spec)}
write_files:
  - path: "/etc/swarmer/swarmer.conf"
    permissions: "0644"
    owner: "root"
    content: |
      JOINIPADDR=#{spec['consul-joinip']}
      JOINIPADDR_WAN=#{spec['consul-joinip-wan']}
      CLUSTER_SIZE=#{spec['nodes'].find_all{ |n| consul_mode(n) == 'server'}.size}
      CONSUL_OPTS="-ui -node=#{node['name']}"
      ADMIN_NETWORK="#{spec['admin-network']}"
      PUBLIC_NETWORK="#{spec['public-network'] || spec['admin-network'] }"
      SWARM_MODE="#{swarm_mode(node)}"
      CONSUL_MODE="#{consul_mode(node)}"
      FLOCKER_MODE="#{flocker_mode(node)}"
      VOLUME_DRIVER="#{spec['volume-driver']}"
      STACK_NAME=#{spec['stack']}
      DATACENTER=#{spec['dc']}
      INFLUXDB_URL="#{spec['influxdb-url']}"
      JOURNALD_SINK="#{spec['journald-sink']}"
      # key genererated via command "consul keygen"
      CONSUL_ENCRYPT_KEY=zaC477iySMhUfu3Bp3SJBQ==
  - path: "/etc/swarmer/docker.conf.d/20-labels.conf"
    permissions: "0600"
    owner: "root"
    content: |
      DOCKER_OPTS="#{docker_labels_opts(spec,node)}"
#{flocker_agent_conf(spec)}
  - path: "/etc/swarmer/certs/certs.tar"
    permissions: "0600"
    owner: "root"
    encoding: "gzip+base64"
    content: |
#{indent_content_for_cloud_init(certs_gzip_base64_content)}
#{flocker_agent_conf(spec)}
EOF
    return userdata
end

spec = YAML.load_file(File.join(File.dirname(__FILE__), $nodes_yaml_path ))
compute_node_fields(spec)

## Generates ssh keypair
init_ssh_keypair(spec)

## Generates TLS CA CERT and Client Cert
init_tls_ca_certs(spec)

## Generates TLS Certs for every node
init_tls_nodes_certs(spec)

# Create and configure the VMs
Vagrant.configure("2") do |config|

  # Always use Vagrant's default insecure key
  config.ssh.insert_key = false
  config.ssh.username = 'core'

  config.ssh.private_key_path = if spec.key? 'private-ssh-key'
                                    spec['private-ssh-key']
                                  else
                                    "#{ENV['HOME']}/.swarmer/#{spec['stack']}/ssh-keypair"
                                  end

  spec['nodes'].each do |node|
    config.vm.define "#{spec['stack']}-#{spec['dc']}-#{node['name']}" do |srv|


      case spec['provider']
      when "aws"
        config.vm.box = "dummybox"
        config_aws_srv(srv, spec, node)
      when "virtualbox"
        config_virtualbox_srv(srv, spec, node)
      else
        puts "provider #{spec['provider']} not supported."
        exit 1
      end
    end
  end
end
