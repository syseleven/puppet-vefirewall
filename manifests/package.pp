# Class: vefirewall::package
#
# Parameters:
#
class vefirewall::package () {

  if $::osfamily == 'Debian' {
    # Preconfigure iptables-save package _not_ to save existing iptables rules
    # upon installation (which is its default setting). Otherwise package
    # installation will fail. Package options are recorded in
    # files/iptables-persistent.preseed.
    case $::operatingsystemrelase {
      '16.04': {
        $service_name = 'netfilter-persistent'
      }
      default: {
        $service_name = 'iptables-persistent'
      }
    }

    file { '/var/cache/apt/iptables-persistent.preseed':
      mode   => '0600',
      source => "puppet:///modules/${module_name}/iptables-persistent.preseed"
      }

    package { 'iptables-persistent':
      ensure       => installed,
      alias        => 'iptables-persistent',
      responsefile => '/var/cache/apt/iptables-persistent.preseed',
      require      => File['/var/cache/apt/iptables-persistent.preseed'],
    }

    # We need to disable iptables-persistent, since this conflicts with our
    # /etc/init.d/firewall
    service { $service_name:
      ensure    => stopped,
      alias     => 'iptables-persistent',
      enable    => false,
      hasstatus => false,
      require   => Package['iptables-persistent'],
    }
  } elsif $::osfamily == 'RedHat' {
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
