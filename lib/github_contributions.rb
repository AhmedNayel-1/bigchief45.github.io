#!/usr/bin/env ruby

module GithubContributions
  require 'octokit'

  REPOS = [
    'rails/rails', 'aws/chalice',
    'ajaxorg/ace', 'jneen/rouge', 'gnocchixyz/gnocchi',
    'gnocchixyz/python-gnocchiclient', 'ElemeFE/element', 'iview/iview-doc',
    'openstack-dev/pbr',
  ]

  class << self
    def login
      Octokit.configure do |c|
        c.login = ENV['GITHUB_LOGIN']
        c.password = ENV['GITHUB_PASSWORD']
      end
      puts "Logged in as #{Octokit.user.login}"
    end

    def my_contributions
      login
      REPOS.map { |repo_url| Repository.new(repo_url) }
    end

    def write_json(contributions)
      path = '/home/ubuntu/workspace/portfolio/data/open_source.json'
      File.open(path, 'w') do |f|
        f.puts contributions.map(&:to_json).to_json
      end
    end
  end

  class Repository
    attr_reader :url, :commits, :additions, :deletions

    def initialize(repository_url)
      puts "Obtaining contributions for #{repository_url}"

      @url = repository_url
      @description = Octokit.repository(@url).description
      @stats ||= retrieve_stats
      @commits = Octokit.commits(@url, author: ENV['GITHUB_LOGIN']).count

      unless @stats.nil?
        @additions = @stats.weeks.map { |week| week[:a] }.reduce(:+)
        @deletions = @stats.weeks.map { |week| week[:d] }.reduce(:+)
      end
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

    def retrieve_stats
      # If the data hasn't been cached when you query a repository's statistics,
      # you'll receive a 202 response; a background job is also fired to start
      # compiling these statistics. Give the job a few moments to complete, and
      # then submit the request again. If the job has completed, that request
      # will receive a 200 response with the statistics in the response body.
      begin
        stats = Octokit.contributors_stats(@url).find do |c|
          c.author.login == ENV['GITHUB_LOGIN']
        end
      rescue NoMethodError, 'No successful response. Re-trying in 10 seconds.'
        sleep(10)
        retry
      end

      stats
    end
  end
end

puts 'Obtaining contributions from Github...'
GithubContributions.write_json(GithubContributions.my_contributions)

puts 'Done'
