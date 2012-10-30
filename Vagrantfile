Vagrant::Config.run do |config|

  config.vm.host_name = "lamp-dev"

  # Our packaged basebox should be based of Ubuntu 12.04 64bit.

  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  # Initialize host-only networking.

  config.vm.network :hostonly, "10.0.1.10"

  # Forward HTTP requests.

  config.vm.forward_port 80, 8080

  # Provision the box with a shell script.

  Vagrant::Config.run do |config|
    config.vm.provision :shell, :path => "provision/provision.sh"
  end

end