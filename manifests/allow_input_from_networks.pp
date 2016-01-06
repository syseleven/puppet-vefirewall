# define vefirewall::allow_input_from_networks
#
# Does 'iptables -I INPUT -s $network -j ACCEPT'
#
# Parameters
#   $title = $provider,[]
#     iptables provider (e.g. ip6tables) and list of networks to allow
#
define vefirewall::allow_input_from_networks() {
  $fw_parts = split($name, ',')
  $provider = $fw_parts[0]
  $network = $fw_parts[1]

  if $provider == 'ip6tables' {
    $version = $vefirewall::params::version6
  } else {
    $version = $vefirewall::params::version
  }

  # network might be empty due to hiera-fact being empty
  # avoid rasing puppet fatal
  if $network {
    firewall { "130 input from ${network} accept ${provider} ${version}":
      provider => $provider,
      chain    => 'INPUT',
      proto    => 'all',
      source   => $network,
      action   => 'accept',
    }
  }
}
