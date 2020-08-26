require 'wombat'
require 'date'
require 'rugged'

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

    repo = Rugged::Repository.new('data/rails')

    commit = repo.lookup(sha1)
    self.message = commit.message

    diff = commit.parents[0].diff(commit)
    self.show = diff
  end

  def parsed_correct_commit?
    self.message[0..50] == self.summary[0..50]
  end
end

IndividualContributor = Struct.new(:commits, :start, :finish) do
  STOPWORDS = [
    'a','cannot','into','our','thus','about','co','is','ours','to','above',
    'could','it','ourselves','together','across','down','its','out','too',
    'after','during','itself','over','toward','afterwards','each','last','own',
    'towards','again','eg','latter','per','under','against','either','latterly',
    'perhaps','until','all','else','least','rather','up','almost','elsewhere',
    'less','same','upon','alone','enough','ltd','seem','us','along','etc',
    'many','seemed','very','already','even','may','seeming','via','also','ever',
    'me','seems','was','although','every','meanwhile','several','we','always',
    'everyone','might','she','well','among','everything','more','should','were',
    'amongst','everywhere','moreover','since','what','an','except','most','so',
    'whatever','and','few','mostly','some','when','another','first','much',
    'somehow','whence','any','for','must','someone','whenever','anyhow',
    'former','my','something','where','anyone','formerly','myself','sometime',
    'whereafter','anything','from','namely','sometimes','whereas','anywhere',
    'further','neither','somewhere','whereby','are','had','never','still',
    'wherein','around','has','nevertheless','such','whereupon','as','have',
    'next','than','wherever','at','he','no','that','whether','be','hence',
    'nobody','the','whither','became','her','none','their','which','because',
    'here','noone','them','while','become','hereafter','nor','themselves','who',
    'becomes','hereby','not','then','whoever','becoming','herein','nothing',
    'thence','whole','been','hereupon','now','there','whom','before','hers',
    'nowhere','thereafter','whose','beforehand','herself','of','thereby','why',
    'behind','him','off','therefore','will','being','himself','often','therein',
    'with','below','his','on','thereupon','within','beside','how','once',
    'these','without','besides','however','one','they','would','between','i',
    'only','this','yet','beyond','ie','onto','those','you','both','if','or',
    'though','your','but','in','other','through','yours','by','inc','others',
    'throughout','yourself','can','indeed','otherwise','thru','yourselves'
  ]

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
      word.downcase!
      acc[word] += 1 unless STOPWORDS.include?(word)
      acc
    end
  end

  def filename_modification_frequency
    filenames = self.commits.map do |commit|
      filenames_from_diff(commit.show)
    end

    filenames.flatten.inject(Hash.new(0)) do |acc, filename|
      acc[filename] += 1
      acc
    end
  end

  def filenames_from_diff(diff)
    begin
      diff.patch.scan(/diff --git a\/([^ ]+) b\//m).flatten
    rescue ArgumentError
      []
    end
  end
end

# check user for word and filename frequency
if __FILE__ == $0
  argv_name = ARGV[0]

  scraper = Scraper.new

  main_page = scraper.main_page
  contributors = ListedContributor.parse(main_page)

  user_from_list = contributors.detect {|contrib| argv_name == contrib.name}
  users_page = scraper.contributor_page(user_from_list.link)

  user_from_page = IndividualContributor.parse(users_page)

  puts "user's most frequently used words:"
  freq = user_from_page.commit_msg_word_freq
  freq.delete(nil)
  freq.sort_by {|_k, v| v}.each {|k, v| puts "#{k}: #{v}"}
  puts

  puts "user's most frequently modified files:"
  freq = user_from_page.filename_modification_frequency
  freq.delete(nil)
  freq.sort_by {|_k, v| v}.each {|k, v| puts "#{k}: #{v}"}
  puts

  puts "user started: #{user_from_page.start}"
  puts "user went til: #{user_from_page.finish}"
  puts "user name: #{argv_name}"
  puts
end

