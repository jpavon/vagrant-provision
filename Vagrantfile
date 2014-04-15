Vagrant.configure("2") do |config|

    # Set server to Ubuntu 12.04
    config.vm.box = "ubuntu/precise64"
    # config.vm.box = "precise64"
    # config.vm.box_url = "http://files.vagrantup.com/precise64.box"


    # Create a static IP
    config.vm.network :private_network, ip: "192.168.33.10"


    # Synced folder
    config.vm.synced_folder ".", "/vagrant",
        id: "core",
        :mount_options => ["dmode=777","fmode=666"]


    # Optionally customize amount of RAM allocated to the VM
    config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", "512"]
    end


    # Provision
    config.vm.provision "shell", path: "provision.sh"
end
