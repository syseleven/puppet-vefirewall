# define vefirewall::vlan2_allow_internal_net
#
# Parameters:
#   none
#
define vefirewall::vlan2_allow_internal_net () {
  # also we need to explicetly allow its own internal network, no vzprivnet yet
  # -A INPUT -s $CUR_INT_NET -d $CUR_INT_NET -j ACCEPT
  # -A OUTPUT -d $CUR_INT_NET -s $CUR_INT_NET -j ACCEPT

  firewall { "130 input from $name to $name accept iptables $vefirewall::params::version":
    chain       => 'INPUT',
    proto       => 'all',
    source      => $name,
    destination => $name,
    action      => 'accept',
  }

  firewall { "130 output from $name to $name accept iptables $vefirewall::params::version":
    chain       => 'OUTPUT',
    proto       => 'all',
    source      => $name,
    destination => $name,
    action      => 'accept',
  }
}
