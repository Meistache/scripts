#!/usr/bin/env ruby

# requires

# todo:
#
# make gateway + netmask optional
# configure resolv.conf
# configure puppet (/etc/hosts or puppet.conf)
# console messages

require 'optparse'
require 'ostruct'
require 'pp'
require 'yaml'

$conffile = '/etc/libvirt/create_host.yaml'

class OptParseVirtInstall
  def self.parse(args)
    # read config file
    fileread = File.read $conffile
    options = OpenStruct.new(YAML::load fileread)


    # use virt-install --os-variant list
    # to show available options
    # for wheezy *and upwards*, "debianwheezy" must
    # be specified
    options.osvariant ="debianwheezy"

    optparse = OptionParser.new do|opts|
      opts.banner = "Usage: create_host.rb -H HOSTNAME -i IP -g GATEWAY -n NETMASK [...]"

      opts.separator ""
      opts.separator "Mandatory:"

      opts.on('-H', '--hostname HOSTNAME','Name of the host') do |h|
        options.hostname = h
      end
      opts.on('-i', '--ip IP','IPv4') do |p|
        options.ip = p
      end
      opts.on('-n', '--netmask MASK','Netmask as 255.255.255.0') do |m|
        options.netmask = m
      end
      opts.on('-g', '--gateway IP','Gateway IP') do |g|
        options.gateway = g
      end

      opts.separator ""
      opts.separator "Optional:"

      opts.on('-r', '--ram SIZE','Memory in MB default: ' + options.ram.to_s ) do |r|
        options.ram = r
      end
      opts.on('-d', '--disk SIZE','Disk Size in GB default: ' + options.disksize.to_s + 'GB') do |s|
        options.disksize = s
      end
      opts.on('--domain DOMAINNAME','domainname default: ' + options.domain) do | d|
        options.domain = d
      end
      opts.on('--pool POOL','name of pool default: ' + options.pool) do | p|
        options.pool = p
      end
      opts.on('--os-type OS','OS default: ' + options.ostype) do | o|
        options.ostype = o
      end
      opts.on('--codename CODENAME','Distribution default: ' + options.codename) do | v|
        options.codename = v
      end
      opts.on('--nameserver NAMESERVER','default: ' + options.nameserver) do | ns|
        options.nameserver = ns
      end
      opts.on('--url URL','URL of preseed file',
              'default: ' + options.url) do | u|
        options.url = u
      end
      opts.on('--bridge BRIDGE','bridge to use',
              'default: ' + options.bridge) do | b|
        options.bridge = b
      end
      opts.on('--noop','do not run virt-inst, just show what would happen') do | no|
        options.noop = true
      end
      opts.on_tail( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit
      end
    end #optparse


    optparse.parse!(args)
    raise OptionParser::MissingArgument if options.hostname.nil?
    raise OptionParser::MissingArgument if options.ip.nil?
    raise OptionParser::MissingArgument if options.netmask.nil?
    raise OptionParser::MissingArgument if options.gateway.nil?

    options
  end #parse()
end #class OptParseVirtInstall


options = OptParseVirtInstall.parse(ARGV)

virt_install_cmd = <<HERE
virt-install \
--os-type=#{options.ostype} \
--os-variant=#{options.osvariant} \
--accelerate \
--hvm \
--ram=#{options.ram} \
--disk bus=virtio,cache=none,pool=#{options.pool},size=#{options.disksize} \
-l http://httpredir.debian.org/debian/dists/#{options.codename}/main/installer-amd64/ \
--network model=virtio,bridge=#{options.bridge} \
--extra-args='console=tty0 console=ttyS0,115200n8 url=#{options.url} interface=eth0 \ hostname=#{options.hostname} domain=#{options.domain} netcfg/get_ipaddress=#{options.ip} netcfg/get_netmask=#{options.netmask} netcfg/get_gateway=#{options.gateway} netcfg/get_nameservers=#{options.nameserver} netcfg/disable_dhcp=true auto=true' \
--graphics none \
--name #{options.hostname}.#{options.domain}
HERE


if options.noop == false
  output=system(virt_install_cmd)
  pp output
else
  pp virt_install_cmd
end
