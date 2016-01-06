# class vefirewall::firewall_pre
#
# Parameters:
#   none
#
class vefirewall::firewall_pre() {
  # this workaround is needed
  Firewall {
    require => undef,
  }

  # https://youtrack.syseleven.de/issue/pp-1020
  # we need older conntrack state if linux < 2.6.18
  # https://youtrack.syseleven.de/issue/pp-1222
  # ...or if we are running on a Ubuntu (12.04 LTS, at least...) VE.

  # The below code doesn't actually serve any semantic purpose since we can't
  # use variables in keys, but we'll leave it in to illustrate the problem.

  if versioncmp($::kernelversion, '2.6.19') < 0 {
    $state = 'state'
  } else {
    $state = 'ctstate'
  }

  if $::sys11vlan == '2' {
    # vlan2 needs to have this NAT rule for the VE to have internet if there is an external IP
    # -t nat -A POSTROUTING -o venet0 ! -d 10.0.0.0/8 -j SNAT --to $EXTIP

    # assuming you have an external IP and need SNAT
    if $vefirewall::vlan2_outgoing_ip {
      firewall  { "000 nat postrouting venet0 not 10.0.0.0/8 snat to ${vefirewall::vlan2_outgoing_ip} iptables ${vefirewall::params::version}":
        table       => 'nat',
        chain       => 'POSTROUTING',
        proto       => 'all',
        outiface    => 'venet0',
        destination => '! 10.0.0.0/8',
        jump        => 'SNAT',
        tosource    => $vefirewall::vlan2_outgoing_ip,
      }
    }

    # also we need to explicetly allow its own internal network, no vzprivnet yet
    if $vefirewall::vlan2_allow_default_internal_net_access {
      $parts = split($::ipaddress_internal, '[.]')
      $first = values_at($parts, 0)
      $second = values_at($parts, 1)
      $third = values_at($parts, 2)
      $internal_net = "${first}.${second}.${third}.0/24"


      vefirewall::vlan2_allow_internal_net { $internal_net: }
    }

    if $vefirewall::vlan2_additional_internal_nets {
      vefirewall::vlan2_allow_internal_net { $vefirewall::vlan2_additional_internal_nets: }
    }
  }

  firewall { "001 input lo accept iptables ${vefirewall::params::version}":
    chain   => 'INPUT',
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }

  if $vefirewall::accept_input_on_internal_network {
    firewall { "002 input 10.0.0.0/8 to 10.0.0.0/8 accept iptables ${vefirewall::params::version}":
      chain       => 'INPUT',
      proto       => 'all',
      source      => '10.0.0.0/8',
      destination => '10.0.0.0/8',
      action      => 'accept',
    }
  }

  if $vefirewall::accept_output_on_internal_network {
    firewall { "003 output 10.0.0.0/8 to 10.0.0.0/8 accept iptables ${vefirewall::params::version}":
      chain       => 'OUTPUT',
      proto       => 'all',
      source      => '10.0.0.0/8',
      destination => '10.0.0.0/8',
      action      => 'accept',
    }
  }

  firewall { "004 input icmp 8 accept iptables ${vefirewall::params::version}":
    chain  => 'INPUT',
    proto  => 'icmp',
    icmp   => '8',
    action => 'accept',
  }

