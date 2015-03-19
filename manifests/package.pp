# Class: vefirewall::package
#
# Parameters:
#
class vefirewall::package () {

  if $::operatingsystem == 'gentoo' {

  if $vefirewall::iptables_useflags {
    gentoo::useflag { $vefirewall::package:
    flags => $vefirewall::iptables_useflags,
      }
    }
  } elsif $::osfamily == 'debian' {
    # Preconfigure iptables-save package _not_ to save existing iptables rules
    # upon installation (which is its default setting). Otherwise package
    # installation will fail. Package options are recorded in
    # files/iptables-persistent.preseed.

    file { '/var/cache/apt/iptables-persistent.preseed':
      mode   => '0600',
      source => "puppet:///modules/$module_name/iptables-persistent.preseed"
      }

    package { 'iptables-persistent':
      ensure       => installed,
      alias        => 'iptables-persistent',
      responsefile => '/var/cache/apt/iptables-persistent.preseed',
      require      => File['/var/cache/apt/iptables-persistent.preseed'],
    }

    # We need to disable iptables-persistent, since this conflicts with our
    # /etc/init.d/firewall
    service { 'iptables-persistent':
      ensure    => stopped,
      enable    => false,
      hasstatus => false,
      require   => Package['iptables-persistent'],
    }
  } elsif $::osfamily == 'redhat' {
    service { 'iptables':
      ensure    => stopped,
      enable    => false,
      hasstatus => false,
      require   => Package[$vefirewall::params::iptables_package],
    }

    # just in case firewalld is running
    ensure_resource('service', 'firewalld', {
      ensure => stopped,
      enable => false,
    })
  }

  package { $vefirewall::params::iptables_package:
    ensure => installed,
    alias  => 'iptables',
  }
}
