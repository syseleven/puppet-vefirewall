# Class: vefirewall::ipv6::service
#
# Parameters:
#
class vefirewall::ipv6::service () {

  if $::osfamily == 'RedHat' {
    file { '/etc/sysconfig/ip6tables':
      ensure  => file,
      content => "# NOT USED. See /var/cache/ip6tables-rules.save!!!\n",
      mode    => '0444',
      owner   => root,
      group   => root,
    }
    file { '/etc/sysconfig/ip6tables.save':
      ensure  => file,
      content => "# NOT USED. See /var/cache/ip6tables-rules.save!!!\n",
      mode    => '0444',
      owner   => root,
      group   => root,
    }
  }

  service { 'firewall6':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Anchor['init6-reload'],
  }

}
