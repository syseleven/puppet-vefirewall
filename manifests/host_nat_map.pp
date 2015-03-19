# define vefirewall::host_nat_map
#
# implements  -t nat -A POSTROUTING -s $VPNNET -d $INTNET -j SNAT -to $INT_IP
#
define vefirewall::host_nat_map() {
    # INFO: no provider here since there is no ipv6 nat support
    #$net_parts = split($name, '-') # TODO deleteme
    $vpn_net = $name

    $ip_parts = split($::ipaddress_internal, '[.]')
    $int_net = join([values_at($ip_parts, 0), values_at($ip_parts, 1), values_at($ip_parts, 2), '0/24'], '.')

    firewall { "200 nat postrouting from $vpn_net to $int_net snat to $ipaddress_internal $vefirewall::params::version":
      table       => 'nat',
      chain       => 'POSTROUTING',
      proto       => 'all',
      source      => $vpn_net,
      destination => $int_net,
      jump        => 'SNAT',
      tosource    => $::ipaddress_internal,
    }
}
