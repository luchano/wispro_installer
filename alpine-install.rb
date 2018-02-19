#!/usr/bin/env ruby
require 'mrdialog' 
require 'pp'
require 'ipaddr'

RESOLV_CONF_FILE="resolv.conf"
INTERFACES_FILE="interfaces"
HEIGHT = 16
WIDTH = 51
DEFAULT_IP = "192.168.0.2"
DEFAULT_NETMASK = "255.255.255.0"
DEFAULT_GATEWAY = "192.168.0.1"
DEFAULT_PRIMARY_DNS = "8.8.8.8"
DEFAULT_SECONDARY_DNS = "8.8.4.4"
def configure_network
  def valid_ip? address
    IPAddr.new address
  end
  dialog = MRDialog.new
  #dialog.logger = Logger.new(ENV["HOME"] + "/dialog_" + ME + ".log")
  dialog.clear = true

  dialog.title = "Configuración de red"

  available_interfaces=[]
  `ls -1 /sys/class/net`.split("\n").each do |i| available_interfaces << [i] end
  interface = dialog.menu("Seleccione la interfaz de red a configurar", available_interfaces, HEIGHT, WIDTH, available_interfaces.size)
  return false unless interface

  method = dialog.menu("Seleccione el método de configuración", [["dchp"], ["manual"]], HEIGHT, WIDTH, 2)
  return false unless method
  if method == "manual"
    ip=nil;netmask=nil;gateway=nil;primary_dns=nil;secondary_dns=nil;errors=nil
    begin
      form_items = []
      form_items << ["Dirección IP", 1, 1, ip || DEFAULT_IP, 1, 20, 15, 0]
      form_items << ["Máscara de red", 2, 1, netmask || DEFAULT_NETMASK, 2, 20, 15, 0]
      form_items << ["Puerta de enlace(default gateway)", 3, 1, gateway || DEFAULT_GATEWAY, 3, 20, 15, 0]
      form_items << ["DNS primario", 4, 1, primary_dns || DEFAULT_PRIMARY_DNS, 4, 20, 15, 0]
      form_items << ["DNS secundario", 5, 1, secondary_dns || DEFAULT_SECONDARY_DNS, 5, 20, 15, 0]
      result = dialog.form("Ingrese los datos requeridos#{errors}", form_items, 20, 50, 0)
      ip = valid_ip? result.values[0]
      netmask = valid_ip? result.values[1]
      gateway = valid_ip? result.values[2]
      primary_dns = valid_ip? result.values[3]
      secondary_dns = valid_ip? result.values[4]
    rescue
      errors = "(Formato inválido)"
      retry
    end
    return false unless ip and netmask and gateway and primary_dns and secondary_dns
    File.open(INTERFACES_FILE, 'w') do |f|
      f.puts "auto #{interface}"
      f.puts "iface #{interface} inet static"
      f.puts "  address #{ip}"
      f.puts "  netmask #{netmask}"
      f.puts "  gateway #{gateway}"
    end
    File.open(RESOLV_CONF_FILE, 'w') do |f|
      f.puts "nameserver #{primary_dns}"
      f.puts "nameserver #{secondary_dns}"
    end
  else #dhcp
    File.open(INTERFACES_FILE, 'w') do |f|
      f.puts "auto #{interface}"
      f.puts "iface #{interface} inet dhcp"
    end
  end
  #puts "Result is: #{interface} #{method} #{ip} #{netmask} #{gateway} #{primary_dns} #{secondary_dns}"
  true
rescue => e
  puts "#{$!}"
  t = e.backtrace.join("\n\t")
  puts "Error: #{t}"
end
def configure_disks
  dialog = MRDialog.new
  dialog.clear = true
  dialog.title = "Configuración de discos"

  available_disks=[]
  `./find_disks.sh`.split("\n").each do |d| available_disks << [d] end
  disk = dialog.menu("Seleccione el disco a instalar", available_disks, HEIGHT, WIDTH, 2)
  return false unless disk
  puts disk
  true
end
configure_network and configure_disks
