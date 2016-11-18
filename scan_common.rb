# coding: utf-8
# this is included in both scanning scripts

WAIT_ARG = RbConfig::CONFIG['host_os'] =~ /linux/ ? "w" : "G"

class Result
  attr_reader :port_open, :default_creds

  def initialize(port_open, default_creds)
    @port_open = port_open
    @default_creds = default_creds
  end

  def to_s
    output = []

    if port_open
      output << "port: \e[0;31mopen\e[0;0m"
    else
      output << "port: \e[0;32mclosed\e[0;0m"
    end

    if default_creds == nil
      output << "creds: \e[1;33m~\e[0;0m"
    elsif default_creds == true
      output << "creds: \e[0;31m✗\e[0;0m"
    else
      output << "creds: \e[0;32m✓\e[0;0m"
    end

    output.join(", ")
  end
end

def port_open(director, port)
  `nc -z -v -#{WAIT_ARG}1 #{director} #{port} 2> /dev/null`

  $?.success?
end

def scan_user(director)
  port = port_open(director, "25555")

  `curl -k -s -f -m 5 --user admin:admin https://#{director}:25555/deployments`
  user = $?.success?

  Result.new(port, user)
end

def scan_hm(director)
  port = port_open(director, "25555")

  `curl -k -s -f -m 5 --user hm:hm-password https://#{director}:25555/deployments`
  user = $?.success?

  Result.new(port, user)
end

def scan_postgres(director)
  port = port_open(director, "5432")
  Result.new(port, nil)
end

def scan_nats(director)
  port = port_open(director, "4222")

  `nats-pub notarealtopic -s nats://nats:nats-password@#{director}:4222 2> /dev/null`
  user = $?.success?

  Result.new(port, user)
end

def scan_agent(director, username, password)
  port = port_open(director, "6868")

  `curl -k -f -s -m 5 -X POST --user "#{username}:#{password}" -d '{"method":"ping","arguments":[],"reply_to":""}' "https://#{director}:6868/agent"`
  user = $?.success?

  Result.new(port, user)
end

def scan_blobstore(director, user, password)
  port = port_open(director, "25250")

  `curl -k -s -f -m 5 --user #{user}:#{password} https://#{director}:25250`
  user = $?.success?

  Result.new(port, user)
end