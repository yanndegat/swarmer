Vagrant.require_version '>= 1.6.0'

require 'yaml'
require 'tempfile'
require 'socket'

$certs_path = ENV['SWARMER_CERTSV_DIR'] || "#{ENV['HOME']}/.swarmer"
server_yaml_path = ENV["SWARMER_SERVER_YML"] || "./servers.yml"
$spec = YAML.load_file(File.join(File.dirname(__FILE__), server_yaml_path ))
$stack = $spec['stack']
$dc = $spec['dc']
$box = $spec['box'] || "yanndegat/swarmer"
$admin_network = $spec['admin_network']
$nodes = $spec['nodes']
$consul_joinip = $nodes.first['ip']

def init_tls_ca_certs ()
  host_ip = `./bin/ipforroute #{$admin_network}`
  init_certs_files = ["ca", "client-#{host_ip}"].flat_map{ |c| ["#{$certs_path}/#{$stack}/#{$dc}/#{c}.pem","#{$certs_path}/#{$stack}/#{$dc}/#{c}-key.pem"]}
  if not init_certs_files.map{ |f| File.file?(f) }.reduce{|r,c| r && c }
    puts "generating ca cert and cert for client #{host_ip}"
    init = system("./bin/init-certs #{$stack} #{$dc} #{host_ip}")
    if not init
      puts "failed to init ca certificates"
      exit 1
    end
  end
end

def init_tls_nodes_certs()
  nodes_certs_files = $nodes.flat_map{ |s| ["#{$certs_path}/#{$stack}/#{$dc}/#{s['name']}.pem","#{$certs_path}/#{$stack}/#{$dc}/#{s['name']}-key.pem"]}
  if not nodes_certs_files.map{ |f| File.file?(f) }.reduce{|r,c| r && c }
    puts "generating certs for nodes: #{$nodes.map{ |s| s['name'] }.join(' ')}"
    init_nodes = system("./bin/node-certs #{$stack} #{$dc} #{$nodes.map{ |s| s['name'] }.join(' ')}")
    if not init_nodes
      puts "failed to init nodes certificates"
      exit 1
    end
  end
end

def indent_file_content_for_cloud_init (file_name)
  IO.read(file_name).split("\n").collect{|line| "     #{line}"}.join("\n")
end

def cert_content_for_userdata(cert)
  indent_file_content_for_cloud_init( "#{$certs_path}/#{$stack}/#{$dc}/#{cert}.pem")
end

def cert_key_content_for_userdata(cert)
  indent_file_content_for_cloud_init( "#{$certs_path}/#{$stack}/#{$dc}/#{cert}-key.pem")
end

def userdata(node)
    userdata = <<EOF
#cloud-config
hostname: #{node}
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
write_files:
  - path: "/etc/swarmer/swarmer.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export JOINIPADDR=#{$consul_joinip}
      export CLUSTER_SIZE=#{$nodes.size}
      export CONSUL_OPTS="-ui -node=#{node}"
      export ADMIN_NETWORK="#{$admin_network}"
      export PUBLIC_NETWORK="#{$admin_network}"
      export SWARM_MODE="both"
      export VOLUME_DRIVER=none
      export STACK_NAME=#{$stack}
      export DATACENTER=#{$dc}
      # key genererated via command "consul keygen"
      export CONSUL_ENCRYPT_KEY=zaC477iySMhUfu3Bp3SJBQ==
  - path: "/etc/swarmer/certs/ca.pem"
    permissions: "0600"
    owner: "root"
    content: |
#{cert_content_for_userdata('ca')}
  - path: "/etc/swarmer/certs/node.pem"
    permissions: "0600"
    owner: "root"
    content: |
#{cert_content_for_userdata(node)}
  - path: "/etc/swarmer/certs/node-key.pem"
    permissions: "0600"
    owner: "root"
    content: |
#{cert_key_content_for_userdata(node)}
EOF
    return userdata
end

## Generates TLS CA CERT and Client Keypair
init_tls_ca_certs()

## Generates TLS Keypair for every node
init_tls_nodes_certs()

# Create and configure the VMs
Vagrant.configure("2") do |config|

  # Always use Vagrant's default insecure key
  config.ssh.insert_key = false
  config.ssh.username = 'core'

  config.vm.provider :virtualbox do |v|
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  $nodes.each do |server|

    config.vm.define server['name'] do |srv|
      srv.vm.provider :virtualbox do |v|
        v.memory = server['memory']
        v.cpus   = server['cpus']
      end
      srv.vm.synced_folder ".", "/vagrant", disabled: true
      srv.vm.hostname = server['name']
      srv.vm.box = $box
      # Don't check for box updates
      srv.vm.box_check_update = false

      # Assign an additional static private network
      srv.vm.network 'private_network', ip: server['ip']

      userdata_file = Tempfile.new(server['name'])
      userdata_file.write userdata(server['name'])
      userdata_file.close

      srv.vm.provision :file, :source => userdata_file.path(), :destination => "/tmp/vagrantfile-user-data"
      srv.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
    end
  end
end
