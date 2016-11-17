#!/usr/bin/env ruby
# coding: utf-8

require "yaml"

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

manifest_path = ARGV[0] || "directors.yml"
manifest = YAML.load_file manifest_path
teams = manifest.fetch("teams")

def report_full(team, director, resultish, name)
  Thread.new do
    result = if resultish.is_a?(Proc)
               resultish.call
             else
               resultish
             end
    puts "#{team} | #{director} | #{name} #{result}"
    STDOUT.flush
  end
end

threads = []
teams.each_slice(4) do |teams|
  teams.each do |team|
    directors = team.fetch("directors")

    directors.each do |director|
      report = lambda do |result, name|
        threads << report_full(team.fetch("name"), director, result, name)
      end

      report.call lambda { scan_user(director) }, "director admin/admin"
      report.call lambda { scan_hm(director) }, "director hm/hm-password"
      report.call lambda { scan_nats(director) }, "nats"
      report.call lambda { scan_agent(director, "mbus", "mbus-password") }, "agent mbus/mbus-password"
      report.call lambda { scan_agent(director, "mbus-user", "mbus-password") }, "agent mbus-user/mbus-password"
      report.call lambda { scan_postgres(director) }, "postgres"
      report.call lambda { scan_blobstore(director, "director", "director-password") }, "blobstore director/director-password"
      report.call lambda { scan_blobstore(director, "agent", "agent-password") }, "blobstore agent/agent-password"
      
    end
  end
  threads.each(&:join)
  threads = []
end

