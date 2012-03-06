These are the sort of small Git extension scripts I would keep in
~/bin/ and have on my path, or put in ~/.gitconfig [alias] section.
The project is named "mca-wtsi/git-yacontrib".


The current plan is to "install" them via symlinks,
  ln -snvf ../../../gitwk-github/scripts/bin/{git-rebase-topswap,pidfzap} ~/bin/

or include the bin/ on PATH.


They are only maintained to the extent that I'm still using them.

I have written them in the course of my work for
http://www.sanger.ac.uk/ and for personal use.

The project is released under GPLv2 or later, per local policy.

(I realise this is far to vague to form a reliable declaration of
"release under GPLv2" except where explicit but marking for release
takes time, and it's probably better to make the thing visible and
wait for someone to ask for clarification.)
