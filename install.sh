#! /bin/bash
# Process substitution

do_inst() {
    local src dest instand leaf
    dest="$1"
    instand="$2"
    src="$PWD"
    if ! [ -d "$dest" ] || ! [ -w "$dest" ]; then
	echo "$0: $dest is not a writable directory" >&2
	return 2
    fi

    ln -snv "$src/bin" "$dest/,git-yacontrib"
    for leaf in $( cat "$src/$instand" ); do
	ln -snv ",git-yacontrib/$leaf" "$dest"
    done

    {
	set -x
	git config plumbed-in.instdir "$dest"
    }
}

show_skipped() {
    local src
    src="$PWD"
    diff -u \
	<( LC_ALL=C sort "$src"/install*.txt ) \
	<( find bin -type f -printf "%f\n" | LC_ALL=C sort )
}

if [ $# = 0 ] && plumbdir="$( git config --get plumbed-in.instdir )"; then
    # Shortcut
    echo "Spotted config 'plumbed-in.instdir: $plumbdir'"
    exec $0 -y "$plumbdir"
fi

case "$1" in
    -y) do_inst "$2" install.txt ;;
    -yS) do_inst "$2" install-scary.txt ;;
#    -h | --help)
    -s|--skipped) show_skipped ;;
    *)
	printf "usage: ./%s < -y ~/bin/ | --skipped >\n
 -s | --skipped
        List files not installed

 -y     Write symlinks (ln -snv) into the specified directory.\n
 -yS    Install (only) the scary \"read it before running\" shortcuts.\n

This isn't so much an install, as placing the files the author likes
on \$PATH the way he does it.\n
It is ideminpotent: it will not overwrite existing files or links.\n" \
    "$( basename $0 )"
	;;
esac
