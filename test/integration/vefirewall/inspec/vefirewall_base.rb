describe iptables do
  it "Should not allow input on tcp ports 60000 - 60100" do
    should_not have_rule('-A INPUT -p tcp -m multiport --dports 60000:60100 -m comment --comment "030 input tcp new related established 60000-60100 iptables 1.0" -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT')
  end
end

describe iptables do
  it "Should not allow input on udp highports" do
    should_not have_rule('-A INPUT -p udp -m multiport --dports 1024:65535 -m comment --comment "022 input udp accept iptables 1.0" -j ACCEPT')
  end
end

describe iptables do
  it "Should export input to port 22 to everywhere" do
    should have_rule('-A INPUT -p tcp -m multiport --dports 22 -m comment --comment "100 INPUT 0.0.0.0/0 tcp 22 accept iptables 1.0" -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT')
  end
end

describe iptables do
  it "Should trust input to port 22 from localhost" do
    should have_rule('-A INPUT -s 127.0.0.1/32 -p tcp -m multiport --dports 22 -m comment --comment "100 INPUT 127.0.0.1 tcp 22 accept iptables 1.0" -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT')
  end
end

describe iptables do
  it "Should have input policy drop" do
    should have_rule('-P INPUT DROP')
  end
end
