require "./lib/top_100"

describe "args" do
  it "lets you specify what number you did last, and then gives you all the contributors who are next in line"
  # i.e., it handles ties
end

describe "scraping the main list web page" do
  before(:all) do
    # cache it. hitting the network once is bad enough!
    @main_page = Scraper.new.main_page
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

  describe "turning raw data into an indexed list of contributors" do
    let(:scraped_data) do
      {
        "contributor_ranks" => [
          "#1",
          "#2",
          "#2",
          "#4"
        ],
        "contributor_names" => [
          "Jon Snow",
          "Tyrion Lannister",
          "Arya Stark",
          "Bronn of the Blackwater"
        ],
        "contributor_links" => [
          "/contributors/jon-snow/commits",
          "/contributors/tyrion-lannister/commits",
          "/contributors/arya-stark/commits",
          "/contributors/bronn/commits"
        ]
      }
    end
    let(:contributors) do
      ListedContributor.parse(scraped_data)
    end

    it "creates a list of contributors" do
      contributors.each {|contributor| expect(contributor).to be_a(ListedContributor)}
    end

    it "orders the list by rank" do
      expect(contributors.map(&:name)).to eq(["Jon Snow", "Tyrion Lannister", "Arya Stark", "Bronn of the Blackwater"])
    end

    it "assigns the correct links" do
      expect(contributors[0].link).to eq("/contributors/jon-snow/commits")
      expect(contributors[2].link).to eq("/contributors/arya-stark/commits")
    end

    it "turns the ranks into numbers" do
      expect(contributors[0].rank).to eq(1)
    end

    it "is trivial now to get the contributors for a given rank" do
      tied_for_2nd_place = contributors.select {|c| c.rank == 2}
      expect(tied_for_2nd_place.map(&:name)).to eq(["Tyrion Lannister", "Arya Stark"])
    end

    it "can tell you who is next, given a specific rank" do
      next_up = contributors.who_comes_next(4)
      expect(next_up.map(&:name)).to eq(["Tyrion Lannister", "Arya Stark"])
    end
  end
end

describe "scraping the committer's link" do
  let(:hashes) do
    [
      "168e395",
      "e81f1ac",
      "6af2cbc"
    ]
  end

  before(:all) do
    # cache it. hitting the network once is bad enough!
    @contributor_page = Scraper.new.contributor_page("/contributors/giles-bowkett/commits")
  end

  it "gets the committer's git hashes" do
    expect(@contributor_page["git_hashes"]).to eq(hashes)
  end

  it "gets the committer's commit summaries"
  # for sanity-checking the git analysis

  it "gets the start year"

  it "gets the finish year"

  it "gets the commit count"

  it "also counts the commits manually"
end

describe "analyzing git" do
  it "gets all the git commit messages for the hashes it already has"

  it "surfaces a hash (map) of words and their frequencies"
end