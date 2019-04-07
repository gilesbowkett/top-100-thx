require 'wombat'

Scraper = Struct.new(:number) do
  def scrape
    first_run = Wombat.crawl do
      base_url "https://contributors.rubyonrails.org"
      path "/"

      contributor_ranks "css=td.contributor-rank", :list
      contributor_names "css=td.contributor-name", :list
      contributor_links "xpath=//html/body/div[3]/div/div/div/div/div/table/tr/td[2]/a/@href", :list
    end

    # TODO: filter the lists in scraped; only return top 100
    first_run.inject({}) do |h, (k, v)|
      h[k] = v.first(100)
      h
    end
  end
end
