# define vefirewall::host_trusted_services_set
#
# implements -A $CHAIN -j ACCEPT -m $state_module NEW,ESTABLISHED,RELATED -s $HOST -p $PROTO --dport $PORT
#
define vefirewall::host_trusted_services_set() {
    $fw_parts = split($name, ',')
    $provider = "${fw_parts[0]}"
    $host = "${fw_parts[1]}"
    $proto = "${fw_parts[2]}"
    $port = "${fw_parts[3]}"
    $chain = "${fw_parts[4]}"

    if ! $chain {
      $chain_real = 'INPUT'
    } else {
      $chain_real = $chain
    }

    if $provider == 'ip6tables' {
      $version = $vefirewall::params::version6
    } else {
      $version = $vefirewall::params::version
    }

    # use src when chain input, and dest when chain output
    if ($chain_real == 'INPUT') {
      if versioncmp($::kernelversion, '2.6.19') < 0 {
        firewall { "100 $chain_real $host $proto $port accept deprecated kernel $provider $version":
          provider => $provider,
          chain    => $chain_real,
          action   => 'accept',
          state    => ['NEW', 'ESTABLISHED', 'RELATED'],
          source   => $host,
          proto    => $proto,
          dport    => $port,
        }
      } else {
        firewall { "100 $chain_real $host $proto $port accept $provider $version":
          provider => $provider,
          chain    => $chain_real,
          action   => 'accept',
          ctstate  => ['NEW', 'ESTABLISHED', 'RELATED'],
          source   => $host,
          proto    => $proto,
          dport    => $port,
        }
      }
    } elsif ($chain_real == 'OUTPUT') {
      if versioncmp($::kernelversion, '2.6.19') < 0 {
        firewall { "100 $chain_real $host $proto $port accept deprecated kernel $provider $version":
          provider    => $provider,
          chain       => $chain_real,
          action      => 'accept',
          state       => ['NEW', 'ESTABLISHED', 'RELATED'],
          destination => $host,
          proto       => $proto,
          dport       => $port,
        }
      } else {
        firewall { "100 $chain_real $host $proto $port accept $provider $version":
          provider    => $provider,
          chain       => $chain_real,
          action      => 'accept',
          ctstate     => ['NEW', 'ESTABLISHED', 'RELATED'],
          destination => $host,
          proto       => $proto,
          dport       => $port,
        }
      }
    }
}
