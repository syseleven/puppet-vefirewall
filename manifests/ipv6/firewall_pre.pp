# class vefirewall::ipv6::firewall_pre
#
# WARNING: currently purge is not supported for ipv6 https://tickets.puppetlabs.com/browse/MODULES-41
#
# Parameters:
#   none
#
class vefirewall::ipv6::firewall_pre() {
  # this workaround is needed
  Firewall {
    provider => 'ip6tables',
    require  => undef,
  }

  firewall { "001 input lo accept ip6tables $vefirewall::params::version6":
    chain   => 'INPUT',
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }

  firewall { "002 ICMPv6 128 $vefirewall::params::version6":
    chain  => 'INPUT',
    proto  => 'ipv6-icmp',
    icmp   => '128',
    action => 'accept',
  }

  firewall { "002 ICMPv6 135 $vefirewall::params::version6":
    chain  => 'INPUT',
    proto  => 'ipv6-icmp',
    icmp   => '135',
    action => 'accept',
  }

  firewall { "002 ICMPv6 136 $vefirewall::params::version6":
    chain  => 'INPUT',
    proto  => 'ipv6-icmp',
    icmp   => '136',
    action => 'accept',
  }

  if versioncmp($::kernelversion, '2.6.19') < 0 {
    firewall { "030 input all related established accept deprecated kernel ip6tables $vefirewall::params::version6":
      chain  => 'INPUT',
      proto  => 'all',
      state  => ['RELATED', 'ESTABLISHED'],
      action => 'accept',
    }
  } else {
    firewall { "030 input all related established accept ip6tables $vefirewall::params::version6":
      chain   => 'INPUT',
      proto   => 'all',
      ctstate => ['RELATED', 'ESTABLISHED'],
      action  => 'accept',
    }
  }
}
