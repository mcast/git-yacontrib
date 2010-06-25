#! /bin/sh


###  Script for "git bisect run"
#
# Attempts to find the cause of broken cookies and redirections after
# upgrade toRail 2.3.8.
#
# Use with
#
#   git bisect start <commitID_bad> <commitID_good>
#   git bisect log > bisect.log
#
#   git bisect reset master && git bisect replay bisect.log && git bisect run ./bisect-test.sh
#
###


# Local patch
# DNW: perl -i -pe 'if (s/(RAILS_GEM_VERSION = )(.2\.3\.8.)/$1"2.3.5"/) { warn "Switch rails $1 to 2.3.5" } $_ .= qq{warn "Rails v#{Rails.version}"\n} if /^end/' config/environment.rb 

# Start server
echo -e "\n\n\n\n\n\nSTART MONGREL"
fuser -k -INT -v -n tcp 3002
mongrel_rails start -p 3002 -d
sleep 10

# Fetch
echo TRY FETCH
export http_proxy=
rm -f fetch.html fetch.hdr
FETCH=`curl -s -o fetch.html -D fetch.hdr http://psd1d.internal.sanger.ac.uk:3002/`
ls -l fetch.html fetch.hdr

# Kill server, undo local patch
fuser -k -INT -v -n tcp 3002
git reset --hard HEAD

# Consider the results
if grep -E '^Set-Cookie:' fetch.hdr && grep -E '^Location:' fetch.hdr; then
    echo OK
    exit 0
elif grep -E '302 Moved Temporarily' fetch.hdr && grep '^Date:' fetch.hdr && grep 'You are being' fetch.html; then
    echo -e "\n\nCLASSIC FAIL\n\n"
    exit 10
else
    echo -e "\n\n\n******\nDoesn't look good\n******\n\n\n"
    head -20 fetch.*
    echo SKIP
    exit 125
fi
