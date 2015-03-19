# Determine the version of the currently installed vefirewall.
# Needing this vor migration paths.
def get_vefirewall_version(vefirewall_version_file)
    if File.exists?(vefirewall_version_file)
      old_version = File.open(vefirewall_version_file).read.chomp
    else
      old_version = "0.0"
    end
    return old_version
end

Facter.add(:vefirewall_version) do
  setcode do
    get_vefirewall_version('/usr/share/vefirewall/version')
  end
end

Facter.add(:vefirewall_version6) do
  setcode do
    get_vefirewall_version('/usr/share/vefirewall/version6')
  end
end
