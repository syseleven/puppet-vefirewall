# define vefirewall::host_ext_services_set
#
# implements -A INPUT -j ACCEPT -m $state_module NEW,ESTABLISHED,RELATED -d $HOST -p $PROTO --dport $PORT
#
define vefirewall::host_ext_services_set() {
  $fw_parts = split($name, ',')
  $provider = "${fw_parts[0]}"
  $ip = "${fw_parts[1]}"
  $proto = "${fw_parts[2]}"
  $port = "${fw_parts[3]}"

  # ip_real (needs to be array)
  $ip_real = $ip ? {
    'internal' => any2array($::ipaddress_internal),
    'external' => any2array($::ipaddress_external),
    'external_all' => split($::ipaddress_external_all, ','),
    default    => any2array($ip),
  }

  if $provider == 'ip6tables' {
    $version = $vefirewall::params::version6
  } else {
    $version = $vefirewall::params::version
  }

  if ! $ip_real {
    fail('Could not get IP')
  }

  # convert data to one useable hash for Define['service_input_accept_set']
  $ip_hash = ip_array_to_hash($ip_real, $port, $proto)
  $ip_hash_titles = keys($ip_hash)

  vefirewall::service_input_accept_set { $ip_hash_titles:
    ip_hash  => $ip_hash,
    version  => $version,
    provider => $provider,
  }
}
