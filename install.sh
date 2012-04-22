#! /bin/sh

do_inst() {
    local dest leaf
    dest="$1"
    if ! [ -d "$dest" ] || ! [ -w "$dest" ]; then
	echo "$0: $dest is not a writable directory" >&2
	return 2
    fi

    ln -snv "$PWD/bin" "$dest/,git-yacontrib"
    for leaf in git-ci git-co git-ff git-g git-gk git-iec git-k git-ll-cpanm git-ll-init git-qcommit git-rebase-topswap git-st git-undzil git-up; do
	ln -snv ",git-yacontrib/$leaf" "$dest"
    done
}

case "$1" in
    -y) do_inst "$2" ;;
#    -h | --help)
    *)
	printf "usage: ./%s -y ~/bin/\n
Writes symlinks into the specified directory.\n
This isn't so much an install, as placing the files the author likes
on \$PATH the way he does it.\n" \
    "$( basename $0 )"
	;;
esac
