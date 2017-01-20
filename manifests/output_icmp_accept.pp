# define firewall_output_icmp_X_accept
#
# Parameters:
#   none
#
define vefirewall::output_icmp_accept() {
  firewall { "070 output icmp ${name} accept iptables ${vefirewall::params::version}":
    chain  => 'OUTPUT',
    proto  => 'icmp',
    icmp   => $name,
    action => 'accept',
  }
}
