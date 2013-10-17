# -*- encoding: utf-8 -*-
import os
import sys

from fabric.api import local, task, cd, settings, abort, run
from fabric.api import env
from fabric.contrib.console import confirm

staging_remote_host_and_path = os.environ.get("GTLAB_AAJEGE_STAGING_HOST")
if staging_remote_host_and_path is None:
    _print_and_exit("GTLAB_AAJEGE_STAGING_HOST environment variable not set.")

staging_host, _, _stg_path = staging_remote_host_and_path.partition(':')

env.hosts = [staging_host, ]
env.use_ssh_config = True

@task
def reinstall_local_db():
    """Wipe the db, and reinstall"""
    local("rm ./data/*.json")
    local("mv media_serv.db media_serv.db.bak")
    local("sh install_db.sh")

@task
def rsync_svn():
    local("cd ../ && sh rsync_the_things.sh")

@task
def svn_up_target():
    host, _, path = staging_remote_host_and_path.partition(':')

    media_db_path = path + '/src/media-serv/'
    client_path = path + '/src/sma-client/'

    with cd(path):
        run("svn up")

@task
def clear_node_modules_rebuild():
    host, _, path = staging_remote_host_and_path.partition(':')

    client_path = path + '/src/sma-client/'

    with cd(path):
        run("svn up")

        with cd(client_path):
            run("rm -rf node_modules/")
            run("npm install")
            run("brunch build")

@task
def update_target_envs():
    host, _, path = staging_remote_host_and_path.partition(':')

    media_db_path = path + '/src/media-serv/'
    client_path = path + '/src/sma-client/'

    with cd(path):
        run("svn up")

        with cd(media_db_path):
            local("pip install -r requirements.txt")

        with cd(client_path):
            local("npm update")

@task
def update_media_db():
    host, _, path = staging_remote_host_and_path.partition(':')

    media_db_path = path + '/src/media-serv/'

    with cd(path):
        run("svn up")

        # reinstall db
        with cd(media_db_path):
            run("rm data/*.json")
            run("mv media_serv.db media_serv.db.bak")
            run("sh install_db.sh")

@task
def brunch_build_target(production=False):
    host, _, path = staging_remote_host_and_path.partition(':')

    client_path = path + '/src/sma-client/'
    if production:
        production = ' --production'
    else:
        production = ''

    with cd(client_path):
        run("svn up")

        # recompile client
        with cd(client_path):
            run("brunch build" + production)

@task
def deploy():
    """ everything: svn up, rebuild everything, recompile database and json
    """
    host, _, path = staging_remote_host_and_path.partition(':')

    media_db_path = path + '/src/media-serv/'
    client_path = path + '/src/sma-client/'

    with cd(path):
        run("svn up")

        # reinstall db
        with cd(media_db_path):
            run("rm ./data/*.json")
            run("mv media_serv.db media_serv.db.bak")
            run("sh install_db.sh")

        # recompile client
        with cd(client_path):
            run("npm update")
            run("brunch build")

        # hup hup hup
        with cd(media_db_path):
            run("kill -HUP `cat pidfile`")

@task
def hup():
    host, _, path = staging_remote_host_and_path.partition(':')

    media_db_path = path + '/src/media-serv/'
    client_path = path + '/src/sma-client/'

    # hup hup hup
    with cd(media_db_path):
        run("kill -HUP `cat pidfile`")
