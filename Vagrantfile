Vagrant.require_version '>= 1.6.0'

require 'yaml'
require 'tempfile'
require 'socket'

server_yaml_path = ENV["SERVER_YML"] || "./servers.yml"

spec = YAML.load_file(File.join(File.dirname(__FILE__), server_yaml_path ))

box = spec['box'] || "yanndegat/swarmer"
admin_network = spec['admin_network']
docker_registry = spec['docker_registry']
servers = spec['servers']
consul_joinip = servers.first['priv_ip']
host_ip = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address

vol_dir="#{Dir.pwd}/vbox_volumes"

# Start vbox remote control server
if ARGV[0] == 'up' || ARGV[0] == 'destroy'
  system "killall vboxwebsrv"
end
if ARGV[0] == 'up'
  system "mkdir -p #{vol_dir}"
  system "VBoxManage setproperty websrvauthlibrary null"
  system "vboxwebsrv -H 0.0.0.0 -b"
end

# Create and configure the VMs
Vagrant.configure("2") do |config|

  # Always use Vagrant's default insecure key
  config.ssh.insert_key = false
  config.ssh.username = 'core'

  config.vm.provider :virtualbox do |v|
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  servers.each do |server|
    userdata = <<EOF
#cloud-config
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
write_files:
  - path: "/etc/rexray/config.yml"
    permissions: "0644"
    owner: "root"
    content: |
      rexray:
        storageDrivers:
          - virtualbox
      virtualbox:
        endpoint: http://#{host_ip}:18083
        volumePath: "#{vol_dir}"
  - path: "/etc/swarmer/swarmer.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export JOINIPADDR=#{consul_joinip}
      export CLUSTER_SIZE=#{servers.size}
      export CONSUL_OPTS="-ui -node=#{server['name']} -dc=vagrant"
      export ADMIN_NETWORK="#{admin_network}"
      export PUBLIC_NETWORK="#{admin_network}"
      export SWARM_MODE="both"
EOF

    userdata_file = Tempfile.new(server['name'])
    userdata_file.write userdata
    userdata_file.close

    config.vm.define server['name'] do |srv|
      srv.vm.provider :virtualbox do |v|
        v.memory = server['memory']
        v.cpus   = server['cpus']
      end
      srv.vm.synced_folder ".", "/vagrant", disabled: true
      srv.vm.hostname = server['name']
      srv.vm.box = box
      # Don't check for box updates
      srv.vm.box_check_update = false

      # Assign an additional static private network
      srv.vm.network 'private_network', ip: server['priv_ip']

      srv.vm.provision :file, :source => userdata_file.path(), :destination => "/tmp/vagrantfile-user-data"
      srv.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
    end
  end
end
