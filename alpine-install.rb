#!/usr/bin/env ruby
require 'mrdialog' 
require 'pp'
require 'ipaddr'

RESOLV_CONF_FILE="resolv.conf"
INTERFACES_FILE="interfaces"
ALPINE_ANSWERS_FILE="answers"
HEIGHT = 16
WIDTH = 51
class DialogConfigNet
  DEFAULT_IP = "192.168.0.2"
  DEFAULT_NETMASK = "255.255.255.0"
  DEFAULT_GATEWAY = "192.168.0.1"
  DEFAULT_PRIMARY_DNS = "8.8.8.8"
  DEFAULT_SECONDARY_DNS = "8.8.4.4"
  def valid_ip? address
    IPAddr.new address
  end
  def available_interfaces
    @_interfaces ||= `ls -1 /sys/class/net`.split("\n").map do|i| [i] end
  end
  def ask_values
    dialog = MRDialog.new
    #dialog.logger = Logger.new(ENV["HOME"] + "/dialog_" + ME + ".log")
    dialog.clear = true

    dialog.title = "Configuración de red"

    @interface = dialog.menu("Seleccione la interfaz de red a configurar", available_interfaces, HEIGHT, WIDTH, available_interfaces.size)
    return false unless @interface

    @method = dialog.menu("Seleccione el método de configuración", [["dchp"], ["manual"]], HEIGHT, WIDTH, 2)
    return false unless @method
    if @method == "manual"
      @ip=nil;@netmask=nil;@gateway=nil;@primary_dns=nil;@secondary_dns=nil;@errors=nil
      begin
        form_items = []
        form_items << ["Dirección IP", 1, 1, @ip || DEFAULT_IP, 1, 20, 15, 0]
        form_items << ["Máscara de red", 2, 1, @netmask || DEFAULT_NETMASK, 2, 20, 15, 0]
        form_items << ["Puerta de enlace(default gateway)", 3, 1, @gateway || DEFAULT_GATEWAY, 3, 20, 15, 0]
        form_items << ["DNS primario", 4, 1, @primary_dns || DEFAULT_PRIMARY_DNS, 4, 20, 15, 0]
        form_items << ["DNS secundario", 5, 1, @secondary_dns || DEFAULT_SECONDARY_DNS, 5, 20, 15, 0]
        result = dialog.form("Ingrese los datos requeridos#{@errors}", form_items, 20, 50, 0)
        @ip = valid_ip? result.values[0]
        @netmask = valid_ip? result.values[1]
        @gateway = valid_ip? result.values[2]
        @primary_dns = valid_ip? result.values[3]
        @secondary_dns = valid_ip? result.values[4]
      rescue
        @errors = "(Formato inválido)"
        retry
      end
      return false unless @ip and @netmask and @gateway and @primary_dns and @secondary_dns
    end
    true
  end
  def to_config
    a =if @method == "manual"
      <<-END
auto #{@interface}
  iface #{@interface} inet static
  address #{@ip}
  netmask #{@netmask}
  gateway #{@gateway}
      END
    else
      <<-END
auto #{@interface}
  iface #{@interface} inet dhcp
      END
    end
  end
end
#    File.open(RESOLV_CONF_FILE, 'w') do |f|
#      f.puts "nameserver #{primary_dns}"
#      f.puts "nameserver #{secondary_dns}"
#    end
  #puts "Result is: #{interface} #{method} #{ip} #{netmask} #{gateway} #{primary_dns} #{secondary_dns}"
#rescue => e
#  puts "#{$!}"
#  t = e.backtrace.join("\n\t")
#  puts "Error: #{t}"
#end
class DialogConfigDisks
  def ask_values
    dialog = MRDialog.new
    dialog.clear = true
    dialog.title = "Configuración de discos"

    @disk = dialog.menu("Seleccione el disco a instalar", available_disks, HEIGHT, WIDTH, available_disks.size)
    return false unless @disk
    true
  end
  def available_disks
    @disks ||= `/etc/wispro/wispro_installer/find_disks.sh`.split("\n").map do |d| [d] end
  end
  def to_config
    "-m sys /dev/#{@disk}"
  end
end
#configure_network and configure_disks
net = DialogConfigNet.new
disk = DialogConfigDisks.new
if net.ask_values
  if disk.ask_values
    File.open(ALPINE_ANSWERS_FILE, 'w') do |f|
      f.puts "KEYMAPOPTS='us us'"
      f.puts "HOSTNAMEOPTS='-n wispro-host'"
      f.puts "INTERFACESOPTS='#{net.to_config}'"
      f.puts "DNSOPTS='-d example.com 8.8.8.8 8.8.4.4'"
      f.puts "TIMEZONEOPTS='-z UTC'"
      f.puts "PROXYOPTS='none'"
      f.puts "APKREPOSOPTS='http://dl-cdn.alpinelinux.org/alpine/v3.6/main
http://dl-cdn.alpinelinux.org/alpine/v3.6/community
https://dl-3.alpinelinux.org/alpine/v3.6/main
https://dl-3.alpinelinux.org/alpine/v3.6/community
'"
      f.puts "SSHDOPTS='-c openssh'"
      f.puts "NTPOPTS='-c chrony'"
      f.puts "DISKOPTS='#{disk.to_config}'"
    end
  else
    puts "Error en diálogo de la configuración de discos"
  end
else
  puts "Error en diálogos de configuración de red"
end
