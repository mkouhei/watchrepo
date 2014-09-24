#!/bin/sh -e


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


test -z $1 && echo "[usage] $0 [/path/to/repodir|stop]" && exit 1
if [ x$1 = x"stop" ]; then
    pkill inotifywait
    exit 0
fi
repodir=$1

test ! -d $repodir && install -d $repodir
targetlist=${repodir}/target.list

rm -f $pidpath
touch $targetlist

watchrepo &
detect_new_repo &
