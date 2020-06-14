require 'erb'
require 'English'

# Include a list of people who should have their PRs added to the team list (i.e. higher priority)
# TEAM_AUTHORS environment variable, comma separated
TEAM_AUTHORS = ENV.key?("TEAM_AUTHORS") ? ENV["TEAM_AUTHORS"].split(',').freeze : [].freeze

# repo_friendly_name => local path of repo
# define REPO_CONFIG_1, REPO_CONFIG_2, etc. outside of the script as repo_friendly_name,local_path_to_repo
REPO_HASH = ENV
  .select { |k, v| k.start_with?("REPO_CONFIG_") }
  .map { |k, v| v.split(",").map(&:strip) }
  .to_h
  .freeze

CURRENT_GITHUB_USER = ENV['CURRENT_GITHUB_USER'].freeze

class ExportPRsFromHub
  def call!
    load_if_needed

    File.read('hub_output.txt')
  end

  def load_if_needed
    # reuse cache to work around github API rate limiting while developing mostly
    if !File.exist?('hub_output.txt') || (File.exist?('hub_output.txt') && File.ctime('hub_output.txt') < Time.now - 10 * 60)
      output = `/usr/local/bin/hub pr list --state all --sort created --format "%t||%U||%I||%au||%rs%n" -L50`

      File.write('hub_output.txt', output)
    end
  end
end

class ThingsHelper
  def self.story_exists?(search_string)
    `/usr/local/bin/things.sh -s "#{search_string}" search | grep -q "#{search_string}"`

    $CHILD_STATUS.success?
  end

  def self.add_task(**args)
    url_param_string = args.map { |k, v| "#{k}=#{ERB::Util.url_encode(v)}" }.join("&")
    url = "things:///add?#{url_param_string}"

    `open "#{url}"`
  end
end

class ImportPRsToThings

  attr_reader :repo_friendly_name, :hub_data

  def initialize(repo_friendly_name:, hub_data:)
    @repo_friendly_name = repo_friendly_name
    @hub_data = hub_data
  end

  def call!
    each_line do |title:, url:, pr_number:, author:, reviewers:|
      title_prefix = "PR #{pr_number} (#{repo_friendly_name}) (#{author})"

      next if ThingsHelper.story_exists?(title_prefix)

      body = `/usr/local/bin/hub pr show -f '%b' #{pr_number}`

      ThingsHelper.add_task(
        title: "#{title_prefix}: #{title}",
        notes: "#{url}\n\n#{body}",
        tags: ['PR', ('Requested' if reviewers.include?(CURRENT_GITHUB_USER))].compact,
        list: TEAM_AUTHORS.include?(author) ? 'PR (Team)' : "PR (Other)",
        heading: nil,
        when: 'today',
      )
    end
  end

  def each_line(&block)
    hub_data.split("\n").each do |line|
      title, url, pr_number, author, unparsed_reviewers = line.split("||")
      reviewers = unparsed_reviewers&.split(", ") || []

      yield title: title, url: url, pr_number: pr_number, author: author, reviewers: reviewers
    end
  end
end

#### Now process each repo in turn

REPO_HASH.each do |repo_friendly_name, path|
  Dir.chdir path

  hub_data = ExportPRsFromHub.new.call!

  ImportPRsToThings.new(repo_friendly_name: repo_friendly_name, hub_data: hub_data).call!
end

`open things:///show?id=today`
