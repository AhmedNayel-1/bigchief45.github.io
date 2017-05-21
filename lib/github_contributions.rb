#!/usr/bin/env ruby

module GithubContributions
  require 'octokit'

  REPOS = ['ajaxorg/ace', 'ElemeFE/element', 'iview/iview-doc', 'openstack-dev/pbr']

  def self.login
    Octokit.configure do |c|
      c.login = ENV['GITHUB_LOGIN']
      c.password = ENV['GITHUB_PASSWORD']
    end
    puts "Logged in as #{Octokit.user.login}"
  end

  def self.my_contributions
    GithubContributions.login()
    REPOS.map { |repo| GithubContributions::Repository.new(repo) }
  end

  def self.write_json(contributions)
    File.open('/home/ubuntu/workspace/portfolio/lib/data/contributions.json', 'w') do |f|
      f.puts contributions.map { |c| c.to_json }.to_json
    end
  end

  class Repository

    attr_reader :url, :stats, :commits, :additions, :deletions

    def initialize(repository_url)
      puts "Obtaining contributions for #{repository_url}"
      @url = repository_url

      @commits = Octokit.commits(@url, {author: ENV['GITHUB_LOGIN']}).count
      #@stats = Octokit.contributors_stats(@url).detect { |c| c.author.login == ENV['GITHUB_LOGIN'] }
      #@commits = @stats.total
      #@additions = get_additions
      #@deletions = get_deletions
    end

    def to_json
      {
        'url' => @url,
        'commits' => @commits,
        #'additions' => @additions,
        #'deletions' => @deletions,
        'image' => @url.split('/').last
      }
    end

    private

      def get_additions
        @stats.weeks.map { |week| week[:a] }.reduce(:+)
      end

      def get_deletions
        @stats.weeks.map { |week| week[:d] }.reduce(:+)
      end

  end
end

puts "Obtaining contributions from Github..."
GithubContributions.write_json(GithubContributions.my_contributions)
puts "Done"