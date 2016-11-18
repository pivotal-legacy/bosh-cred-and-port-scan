# coding: utf-8
# this is included in both scanning scripts

WAIT_ARG = RbConfig::CONFIG['host_os'] =~ /linux/ ? "w" : "G"
TIMEOUT = 2

`which nats-pub`
raise "install nats-pub please" unless $?.success?

class Result
  attr_reader :port_open, :default_creds

  def initialize(port_open, default_creds)
    @port_open = port_open
    @default_creds = default_creds
  end

  def to_s
    output = []

    if port_open
      output << "port: \e[0;31m  open\e[0;0m"
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

  `curl -k -s -f -m #{TIMEOUT} --user "admin:admin" https://#{director}:25555/deployments`
  user = $?.success?

  Result.new(port, user)
end

def scan_hm(director)
  port = port_open(director, "25555")

  `curl -k -s -f -m #{TIMEOUT} --user "hm:hm-password" https://#{director}:25555/deployments`
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

  `curl -k -f -s -m #{TIMEOUT} -X POST --user "#{username}:#{password}" -d '{"method":"ping","arguments":[],"reply_to":""}' "https://#{director}:6868/agent"`
  user = $?.success?

  Result.new(port, user)
end

def scan_blobstore(director, user, password)
  port = port_open(director, "25250")

  output = `curl -v -v -k -s -f -m #{TIMEOUT} --user "#{user}:#{password}" http://#{director}:25250/lol 2>&1`
  authenticated = !!(output =~ /404 Not Found/)

  Result.new(port, authenticated)
end

def scan_registry(director, user, password)
  port = port_open(director, "25777")

  `curl -k -s -f -m #{TIMEOUT} --user "#{user}:#{password}" http://#{director}:25777/instances/blah/settings`
  user = $?.success?

  Result.new(port, user)
end

def scan_redis(director)
  port = port_open(director, "25255")
  Result.new(port, nil)
end

def scan_hm_http(director)
  port = port_open(director, "25923")
  Result.new(port, nil)
end

# TODO: redis 25255 https://bosh.io/jobs/redis?source=github.com/cloudfoundry/bosh&version=152
# TODO: hm 25923 https://bosh.io/jobs/health_monitor?source=github.com/cloudfoundry/bosh&version=152#p=hm.http.port
