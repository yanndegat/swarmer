Vagrant.require_version '>= 1.6.0'
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

require_relative 'vagrant/change_host_name.rb'
require_relative 'vagrant/configure_networks.rb'
require_relative 'vagrant/base_mac.rb'

# Require 'yaml', 'fileutils', and 'erb' modules
require 'yaml'
require 'fileutils'
require 'erb'

spec = YAML.load_file(File.join(File.dirname(__FILE__), 'servers.yml'))
admin_network = spec['admin_network']
consul_joinip = spec['consul_joinip']
servers = spec['servers']

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

    # create cloud-init device
    cloudinit_img=%x[INSTANCE_ID=#{server['name']} ADMIN_NETWORK=#{admin_network} INSTANCE_IP=#{server['priv_ip']} JOINIPADDR=#{consul_joinip} CLUSTER_SIZE=#{servers.size} vagrant/cloud-init-img.sh 2>/dev/null]

    if $?.exitstatus != 0
      abort("could not create cloudconfig.")
    end

    config.vm.define server['name'] do |srv|
      srv.vm.provider :virtualbox do |v|
        v.memory = server['memory']
        v.cpus   = server['cpus']
      end
      srv.vm.synced_folder ".", "/vagrant", disabled: true
      srv.vm.hostname = server['name']
      srv.vm.box = server['box']
      # Don't check for box updates
      srv.vm.box_check_update = false

      # Assign an additional static private network
      srv.vm.network 'private_network', ip: server['priv_ip']

      srv.vm.provider :virtualbox do |v|
        v.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', cloudinit_img]
      end
    end
  end
end
