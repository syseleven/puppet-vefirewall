# class vefirewall
#
# This class fully configures the firewall of an sys11 VE
#
# Paramters:
#   $host_trusted_services = [],
#     List of services to be allowed for certain hosts, protocols, ports and chain
#   $host_ext_services = [],
#     List of services to be allowed all incoming traffic on a certain IP, protocol and port.
#     By using 'external' or 'internal' as IP, the first automatically discovered IP address is used.
#     By using 'external_all' all external ip addresses are used.
#   $vlan2_outgoing_ip = $::ipaddress_external,
#     This IP is used for outgoing connections in VLAN2, you can set this variable if the default external (the first one) is not the right one
#   $vlan2_allow_default_internal_net_access = true,
#     Set this to false to not accept all internal traffic on the first internal IP
#   $vlan2_additional_internal_nets = [],
#     List of internal networks for which in- and outgoing traffic should be allowed in addition to default internal network (see $vlan2_allow_default_internal_net_access above)
#   $host_nat_map = undef,
#     Set this to a network (e.g. '10.21.0.0/24') so that requests from that network will be NATed to the internal IP
#   $allow_input_from_networks = undef,
#     Set this to a list of networks (e.g. '10.21.0.0/24') to do iptables -I INPUT -s $network -j ACCEPT
#   $iptables_package = $vefirewall::params::package,
#     iptables package to install
#   $accept_input_on_internal_network = true,
#     Set this to false to not accept 10.0.0.0/8 for INPUT chain
#   $accept_output_on_internal_network = true,
#     Set this to false to not accept 10.0.0.0/8 for OUTPUT chain
#   $output_default_policy = 'accept',
#     This set the default output_police to given value
#   $icmp_related_list = ['0', '3', '11', '12', '14', '18'],
#     accepted returns for icmptypes from outgoing requests
#   $output_icmp_list = ['time-exceeded', '3/3', '3/4', '3/9', '3/10', '3/13', '3', '8']
#     accepted output icmp list
#   $force_migration = false
#     true will flush all rules before new rules are applied.
#   $disable_migration_nat = false
#     tell the migration to not flush nat, just for very special cases.
#   $disable_migration_mangle = false
#     tell the migration to not flush mangle, just for very special cases.
#
# Sample usage:
#   vefirewall:
#     host_trusted_services:
#       - 1.1.1.1,tcp,80
#       - 2.1.1.1,tcp,80
#       - 2.1.1.1,tcp,80-89
#       - 2.1.1.0/24,tcp,80-89
#       - 8.8.8.8,tcp,53,OUTPUT
#     host_ext_services:
#       - external,tcp,ssh
#       - 151.252.40.158,tcp,ssh
#       - external_all,tcp,http
#       - external_all,tcp,https
#     host_nat_map: 10.21.0.0/24
#     # only for vlan2 relevant
#     # default value should should suffice most times!
#     vlan2_additional_internal_nets:
#       - 10.0.22.0/24
#       - 10.0.23.0/24
#
class vefirewall(
  $host_trusted_services = [],
  $host_ext_services = [],
  $vlan2_outgoing_ip = $::ipaddress_external,
  $vlan2_allow_default_internal_net_access = true,
  $vlan2_additional_internal_nets = [],
  $host_nat_map = undef,
  $allow_input_from_networks = undef,
  $iptables_package = $vefirewall::params::package,
  $accept_input_on_internal_network = true,
  $accept_output_on_internal_network = true,
  $accept_udp_high_ports = true,
  $accept_tcp_60000_60100 = true,
  $output_default_policy = 'accept',
  $forward_default_policy = 'accept',
  $icmp_related_list = ['0', '3', '11', '12', '14', '18'],
  $output_icmp_list = ['time-exceeded', '3/3', '3/4', '3/9', '3/10', '3/13', '3', '8'],
  $force_migration = false,
  $disable_migration_nat = false,
  $disable_migration_mangle = false,
) inherits vefirewall::params {

  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease > 6 {
    ensure_resource('exec', 'systemctl daemon-reload', {
      path        => '/bin:/usr/bin:/sbin:/usr/sbin',
      refreshonly => true,
    })
    $notify_init_script = [Exec['iptables-save-vefirewall'], Exec['systemctl daemon-reload']]
    # hack to ensure daemon-reload occurs before service start
    anchor { 'init-reload':
      require => Exec['systemctl daemon-reload'],
    }
  } else {
    $notify_init_script = Exec['iptables-save-vefirewall']
    # nothing to do here. BUT service fireall requires this anchor!!!
    anchor { 'init-reload':
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
  concat { '/etc/init.d/firewall':
    ensure => present,
    mode   => '0544',
    notify => $notify_init_script,
    before => Service['firewall'],
  }

  concat::fragment { 'headv4':
    target => '/etc/init.d/firewall',
    source => "${vefirewall::params::init_script}.v4",
    order  => '01',
  }

  concat::fragment { 'scriptv4':
    target => '/etc/init.d/firewall',
    source => $vefirewall::params::init_script,
    order  => '02',
  }
  # /HACK

  file {
    '/etc/init.d/firewall3':
      ensure => absent;
    '/etc/init.d/firewall2':
      ensure => absent;
    '/etc/conf.d/firewall':
      ensure => absent;
  }

  exec { 'iptables-save-vefirewall':
    command     => 'iptables-save > /var/cache/iptables-rules.save',
    path        => '/sbin/:/bin/:/usr/sbin/',
    refreshonly => true,
    before      => Service['firewall'],
  }

  if versioncmp($::vefirewall_version, $vefirewall::params::version) < 0 or $force_migration {
    # it would be also possible to flush here,
    # but then in your first puppet run you will get errors for each
    # row to be deleted.
    # the provider to obtain the current iptables runs before this
    # stuff in here.
    exec { 'vefirewall::prepare_migration':
      command => 'iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT',
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      before  => Class['vefirewall::firewall_pre'],
      require => Class['vefirewall::package'],
    }

    # HACK for some special cases to disable flushing of nat an mangle
    if $disable_migration_nat and $disable_migration_mangle {
      $migration_cmd=''
    } elsif $disable_migration_nat and ! $disable_migration_mangle {
      $migration_cmd='; iptables -t mangle -F'
    } elsif ! $disable_migration_nat and $disable_migration_mangle {
      $migration_cmd='; iptables -t nat -F'
    } else {
      $migration_cmd='; iptables -t nat -F; iptables -t mangle -F'
    }
    notify { "iptables -F ${migration_cmd}": }
    # flushing all tables
    exec { 'vefirewall::flush_iptables':
      command => "iptables -F ${migration_cmd}",
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      before  => Class['vefirewall::firewall_pre'],
      require => Exec['vefirewall::prepare_migration'],
    }
    # Define the resource here, to not override it by a non-migration of ipv6.
    resources { 'firewall':
      purge => false,
    }
  } else {
    # do not purge on migrations. The tables will be flushed by an exec
    # otherwise the first puppet run will get errors, since the the providers
    # purge runs before running the exec (which is not able to cover by
    # dependencies).
    resources { 'firewall':
      purge => true,
    }
  }

  Firewall {
    before  => Class['vefirewall::firewall_post'],
    require => [Class['vefirewall::firewall_pre'], Concat['/etc/init.d/firewall']],
    notify  => Exec['iptables-save-vefirewall'],
  }

  anchor { 'vefirewall::start':
    notify => Class['vefirewall::package'],
  }

  class { 'vefirewall::package':
    notify => Class['vefirewall::firewall_pre'],
  }

  class { 'vefirewall::firewall_pre':
    notify => Class['vefirewall::firewall_post'],
  }

  class { 'vefirewall::firewall_post':
    require => Class['vefirewall::firewall_pre'],
    notify  => Class['vefirewall::service'],
  }

  class { 'vefirewall::service':
    require => Class['vefirewall::firewall_post'],
  }

  if $host_trusted_services{
    $host_trusted_services_hash = prefix($host_trusted_services, 'iptables,')
    vefirewall::host_trusted_services_set { $host_trusted_services_hash: }
  }

  if $host_ext_services{
    $host_ext_services_hash = prefix($host_ext_services, 'iptables,')
    vefirewall::host_ext_services_set { $host_ext_services_hash: }
  }

  if $host_nat_map{
    vefirewall::host_nat_map { $host_nat_map: }
  }

  if $allow_input_from_networks {
      # remove empty entries that may come via hiera
      $allow_input_from_networks_real = reject($allow_input_from_networks, '^/$')
      $allow_input_from_networks_hash = prefix($allow_input_from_networks_real, 'iptables,')
      vefirewall::allow_input_from_networks { $allow_input_from_networks_hash: }
  }

  anchor { 'vefirewall::end':
    require => Class['vefirewall::service'],
  }

  if !defined(Class['vefirewall::version']) {
    include vefirewall::version
  }

  file { '/usr/share/vefirewall/version':
    ensure  => file,
    content => $vefirewall::params::version,
    mode    => '0444',
    require => [Class['vefirewall::version'], Anchor['vefirewall::end']],
  }

}
