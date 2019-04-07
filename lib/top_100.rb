require 'wombat'

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

      git_hashes "css=span.sha1", :list
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
