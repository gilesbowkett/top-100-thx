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
  let(:dates) do
    [
      "17 Mar 2009",
      "15 Oct 2007",
      "18 Jun 2007"
    ]
  end
  let(:messages) do
    [
      "this page referred to an :href_options keyword hash, in ...",
			"Uncomment test for join model method_missing. Closes #87...",
      "remove extra debug line.  Closes #8681 [Giles Bowkett]"
    ]
  end

  before(:all) do
    # cache it. hitting the network once is bad enough!
    @contributor_page = Scraper.new.contributor_page("/contributors/giles-bowkett/commits")
  end

  it "gets the committer's git hashes" do
    expect(@contributor_page["git_hashes"]).to eq(hashes)
  end

  it "gets the committer's commit dates" do
    expect(@contributor_page["commit_dates"]).to eq(dates)
  end

  it "gets the committer's commit messages" do
		# for sanity-checking the git analysis
    expect(@contributor_page["commit_messages"]).to eq(messages)
  end
end

describe "turning raw data into an individual contributor" do
  let(:raw_data) do
    {
      "git_hashes" => [
        "168e395",
        "e81f1ac",
        "6af2cbc"
      ],
       "commit_dates" => [
        "17 Mar 2009",
        "15 Oct 2007",
        "18 Jun 2007"
      ],
      "commit_messages" => [
        "this page referred to an :href_options keyword hash, in ...",
        "Uncomment test for join model method_missing. Closes #87...",
        "remove extra debug line.  Closes #8681 [Giles Bowkett]"
      ]
    }
  end
  let(:contributor) do
    IndividalContributor.parse(raw_data)
  end

  it "creates an IndividalContributor" do
    expect(contributor).to be_an(IndividalContributor)
  end

	it "gets the start year" do
    expect(contributor.start).to eq(2007)
  end

	it "gets the finish year" do
    expect(contributor.finish).to eq(2009)
	end

  describe "parsing commits" do
    # FIXME: DRY!
		let(:hashes) do
			[
				"168e395",
				"e81f1ac",
				"6af2cbc"
			]
		end
		let(:dates) do
			[
				"17 Mar 2009",
				"15 Oct 2007",
				"18 Jun 2007"
			]
		end
		let(:summaries) do
			[
				"this page referred to an :href_options keyword hash, in ...",
				"Uncomment test for join model method_missing. Closes #87...",
				"remove extra debug line.  Closes #8681 [Giles Bowkett]"
			]
		end

    it "captures them all" do
      expect(contributor.commits.count).to eq(3)
    end

    # I think in Clojure this would just be interleave
    it "captures the dates, sha hashes, and summaries, in order" do
      expect(contributor.commits.first.sha1).to eq(hashes.first)
      expect(contributor.commits.first.summary).to eq(summaries.first)
      expect(contributor.commits.first.date).to eq(dates.first)

      expect(contributor.commits.last.sha1).to eq(hashes.last)
      expect(contributor.commits.last.summary).to eq(summaries.last)
      expect(contributor.commits.last.date).to eq(dates.last)
    end
  end
end

describe "analyzing git" do
  let(:commit) do
    Commit.new("168e395")
  end
  let(:full_message) do
    msg = <<~FULL_MESSAGE
      this page referred to an :href_options keyword hash, in fact the correct keyword (the one the code responds to) is :html
    FULL_MESSAGE
    msg.chomp
  end

  it "gets the full git commit message" do
    expect(commit.message).to eq(full_message)
  end

  it "surfaces a hash (map) of words and their frequencies"
  # it would probably be easy to do this for the code each contributor affected also

  it "surfaces a hash of modified filenames and their frequencies"
end