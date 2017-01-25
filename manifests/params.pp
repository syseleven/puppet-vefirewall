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
    'Gentoo': {
      $iptables_package = 'net-firewall/iptables'
      $init_script = "firewall.init.gentoo"
    }
    'Ubuntu': {
      $iptables_package = 'iptables'
      $init_script = "firewall.init.ubuntu"
    }
    'Debian': {
      if versioncmp($::operatingsystemmajrelease, '7') < 0 {
        fail('Your debian must be at least 7.0!')
      }
      $iptables_package = 'iptables'
      $init_script = "firewall.init.ubuntu"
    }
    'CentOS': {
      if versioncmp($::operatingsystemmajrelease, '6') < 0 {
        fail('Your centos must be at least 6!')
      }
      $iptables_package = 'iptables'
      $ip6tables_package = 'iptables-ipv6'
      $init_script = "firewall.init.centos6"
    }
    'OracleLinux': {
      $iptables_package = 'iptables'
      $ip6tables_package = 'iptables-ipv6'
      $init_script = "firewall.init.centos6"
    }
    default: {
      fail("Unknown OS: ${::operatingsystem}")
    }
  }
}
