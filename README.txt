These are the sort of small scripts I would keep in ~/bin/ and have on
my path.  For want of a better name, I call the project
"mca-wtsi/scripts".

The current plan is to "install" them via symlinks,

  ln -snvf ../../../gitwk-github/scripts/bin/{git-rebase-topswap,pidfzap} ~/bin/

They are only maintained to the extent that I'm still using them.

I have written them in the course of my work for http://www.sanger.ac.uk/

The longer and more complete items I have released under GPLv2 or
later, per local policy.

The short, messy, one-off solutions and wrapper scripts I would expect
to be considered "trivial", more an example of how something could be
done.
