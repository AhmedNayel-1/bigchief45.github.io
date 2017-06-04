#!/usr/bin/env ruby

module GithubContributions
  require 'octokit'

  REPOS = ['ajaxorg/ace', 'jneen/rouge', 'ElemeFE/element', 'iview/iview-doc',
    'openstack-dev/pbr', 'gnocchixyz/gnocchi',
    'gnocchixyz/python-gnocchiclient'
  ]

  def self.login
    Octokit.configure do |c|
      c.login = ENV['GITHUB_LOGIN']
      c.password = ENV['GITHUB_PASSWORD']
    end
    puts "Logged in as #{Octokit.user.login}"
  end

  def self.my_contributions
    login()
    REPOS.map { |repo| Repository.new(repo) }
  end

  def self.write_json(contributions)
    File.open('/home/ubuntu/workspace/portfolio/lib/data/contributions.json', 'w') do |f|
      f.puts contributions.map { |c| c.to_json }.to_json
    end
  end

  class Repository

    attr_reader :url, :commits, :additions, :deletions

    def initialize(repository_url)
      puts "Obtaining contributions for #{repository_url}"

      @url = repository_url
      @description = Octokit.repository(@url).description
      @stats ||= get_stats()
      @commits = Octokit.commits(@url, { author: ENV['GITHUB_LOGIN'] }).count

      unless @stats.nil?
       @additions = @stats.weeks.map { |week| week[:a] }.reduce(:+)
       @deletions = @stats.weeks.map { |week| week[:d] }.reduce(:+)
      end

      sleep(10)
    end

    def to_json
      {
        'url' => @url,
        'description' => @description,
        'commits' => @commits,
        'additions' => @additions,
        'deletions' => @deletions,
        'image' => @url.split('/').last
      }
    end

    private

    def get_stats
      # If the data hasn't been cached when you query a repository's statistics,
      # you'll receive a 202 response; a background job is also fired to start
      # compiling these statistics. Give the job a few moments to complete, and
      # then submit the request again. If the job has completed, that request
      # will receive a 200 response with the statistics in the response body.
      begin
        stats = Octokit.contributors_stats(@url).find { |c| c.author.login == ENV['GITHUB_LOGIN'] }
      rescue NoMethodError
        puts "No successful response obtained. Re-trying in 10 seconds."
        sleep(10)
        retry
      end

      return stats
    end

  end
end

puts "Obtaining contributions from Github..."
GithubContributions.write_json(GithubContributions.my_contributions)

puts "Done"