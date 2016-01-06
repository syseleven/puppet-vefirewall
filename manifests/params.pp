# Class: vefirewall::params
#
# Parameters:
#   none
#
class vefirewall::params () {

  # can be changed separately, if only one of the parts has to be migrated
  $version = '1.0'
  $version6 = '1.0'

  case $::operatingsystem {
    'gentoo': {
      $iptables_package = 'net-firewall/iptables'
      $gentoo_useflags = ''
      $init_script = "puppet:///modules/${module_name}/firewall.init.gentoo"
    }
    'ubuntu': {
      $iptables_package = 'iptables'
      $init_script = "puppet:///modules/${module_name}/firewall.init.ubuntu"
    }
    'debian': {
      if $::operatingsystemmajrelease < 7 {
        fail('Your debian must be at least 7.0!')
      }
      $iptables_package = 'iptables'
      $init_script = "puppet:///modules/${module_name}/firewall.init.ubuntu"
    }
    'centos': {
      if $::operatingsystemmajrelease < 6 {
        fail('Your centos must be at least 6!')
      }
      $iptables_package = 'iptables'
      $ip6tables_package = 'iptables-ipv6'
      $init_script = "puppet:///modules/${module_name}/firewall.init.centos6"
    }
    default: {
      fail("Unknown OS: ${::operatingsystem}")
    }
  }
}
