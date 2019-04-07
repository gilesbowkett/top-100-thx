require 'wombat'
require 'date'
require 'git'

class Scraper
  def main_page
    scraped = Wombat.crawl do
      base_url "https://contributors.rubyonrails.org"
      path "/"

      contributor_ranks "css=td.contributor-rank", :list
      contributor_names "css=td.contributor-name", :list
      contributor_links "xpath=//html/body/div[3]/div/div/div/div/div/table/tr/td[2]/a/@href", :list
    end

    scraped.inject({}) do |h, (k, v)|
      h[k] = v.first(100)
      h
    end
  end

  def contributor_page(contributor_url)
    scraped = Wombat.crawl do
      base_url "https://contributors.rubyonrails.org"
      path contributor_url

      github_urls "xpath=//html/body/div[3]/div/div/div/div/div/div/table/tr/td[1]/a/@href", :list
      commit_dates "css=td.commit-date", :list
      commit_messages "css=td.commit-message", :list
    end
  end
end

class ListedContributors < Array
  def who_comes_next(current_index)
    subsequent = select {|contributor| contributor.rank < current_index}
    next_index = subsequent.last.rank
    select {|contributor| contributor.rank == next_index} # FIXME: more efficient way?
  end
end

ListedContributor = Struct.new(:name, :link, :rank) do
  def self.parse(raw_data)
    parsed = raw_data["contributor_ranks"].each_with_index.map do |rank, index|
      new(raw_data["contributor_names"][index], raw_data["contributor_links"][index], rank.gsub('#', '').to_i)
    end

    ListedContributors.new(parsed)
  end
end

# the summary comes from the contributors web site; the message comes from git
Commit = Struct.new(:sha1, :summary, :date, :message, :show) do
  def initialize(*args)
    super(*args)

    git = Git.open("data/rails")
    commit = git.gcommit(sha1)
    self.message = commit.message
    self.show = git.show(sha1)
  end

  def parsed_correct_commit?
    self.message[0..50] == self.summary[0..50]
  end
end

IndividualContributor = Struct.new(:commits, :start, :finish) do
  def self.parse(raw_data)
    commits = raw_data["github_urls"].each_with_index.map do |url, index|
      sha1 = url.gsub('https://github.com/rails/rails/commit/', '')
      Commit.new(sha1, raw_data["commit_messages"][index], raw_data["commit_dates"][index])
    end

    dates = raw_data["commit_dates"].map do |date|
      Date.parse(date)
    end
    start = dates.sort.first.year
    finish = dates.sort.last.year

    new(commits, start, finish)
  end

  def commit_msg_word_freq
    words = (self.commits.map {|commit| commit.message.split(/\W/)}).flatten.select {|word| word != ""}

    words.inject(Hash.new(0)) do |acc, word|
      acc[word] += 1
      acc
    end
  end

  def filename_modification_frequency
    filenames = self.commits.map do |commit|
      filename_from_diff(commit.show)
    end

    filenames.inject(Hash.new(0)) do |acc, filename|
      acc[filename] += 1
      acc
    end
  end

  def filename_from_diff(diff)
    # FIXME: String#match has such an awkward API
    matched = diff.match(/.+\ndiff --git a\/([^ ]+) b\//m)
    matched[1] if matched
  end
end

# trial run: check Ernie Miller for tag cloud and filename frequency
if __FILE__ == $0
  require 'awesome_print'
  scraper = Scraper.new

  main_page = scraper.main_page
  contributors = ListedContributor.parse(main_page)

  ernie_from_list = contributors.detect {|contrib| "Ernie Miller" == contrib.name}
  ernies_page = scraper.contributor_page(ernie_from_list.link)

  ernie_from_page = IndividualContributor.parse(ernies_page)
  ap "ernie started: #{ernie_from_page.start}"
  ap "ernie went til: #{ernie_from_page.finish}"

  ap "ernie's most frequently modified files:"
  freq = ernie_from_page.filename_modification_frequency
  freq.delete(nil)
  ap freq.sort_by {|_k, v| v}

  ap "ernie's most frequently used words:"
  freq = ernie_from_page.commit_msg_word_freq
  freq.delete(nil)
  ap freq.sort_by {|_k, v| v}
end

