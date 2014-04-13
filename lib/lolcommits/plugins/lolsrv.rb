# -*- encoding : utf-8 -*-
require 'rest_client'
require 'pp'
require 'json'

module Lolcommits
  class Lolsrv < Plugin
    def initialize(runner)
      super
      self.options << 'server'
    end

    def run
      return unless valid_configuration?
      fork { sync }
    end

    def configured?
      !configuration['enabled'].nil? && configuration['server']
    end

    def sync
      existing = existing_lols
      unless existing.nil?
        Dir[self.runner.config.loldir + '/*.{jpg,gif}'].each do |item|
          sha = File.basename(item, '.*')
          unless existing.include?(sha) || sha == 'tmp_snapshot'
            upload(item, sha)
          end
        end
      end
    end

    def existing_lols
      begin
        lols = JSON.parse(
        RestClient.get(configuration['server'] + '/lols'))
        lols.map { |lol| lol['sha'] }
      rescue => e
        log_error(e, "ERROR: existing lols could not be retrieved #{e.class} - #{e.message}")
        return nil
      end
    end

    def upload(file, sha)
      begin
        RestClient.post(
          configuration['server'] + '/uplol',
          :lol => File.new(file),
          :url => self.runner.url + sha,
          :repo => self.runner.repo,
          :date => File.ctime(file),
          :sha => sha)
      rescue => e
        log_error(e, "ERROR: Upload of lol #{sha} FAILED #{e.class} - #{e.message}")
        return
      end
    end

    def log_error(e, message)
      debug message
      debug e.backtrace
    end

    def self.name
      'lolsrv'
    end

    def self.runner_order
      :postcapture
    end
  end
end
