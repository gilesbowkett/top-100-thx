require "./lib/top_100"

describe "args" do
  it "lets you specify which number you want"
end

describe "scraping the web" do
  before(:all) do
    # cache it. hitting the network once is bad enough!
    @scraped = Scraper.new(1).scrape
  end

  it "hits the main list web page" do
    expect(@scraped).to eq("wombat")
  end

  it "gets only the first 100 ranks" do
    expect(@scraped["contributor_ranks"].count).to eq(100)
  end

  it "gets only the first 100 names" do
    expect(@scraped["contributor_names"].count).to eq(100)
  end

  it "gets only the first 100 links" do
    expect(@scraped["contributor_links"].count).to eq(100)
  end

  describe "per contributor" do
    let(:contributor) do
      {
        rank: @scraped["contributor_ranks"][0],
        link: @scraped["contributor_links"][0],
        name: @scraped["contributor_names"][0]
      }
    end

		it "gets the committer's rank" do
      expect(contributor[:rank]).to eq("#1")
    end

		it "gets the committer's link" do
      expect(contributor[:link]).to eq("/contributors/rafael-mendonca-franca/commits")
    end

		it "gets the committer's name" do
      expect(contributor[:name]).to eq("Rafael Mendonça França")
    end
  end

  it "hits the committer's link"

  it "gets the committer's git hashes"

  it "gets the committer's commit summaries"
  # for sanity-checking the git analysis

  it "gets the start year"

  it "gets the finish year"

  describe "getting the number of commits" do
    it "counts the individual commit listings"
    it "also grabs the official number from the committer's link"
    it "also grabs the official number from the main web page"
  end
end

describe "analyzing git" do
  it "gets all the git commit messages for the hashes it already has"

  it "surfaces a hash (map) of words and their frequencies"
end