# define vefirewall::service_input_accept_set
#
define vefirewall::service_input_accept_set(
  $ip_hash,
  $version,
  $provider='iptables',
) {

  $host = $ip_hash[$name]['ip']
  $proto = $ip_hash[$name]['proto']
  $port = $ip_hash[$name]['port']

  if ! $host or ! $proto or ! $port {
    fail('$host or $proto or $port not set!')
  }

  if versioncmp($::kernelversion, '2.6.19') < 0 {
    firewall { "100 INPUT ${host} ${proto} ${port} accept deprecated kernel ${provider} ${version}":
      provider    => $provider,
      chain       => 'INPUT',
      action      => 'accept',
      state       => ['NEW', 'ESTABLISHED', 'RELATED'],
      destination => $host,
      proto       => $proto,
      dport       => $port,
    }
  } else {
    firewall { "100 INPUT ${host} ${proto} ${port} accept ${provider} ${version}":
      provider    => $provider,
      chain       => 'INPUT',
      action      => 'accept',
      ctstate     => ['NEW', 'ESTABLISHED', 'RELATED'],
      destination => $host,
      proto       => $proto,
      dport       => $port,
    }
  }
}