  # define vefirewall::firewall_input_icmp_related_established_X_accept
  #
  # Paramters:
  #   none
  #
  define firewall_input_icmp_related_established_X_accept() {
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
  firewall_input_icmp_related_established_X_accept { $vefirewall::icmp_related_list: }

  firewall { "020 input tcp drop sync rst ack sync iptables ${vefirewall::params::version}":
    chain     => 'INPUT',
    proto     => 'tcp',
    dport     => '1024-65535',
    tcp_flags => '! SYN,RST,ACK SYN',
    action    => 'accept',
  }

  if $vefirewall::accept_udp_high_ports {
    firewall { "022 input udp accept iptables ${vefirewall::params::version}":
      chain  => 'INPUT',
      proto  => 'udp',
      dport  => '1024-65535',
      action => 'accept',
    }
  }

  if $vefirewall::accept_tcp_60000_60100 {
    # TODO what is that needed for?
    if versioncmp($::kernelversion, '2.6.19') < 0 {
      firewall { "030 input tcp new related established 60000-60100 deprecated kernel iptables ${vefirewall::params::version}":
        chain  => 'INPUT',
        proto  => 'tcp',
        state  => ['NEW', 'RELATED', 'ESTABLISHED'],
        dport  => '60000-60100',
        action => 'accept',
      }
    } else {
      firewall { "030 input tcp new related established 60000-60100 iptables ${vefirewall::params::version}":
        chain   => 'INPUT',
        proto   => 'tcp',
        ctstate => ['NEW', 'RELATED', 'ESTABLISHED'],
        dport   => '60000-60100',
        action  => 'accept',
      }
    }
  }

  if versioncmp($::kernelversion, '2.6.19') < 0 {
    firewall { "040 input tcp related established accept deprecated kernel iptables ${vefirewall::params::version}":
      chain  => 'INPUT',
      proto  => 'tcp',
      state  => ['RELATED', 'ESTABLISHED'],
      action => 'accept',
    }
  } else {
    firewall { "040 input tcp related established accept iptables ${vefirewall::params::version}":
      chain   => 'INPUT',
      proto   => 'tcp',
      ctstate => ['RELATED', 'ESTABLISHED'],
      action  => 'accept',
    }
  }
  if versioncmp($::kernelversion, '2.6.19') < 0 {
    firewall { "041 input udp related established accept deprecated kernel iptables ${vefirewall::params::version}":
      chain  => 'INPUT',
      proto  => 'udp',
      state  => ['RELATED', 'ESTABLISHED'],
      action => 'accept',
    }
  } else {
    firewall { "041 input udp related established accept iptables ${vefirewall::params::version}":
      chain   => 'INPUT',
      proto   => 'udp',
      ctstate => ['RELATED', 'ESTABLISHED'],
      action  => 'accept',
    }
  }

  firewall { "050 input icmp echo-request accept iptables ${vefirewall::params::version}":
    chain  => 'INPUT',
    proto  => 'icmp',
    icmp   => 'echo-request',
    action => 'accept',
  }

  firewall { "060 output lo accept iptables ${vefirewall::params::version}":
    chain    => 'OUTPUT',
    proto    => 'all',
    outiface => 'lo',
    action   => 'accept',
  }

  # define firewall_output_icmp_X_accept
  #
  # Parameters:
  #   none
  #
  define firewall_output_icmp_X_accept() {
    firewall { "070 output icmp ${name} accept iptables ${vefirewall::params::version}":
      chain  => 'OUTPUT',
      proto  => 'icmp',
      icmp   => $name,
      action => 'accept',
    }
  }

  firewall_output_icmp_X_accept { $vefirewall::output_icmp_list: }

  if versioncmp($::kernelversion, '2.6.19') < 0 {
    firewall { "030 output all related established accept depcrecated kernel iptables ${vefirewall::params::version}":
      chain  => 'OUTPUT',
      proto  => 'all',
      state  => ['RELATED', 'ESTABLISHED'],
      action => 'accept',
    }
  } else {
    firewall { "030 output all related established accept iptables ${vefirewall::params::version}":
      chain   => 'OUTPUT',
      proto   => 'all',
      ctstate => ['RELATED', 'ESTABLISHED'],
      action  => 'accept',
    }
  }


}

#-A INPUT -i lo -j ACCEPT
#-A INPUT -s 10.0.0.0/8 -d 10.0.0.0/8 -j ACCEPT
#-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
#-A INPUT -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0 -j ACCEPT
#-A INPUT -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 3 -j ACCEPT
#-A INPUT -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 11 -j ACCEPT
#-A INPUT -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 12 -j ACCEPT
#-A INPUT -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 14 -j ACCEPT
#-A INPUT -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 18 -j ACCEPT
#-A INPUT -s 10.0.10.111/32 -p tcp -m conntrack --ctstate NEW,RELATED,ESTABLISHED -m tcp --dport 10050 -j ACCEPT
#-A INPUT -s 10.3.20.41/32 -p tcp -m conntrack --ctstate NEW,RELATED,ESTABLISHED -m tcp --dport 10050 -j ACCEPT
#-A INPUT -p tcp -m tcp --dport 1024:65535 ! --tcp-flags SYN,RST,ACK SYN -j ACCEPT
#-A INPUT -p udp -m udp --dport 1024:65535 -j ACCEPT
#-A INPUT -p tcp -m conntrack --ctstate NEW,RELATED,ESTABLISHED -m tcp --dport 60000:60100 -j ACCEPT
#-A INPUT -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
#-A OUTPUT -o lo -j ACCEPT
#-A OUTPUT -s 10.0.0.0/8 -d 10.0.0.0/8 -j ACCEPT
#-A OUTPUT -p icmp -m icmp --icmp-type 11 -j ACCEPT
#-A OUTPUT -p icmp -m icmp --icmp-type 3/3 -j ACCEPT
#-A OUTPUT -p icmp -m icmp --icmp-type 3/4 -j ACCEPT
#-A OUTPUT -p icmp -m icmp --icmp-type 3/9 -j ACCEPT
#-A OUTPUT -p icmp -m icmp --icmp-type 3/10 -j ACCEPT
#-A OUTPUT -p icmp -m icmp --icmp-type 3/13 -j ACCEPT
#-A OUTPUT -p icmp -m icmp --icmp-type 3 -j ACCEPT
#-A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
