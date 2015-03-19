# Class vefirewall::version
#
# Creates directory structure for version files
#
class vefirewall::version() {
  file { '/usr/share/vefirewall':
    ensure => directory,
  }

  file { '/usr/share/vefirewall/DO_NOT_DELETE':
    ensure  => file,
    content => 'THIS DIRECTORY IS CREATED BY SYS11-PUPPET\n',
    require => File['/usr/share/vefirewall'],
  }
}
