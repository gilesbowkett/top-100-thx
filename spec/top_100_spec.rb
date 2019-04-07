require "./lib/top_100"

describe "args" do
  it "lets you specify which number you want"
end

describe "scraping the web" do
  it "hits the main list web page"

  it "gets the committer's link"

  it "hits the committer's link"

  it "gets the committer's name"

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