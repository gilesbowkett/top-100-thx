# top-100-thx

This is a command-line research assistant
for a little "100 days, 100 devs" blogging side project.
The goal of the project is to create a new thank you post for all the top 100 Rails committers by commits,
although in practice I'll probably put every "tie" in the same post.

This library assists the project because reading each user's commits by hand,
to get a sense for where their contributions were focused,
doesn't scale well.
Even the 100th most active committer by commits has almost 100 commits to their name.
Everyone in the top 5 has more than 3K commits.

usage: `bundle exec ruby lib/top_100.rb "Contributor's Name"`

This gets you the years that the contributor was active,
the files they edited (in order of frequency),
and the words they used in their commit messages.