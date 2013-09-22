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

# @task
# def init():
#     """Set up the project and environment.
# 
#     Install dependencies and create a symlink from an
#     external media storage to Hyde's media folder for easier
#     development and deployment.
#     """
#     local("pip install -r requirements.txt")
#     if not os.path.exists(EXTERNAL_MEDIA_PATH):
#         external_media_path = os.environ.get("EXTERNAL_MEDIA_PATH")
#         if external_media_path is None:
#             _print_and_exit("EXTERNAL_MEDIA_PATH environment variable not set.")
#         local("ln -s {0} {1}".format(external_media_path,
#             EXTERNAL_MEDIA_PATH))
#     else:
#         print("A link to an external media already exists.")

@task
def reinstall_db():
    """Wipe the db, and reinstall"""
    local("mv media_serv.db media_serv.db.bak")
    local("sh install_db.sh")

@task
def rsync_svn():
    local("cd ../ && sh rsync_the_things.sh")


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
            run("mv media_serv.db media_serv.db.bak")
            run("sh install_db.sh")

@task
def brunch_build_target():
    host, _, path = staging_remote_host_and_path.partition(':')

    client_path = path + '/src/sma-client/'

    with cd(client_path):
        run("svn up")

        # recompile client
        with cd(client_path):
            run("brunch build")

@task
def deploy():
    host, _, path = staging_remote_host_and_path.partition(':')

    media_db_path = path + '/src/media-serv/'
    client_path = path + '/src/sma-client/'

    with cd(path):
        run("svn up")

        # reinstall db
        with cd(media_db_path):
            run("mv media_serv.db media_serv.db.bak")
            run("sh install_db.sh")

        # recompile client
        with cd(client_path):
            run("npm update")
            run("brunch build")

        # hup hup hup
        with cd(media_db_path):
            run("kill -HUP `cat pidfile`")

