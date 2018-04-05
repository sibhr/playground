# Install altera opencl sdk

Tutorial is based on this document https://www.altera.com/en_US/pdfs/literature/hb/opencl-sdk/aocl_getting_started.pdf

Open a terminal on host with vagrant installed:

- Download altera opencl from http://dl.altera.com/opencl/?edition=standard (Login required)
- Extract file in `shared-data/altera-opencl/sdk-16.1` folder
- Run `vagrant plugin install vagrant-vbguest`
- Run `vagrant up`

In centos 7 VirtualBox
- Login with vagrant/vagrant
- Open a temrinal
- Run as vagrant user `/vagrant/shared-data/altera-opencl/sdk-16.1/setup.sh`
- Run as root `cp /home/vagrant/intelFPGA/16.1/hld/Altera.icd /etc/OpenCL/vendors/`

# Build hello word

Open a terminal on host with vagrant installed:
- run `vagrant ssh`
- run `cd /vagrant/shared-data`
- run `./hello-world.sh`
