# Class: vefirewall::ipv6::package
#
# Parameters:
#
class vefirewall::ipv6::package () {

  if $vefirewall::params::ip6tables_package {
    package { $vefirewall::params::ip6tables_package:
      ensure => installed,
      alias  => 'ip6tables',
    }

    if $::osfamily == 'RedHat' {
      service { 'ip6tables':
        ensure    => stopped,
        enable    => false,
        hasstatus => false,
        require   => Package[$vefirewall::params::ip6tables_package],
      }

      # just in case firewalld is running
      ensure_resource('service', 'firewalld', {
        ensure => stopped,
        enable => false,
      })
    }
  }

}
