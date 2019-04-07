require "./lib/top_100"

describe "args" do
  it "lets you specify which number you want"

  it "lets you specify what number you did last, and then gives you all the contributors who are next in line"
  # i.e., it handles ties
end

describe "scraping the main list web page" do
  before(:all) do
    # cache it. hitting the network once is bad enough!
    @main_page = Scraper.new(1).main_page
  end

  it "gets only the first 100 ranks" do
    expect(@main_page["contributor_ranks"].count).to eq(100)
  end

  it "gets only the first 100 names" do
    expect(@main_page["contributor_names"].count).to eq(100)
  end

  it "gets only the first 100 links" do
    expect(@main_page["contributor_links"].count).to eq(100)
  end

  describe "per contributor" do
    let(:contributor) do
      {
        rank: @main_page["contributor_ranks"][0],
        link: @main_page["contributor_links"][0],
        name: @main_page["contributor_names"][0]
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

    it "gets the official count of commits"
    # sanity-checking; I saw a contributor with more commits than the contributor before them.
    # it turned out to be a weird redundant commit that made the difference, and there are
    # probably a lot of little edge cases like that, but I want to surface them just in case.
  end
end

describe "scraping the committer's link" do
  before(:all) do
    # cache it. hitting the network once is bad enough!
    # @main_page = Scraper.new(1).contributor_page
  end

  it "gets the committer's git hashes"

  it "gets the committer's commit summaries"
  # for sanity-checking the git analysis

  it "gets the start year"

  it "gets the finish year"

  it "counts the commits"
end

describe "analyzing git" do
  it "gets all the git commit messages for the hashes it already has"

  it "surfaces a hash (map) of words and their frequencies"
end