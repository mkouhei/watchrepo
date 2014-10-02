#!/bin/sh -e
# Copyright (C) 2014 Kouhei Maeda <mkouhei@palmtb.net>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# watch repositry
watchrepo() {
    echo "check update repository"

    inotifywait -mr -e create,modify,close_write,delete --fromfile $targetlist --exclude ".repodata|.olddata|repodata" | while read dir event file
    do
        echo "[$dir] $file is $event."
        createrepo $dir
    done
}


# detect new repostory directory
detect_new_repo() {
    inotifywait -m -e create $repodir | while read dir event file
    do
        echo "check new repository"
        if [ $event = "CREATE,ISDIR" ]; then
            if ! grep -q ${dir}${file} $targetlist; then
                echo ${dir}${file} >> $targetlist

                pid=$(ps auxwww | grep inotifywait | grep fromfile | grep -v grep | awk '{ printf $2 }')
                if [ ! -z $pid ]; then
                    echo "restart watchrepo"
                    kill $pid
                fi
                watchrepo &
            fi
        fi
    done
}

while getopts "r:t:s" flag; do
case $flag in
    \?) OPT_ERROR=1; break;;
    r) repodir="$OPTARG";;
    t) targetlist="$OPTARG";;
    s) stop=1;;
esac
done

shift $(( $OPTIND - 1))

if [ $OPT_ERROR ] || ( [ $repodir ] && [ $stop ] ) || ( [ -z $repodir ] && [ -z $stop ] ); then
    echo >&2 "[usage] $0 [-t /path/to/targetlist] -r /path/to/repodir|-s|-S"
    echo >&2 "\tstart:\t[-t /path/to/targetlist] -r /path/to/repodir"
    echo >&2 "\tstop:\t-s"
    exit 1
fi

test -z $stop && stop=0

if [ $stop -eq 1 ]; then
    pkill inotifywait
    exit 0
fi

test ! -d $repodir && install -d $repodir
test -z $targetlist && targetlist=${repodir}/target.list

rm -f $pidpath
touch $targetlist

watchrepo &
detect_new_repo &
