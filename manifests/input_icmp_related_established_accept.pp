# define vefirewall::input_icmp_related_established_accept
#
# Paramters:
#   none
#
define vefirewall::input_icmp_related_established_accept() {
  if versioncmp($::kernelversion, '2.6.19') < 0 {
    firewall { "010 input icmp relayed established ${name} accept depcrecated kernel iptables ${vefirewall::params::version}":
        chain  => 'INPUT',
        proto  => 'icmp',
        state  => ['RELATED','ESTABLISHED'],
        icmp   => $name,
        action => 'accept',
      }
  } else {
    firewall { "010 input icmp relayed established ${name} accept iptables ${vefirewall::params::version}":
        chain   => 'INPUT',
        proto   => 'icmp',
        ctstate => ['RELATED','ESTABLISHED'],
        icmp    => $name,
        action  => 'accept',
      }
  }
}
