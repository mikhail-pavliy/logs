# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

           config.vm.define "web" do |web|
                web.vm.box = "centos/7"
                web.vm.host_name = "web"
                web.vm.network "private_network", ip: '192.168.10.10'
                web.vm.provider :virtualbox do |vb|
                  vb.customize ["modifyvm", :id, "--memory", "256"]
                end
                web.vm.provision "shell", path: "web.sh"
           end

           config.vm.define "log" do |log|
                log.vm.box = "centos/7"
                log.vm.host_name = "log"
                log.vm.network "private_network", ip: '192.168.10.20'
                log.vm.provider :virtualbox do |vb|
                  vb.customize ["modifyvm", :id, "--memory", "256"]
                end
                log.vm.provision "shell", path: "log.sh"
           end
end