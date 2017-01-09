# class vefirewall::ipv6
#
# This class fully configures the firewall (ipv6) of an sys11 host.
#
# Paramters:
#   $host_trusted_services = [],
#     List of services to be allowed for certain hosts, protocols, ports and chain
#   $host_ext_services = [],
#     List of services to be allowed all incoming traffic on a certain IP, protocol and port.
#     By using 'external' or 'internal' as IP, the first automatically discovered IP address is used.
#     By using 'external_all' all external ip addresses are used.
#   $allow_input_from_networks = undef,
#     Set this to a list of networks (e.g. '10.21.0.0/24') to do iptables -I INPUT -s $network -j ACCEPT
#   $output_default_policy = 'accept',
#     This set the default output_police to given value
#   $force_migration = true
#     true will flush all rules before new rules are applied.
#
# Sample usage:
#   vefirewall:
#     host_trusted_services:
#       - 2001:db8::/32,tcp,80
#       - 2001:db8:2000:16::/64,tcp,80-89
#       - 2001:db8:2000:16::/64,tcp,80-89
#       - 2001:db8:4000:3:2:128:0:1,tcp,53,OUTPUT
#     host_ext_services:
#       - 2001:db8:4000:3:2:128:0:1,tcp,ssh
#
class vefirewall::ipv6(
  $host_trusted_services = [],
  $host_ext_services = [],
  $allow_input_from_networks = undef,
  $output_default_policy = 'accept',
  $force_migration = false,
) inherits vefirewall::params {

  require vefirewall::ipv6::package

  if $::osfamily == 'RedHat' and versioncmp($::operatingsystemmajrelease, '6') > 0 {
    ensure_resource('exec', 'systemctl daemon-reload', {
      path        => '/bin:/usr/bin:/sbin:/usr/sbin',
      refreshonly => true,
    })
    $notify_init_script = [Exec['ip6tables-save-vefirewall'], Exec['systemctl daemon-reload']]
    # hack to ensure daemon-reload occurs before service start
    anchor { 'init6-reload':
      require => Exec['systemctl daemon-reload'],
    }
  } else {
    $notify_init_script = Exec['ip6tables-save-vefirewall']
    # nothing to do here. BUT service fireall requires this anchor!!!
    anchor { 'init6-reload':
    }
  }

  #
  # HACK
  # This is because of too much bash magic in $vefirewall::params::init_script
  # it can not be used as template.
  # But. We need almost the same code twice. Once for iptables and once for iptables6.
  # It is not enough to try to detect the call path in this script, because the helper
  # comments for upstart have to differ between v4 and v6 too.
  #
  # But... I do not want to have the code logic duplicated.
  #
  concat { '/etc/init.d/firewall6':
    ensure => present,
    mode   => '0544',
    notify => $notify_init_script,
    before => Service['firewall6'],
  }

  concat::fragment { 'headv6':
    target => '/etc/init.d/firewall6',
    source => "${vefirewall::params::init_script}.v6",
    order  => '01',
  }

  concat::fragment { 'scriptv6':
    target => '/etc/init.d/firewall6',
    source => $vefirewall::params::init_script,
    order  => '02',
  }
  # /HACK

  exec { 'ip6tables-save-vefirewall':
    command     => 'ip6tables-save > /var/cache/ip6tables-rules.save',
    path        => '/sbin/:/bin/:/usr/sbin/',
    refreshonly => true,
    before      => Service['firewall6'],
  }

  if !defined(Class['vefirewall']) and !defined(Resources['firewall']) {
    # since puppetlabs-firewall does not support purging for IPv6, we have to
    # disable purging here. Otherwise it may purge all rules of a not managed
    # IPv4-firewall.
    resources { 'firewall':
      purge => false,
    }
  }
  if versioncmp($::vefirewall_version6, $vefirewall::params::version6) < 0 or $force_migration {
    exec { 'vefirewall::ipv6::prepare_migration':
      command => 'ip6tables -P INPUT ACCEPT; ip6tables -P OUTPUT ACCEPT',
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      before  => Class['vefirewall::ipv6::firewall_pre'],
      require => Class['vefirewall::package'],
    }
    exec { 'vefirewall::ipv6::flush_iptables':
      command => 'ip6tables -F ; ip6tables -F -t mangle',
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      before  => Class['vefirewall::ipv6::firewall_pre'],
      require => Exec['vefirewall::ipv6::prepare_migration'],
    }
  }

  if ! defined(Class['vefirewall']) {
    include vefirewall::package
  }


  Firewall {
    before  => Class['vefirewall::ipv6::firewall_post'],
    require => [Class['vefirewall::ipv6::firewall_pre'], Concat['/etc/init.d/firewall6']],
    notify  => Exec['ip6tables-save-vefirewall'],
  }

  anchor { 'vefirewall::ipv6::start':
    notify => Class['vefirewall::package'],
  }

  class { 'vefirewall::ipv6::firewall_pre':
    require => Class['vefirewall::package'],
    notify  => Class['vefirewall::ipv6::firewall_post'],
  }

  class { 'vefirewall::ipv6::firewall_post':
    require => Class['vefirewall::ipv6::firewall_pre'],
    notify  => Class['vefirewall::ipv6::service'],
  }

  class { 'vefirewall::ipv6::service':
    require => Class['vefirewall::ipv6::firewall_post'],
  }

  anchor { 'vefirewall::ipv6::end':
    require => Class['vefirewall::ipv6::service'],
  }

  if $host_trusted_services{
    $host_trusted_services_hash = prefix($host_trusted_services, 'ip6tables,')
    vefirewall::host_trusted_services_set { $host_trusted_services_hash: }
  }

  if $host_ext_services{
    $host_ext_services_hash = prefix($host_ext_services, 'ip6tables,')
    vefirewall::host_ext_services_set { $host_ext_services_hash: }
  }

  if $allow_input_from_networks {
      # remove empty entries that may come via hiera
      $allow_input_from_networks_real = reject($allow_input_from_networks, '^/$')
      $allow_input_from_networks_hash = prefix($allow_input_from_networks_real, 'ip6tables,')
      vefirewall::allow_input_from_networks { $allow_input_from_networks_hash: }
  }

  if !defined(Class['vefirewall::version']) {
    include vefirewall::version
  }

  file { '/usr/share/vefirewall/version6':
    ensure  => file,
    content => $vefirewall::params::version6,
    mode    => '0444',
    require => [Class['vefirewall::version'], Anchor['vefirewall::ipv6::end']],
  }

}
