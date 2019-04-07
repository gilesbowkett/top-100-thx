require "./lib/top_100"

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

  let(:github_urls) do
    [
      "https://github.com/rails/rails/commit/168e3958df38b7f6738d60f2510a2e6d1ebcc9fb",
      "https://github.com/rails/rails/commit/e81f1acc33a642df68c32d28202dcf589a79d714",
      "https://github.com/rails/rails/commit/6af2cbca07821e66cc358a4105a54c78f1dde19b"
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

  it "gets the committer's github_urls" do
    expect(@contributor_page["github_urls"]).to eq(github_urls)
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
      "github_urls" => [
        "https://github.com/rails/rails/commit/168e3958df38b7f6738d60f2510a2e6d1ebcc9fb",
        "https://github.com/rails/rails/commit/e81f1acc33a642df68c32d28202dcf589a79d714",
        "https://github.com/rails/rails/commit/6af2cbca07821e66cc358a4105a54c78f1dde19b"
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
    IndividualContributor.parse(raw_data)
  end

  it "creates an IndividualContributor" do
    expect(contributor).to be_an(IndividualContributor)
  end

  it "gets the git hash (sha1)" do
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
        "168e3958df38b7f6738d60f2510a2e6d1ebcc9fb",
        "e81f1acc33a642df68c32d28202dcf589a79d714",
        "6af2cbca07821e66cc358a4105a54c78f1dde19b"
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

    describe "sanity check" do

      let(:sane) do
        Commit.new("e81f1ac", "Uncomment test for join model method_missing. Closes #87...")
      end

      let(:nope) do
        Commit.new("e81f1ac", "this page referred to an :href_options keyword hash, in ...")
      end

      # more likely a bug in my code than the site, but either way, gotta know
      it "can tell if the contributors.rubyonrails.org summary doesn't match the commit" do
        expect(sane.parsed_correct_commit?).to be true
        expect(nope.parsed_correct_commit?).to be false
      end
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

  let(:show) do
    msg = <<~SHOW
      commit 168e3958df38b7f6738d60f2510a2e6d1ebcc9fb
      Author: Giles Bowkett <gilesb@gmail.com>
      Date:   Tue Mar 17 12:41:15 2009 -0700

          this page referred to an :href_options keyword hash, in fact the correct keyword (the one the code responds to) is :html

      diff --git a/actionpack/lib/action_view/helpers/text_helper.rb b/actionpack/lib/action_view/helpers/text_helper.rb
      index 48bf4717ad..573b99b96e 100644
      --- a/actionpack/lib/action_view/helpers/text_helper.rb
      +++ b/actionpack/lib/action_view/helpers/text_helper.rb
      @@ -324,7 +324,7 @@ module ActionView
       
             # Turns all URLs and e-mail addresses into clickable links. The <tt>:link</tt> option
             # will limit what should be linked. You can add HTML attributes to the links using
      -      # <tt>:href_options</tt>. Possible values for <tt>:link</tt> are <tt>:all</tt> (default),
      +      # <tt>:html</tt>. Possible values for <tt>:link</tt> are <tt>:all</tt> (default),
             # <tt>:email_addresses</tt>, and <tt>:urls</tt>. If a block is given, each URL and
             # e-mail address is yielded and the result is used as the link text.
             #
      @@ -341,7 +341,7 @@ module ActionView
             #   # => "Visit http://www.loudthinking.com/ or e-mail <a href=\\\"mailto:david@loudthinking.com\\\">david@loudthinking.com</a>"
             #
             #   post_body = "Welcome to my new blog at http://www.myblog.com/.  Please e-mail me at me@email.com."
      -      #   auto_link(post_body, :href_options => { :target => '_blank' }) do |text|
      +      #   auto_link(post_body, :html => { :target => '_blank' }) do |text|
             #     truncate(text, 15)
             #   end
             #   # => "Welcome to my new blog at <a href=\\\"http://www.myblog.com/\\\" target=\\\"_blank\\\">http://www.m...</a>.
      @@ -359,7 +359,7 @@ module ActionView
             #   auto_link(post_body, :all, :target => "_blank")     # => Once upon\\na time
             #   # => "Welcome to my new blog at <a href=\\\"http://www.myblog.com/\\\" target=\\\"_blank\\\">http://www.myblog.com</a>.
             #         Please e-mail me at <a href=\\\"mailto:me@email.com\\\">me@email.com</a>."
      -      def auto_link(text, *args, &block)#link = :all, href_options = {}, &block)
      +      def auto_link(text, *args, &block)#link = :all, html = {}, &block)
               return '' if text.blank?
       
               options = args.size == 2 ? {} : args.extract_options! # this is necessary because the old auto_link API has a Hash as its last parameter
    SHOW
    msg.chomp
  end

  it "gets the full git commit message" do
    expect(commit.message).to eq(full_message)
  end

  it "shows you the full commit with diff and message" do
    expect(commit.show).to eq(show)
  end
end

describe "analyzing a contributor's commits" do

  # FIXME: DRY, also, these should likely be distinct files
  let(:hashes) do
    [
      "168e395",
      "e81f1ac"
    ]
  end

  let(:commits) do
    hashes.map {|sha| Commit.new(sha)}
  end

  let(:contributor) do
    IndividualContributor.new(commits)
  end

  let(:commit_msg_word_freq) do
    {
       "0310" => 1,
       "1ee6" => 1,
       "5ecf4fe2" => 1,
       "7897" => 1,
       "8707" => 1,
       "87b1" => 1,
       "Bowkett" => 1,
       "Closes" => 1,
       "Giles" => 1,
       "Josh" => 1,
       "Peek" => 1,
       "Uncomment" => 1,
       "an" => 1,
       "code" => 1,
       "commit" => 1,
       "correct" => 1,
       "e25e094e27de" => 1,
       "fact" => 1,
       "for" => 1,
       "git" => 1,
       "hash" => 1,
       "href_options" => 1,
       "html" => 1,
       "http" => 1,
       "id" => 1,
       "in" => 1,
       "is" => 1,
       "join" => 1,
       "keyword" => 2,
       "method_missing" => 1,
       "model" => 1,
       "one" => 1,
       "org" => 1,
       "page" => 1,
       "rails" => 1,
       "referred" => 1,
       "responds" => 1,
       "rubyonrails" => 1,
       "svn" => 2,
       "test" => 1,
       "the" => 3,
       "this" => 1,
       "to" => 2,
       "trunk" => 1,
    }
  end

  let(:filename_modification_frequency) do
    {
      "actionpack/lib/action_view/helpers/text_helper.rb" => 1,
      "activerecord/test/associations/join_model_test.rb" => 1
    }
  end

  let(:diff) do
    <<~DIFF
      foo
      diff --git a/activerecord/test/associations/join_model_test.rb b/activerecord/test/associations/join_model_test.rb
      bar
    DIFF
  end

  let(:filename) do
    "activerecord/test/associations/join_model_test.rb"
  end

  it "surfaces a hash (map) of words (from commit messages) and their frequencies" do
    expect(contributor.commit_msg_word_freq).to eq(commit_msg_word_freq)
  end

  it "surfaces a hash of modified filenames and their frequencies" do
    expect(contributor.filename_modification_frequency).to eq(filename_modification_frequency)
  end

  # always TDD your regexes
  it "uses a regex to pull out filenames" do
    expect(contributor.filename_from_diff(diff)).to eq(filename)
    # FIXME: what happens if it fails?
  end
end