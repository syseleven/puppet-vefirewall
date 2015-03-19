# Class: vefirewall::service
#
# Parameters:
#
class vefirewall::service () {

  if $::osfamily == 'RedHat' {
    file { '/etc/sysconfig/iptables':
      ensure  => file,
      content => "# NOT USED. See /var/cache/iptables-rules.save!!!\n",
      mode    => '0444',
      owner   => root,
      group   => root,
    }
    file { '/etc/sysconfig/iptables.save':
      ensure  => file,
      content => "# NOT USED. See /var/cache/iptables-rules.save!!!\n",
      mode    => '0444',
      owner   => root,
      group   => root,
    }
  }

  service { 'firewall':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Anchor['init-reload'],
  }

}
