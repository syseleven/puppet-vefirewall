# class vefirewall::firewall_post() {
#
# Paramters:
#   none
#
class vefirewall::firewall_post() {
  Firewallchain {
    ensure => present,
    policy => 'drop',
    before => undef,
    notify => Exec['iptables-save-vefirewall'],
  }

  firewallchain { 'INPUT:filter:IPv4': }
  firewallchain { 'OUTPUT:filter:IPv4':
    policy => $vefirewall::output_default_policy,
  }
  firewallchain { 'FORWARD:filter:IPv4':
    policy => $vefirewall::forward_default_policy,
  }
}
