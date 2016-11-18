#!/usr/bin/env ruby
# coding: utf-8

require "yaml"
require_relative "scan_common"

manifest_path = ARGV[0] || "directors.yml"
manifest = YAML.load_file manifest_path
teams = manifest.fetch("teams")

def report(result, name)
  puts "    #{name} #{result}"
end

teams.each do |team|
  puts "#{team.fetch("name")}"
  directors = team.fetch("directors")

  directors.each do |director|
    puts "  #{director}"

    report(scan_user(director), "director admin/admin")
    report(scan_hm(director), "director hm/hm-password")
    report(scan_nats(director), "nats")
    report(scan_agent(director, "mbus", "mbus-password"), "agent mbus/mbus-password")
    report(scan_agent(director, "mbus-user", "mbus-password"), "agent mbus-user/mbus-password")
    report(scan_postgres(director), "postgres")
    report(scan_blobstore(director, "director", "director-password"), "blobstore director/director-password")
    report(scan_blobstore(director, "agent", "agent-password"), "blobstore agent/agent-password")

    puts
  end
end
