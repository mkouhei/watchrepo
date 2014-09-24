===========
 watchrepo
===========

Purpose
-------

Detect event of new repository directory and RPM packages in Yum repository.

Requires
--------

* inotify-tools
* createrepo

Getting started
---------------

1. git clone::

     $ git clone https://github.com/mkouhei/watchrepo.git

2. Install depended packages.::

     $ sudo apt-get install createrepo inotify-tools
  
3. Execute shell script.::

     $ watchrepo/watchrepo.sh /path/to/repodir &

4. Stop process::

     $ watchrepo/watchrepo.sh stop
