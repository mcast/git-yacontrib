#! /bin/sh

do_inst() {
    local src dest leaf
    dest="$1"
    src="$PWD"
    if ! [ -d "$dest" ] || ! [ -w "$dest" ]; then
	echo "$0: $dest is not a writable directory" >&2
	return 2
    fi

    ln -snv "$src/bin" "$dest/,git-yacontrib"
    for leaf in $( cat "$src/install.txt" ); do
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
