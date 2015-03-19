# class vefirewall::ipv6::firewall_post() {
#
# Paramters:
#   none
#
class vefirewall::ipv6::firewall_post() {
  Firewallchain {
    ensure => present,
    policy => 'drop',
    before => undef,
    notify => Exec['ip6tables-save-vefirewall'],
  }

  firewallchain { 'INPUT:filter:IPv6': }
  firewallchain { 'OUTPUT:filter:IPv6':
    policy => $vefirewall::ipv6::output_default_policy,
  }
  firewallchain { 'FORWARD:filter:IPv6':
    policy => 'accept',
  }
}


