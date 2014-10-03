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

check_status() {
    ps_cnt=$(ps auxw | grep inotifywait | grep -v grep | wc -l)
}

while getopts "t:r:sS" flag; do
case $flag in
    \?) OPT_ERROR=1; break;;
    t) targetlist="$OPTARG";;
    r) repodir="$OPTARG";break;;
    s) stop=1; break;;
    S) status=1; break;;
esac
done

shift $(( $OPTIND - 1))

if [ $OPT_ERROR ] || [ -z $repodir ] && [ -z $stop ] && [ -z $status ]; then
    echo >&2 "[usage] $0 [-t /path/to/targetlist] -r /path/to/repodir|-s|-S"
    echo >&2 "\tstart:\t[-t /path/to/targetlist] -r /path/to/repodir"
    echo >&2 "\tstop:\t-s"
    echo >&2 "\tstatus:\t-S"
    exit 1
fi

test -z $stop && stop=0
test -z $status && status=0


# check status
if [ $status -eq 1 ]; then
    check_status
    case $ps_cnt in
        0) msg="watchrepo: stopped.";;
        1) msg="watchrepo: started only detecting newrepo.";;
        2) msg="watchrepo: started detecting newrepo and rpm files.";;
        *) msg="watchrepo: error occured. you must stop watchrepo.";;
    esac
    echo $msg
    exit 0
fi

# stopping
if [ $stop -eq 1 ]; then
    check_status
    if [ $ps_cnt -gt 0 ]; then
        pkill inotifywait
    else
        echo "watchrepo has already stopped."
    fi
    exit 0
fi

# starting
if [ $repodir ]; then
    test ! -d $repodir && install -d $repodir
    test -z $targetlist && targetlist=${repodir}/target.list
    check_status
    if [ $ps_cnt -eq 0 ]; then
        touch $targetlist
        watchrepo &
        detect_new_repo &
    else
        echo "watchrepo is already started."
        exit 0
    fi
fi
