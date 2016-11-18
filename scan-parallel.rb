#!/usr/bin/env ruby
# coding: utf-8

require "yaml"
require_relative "scan_common"

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
      report.call lambda { scan_registry(director, "admin", "admin") }, "registry admin/admin"
      
    end
  end
  threads.each(&:join)
  threads = []
end

