#
# ip_array_to_hash.rb
#
# given
# - list of ip addresses (array)
# - port (string)
# - protocol (string)
#
# creates a hash with uniqe title for use in puppet define later
#
# example
#
#   ip_list = { '1.1.1.1', '2.2.2.2' }
#   port = '80'
#   proto = 'tcp'
#
# will be
#
#   {
#     "1.1.1.1,80,tcp" => {
#       "host" => "1.1.1.1",
#       "port" => "80",
#       "proto" => "tcp"
#     },
#     "2.2.2.2,80,tcp" => {
#       "host" => "2.2.2.2",
#       "port" => "80",
#       "proto" => "tcp"
#     }
#   }
#
# author amauf@syseleven.de 2014
#
module Puppet::Parser::Functions
  newfunction(:ip_array_to_hash, :type => :rvalue) do |args|
    ip_list = args[0]
    port = args[1]
    proto = args[2]

    ip_hash = Hash.new

    ip_list.each { |ip|

      # need unique title for puppet define
      title = ip + ',' + port + ',' + proto

      # collect all data
      ip_hash[title] = {
        'ip' => ip,
        'port' => port,
        'proto' => proto
      }

    }

    # return ip_hash
    ip_hash

  end
end
