# -*- encoding: utf-8 -*-
import os
import sys

from fabric.colors import red, green, cyan
from fabric.api import local, task, cd, settings, abort, run
from fabric.api import env
from fabric.contrib.console import confirm
from fabvenv import virtualenv

staging_remote_host_and_path = os.environ.get("GTLAB_AAJEGE_STAGING_HOST")
if staging_remote_host_and_path is None:
    _print_and_exit("GTLAB_AAJEGE_STAGING_HOST environment variable not set.")

staging_host, _, _stg_path = staging_remote_host_and_path.partition(':')

env.hosts = [staging_host, ]
env.use_ssh_config = True

@task
def reinstall_local_db():
    """Wipe the db, and reinstall"""
    local("rm -rf ./data/*.json")
    local("rm -rf ./data/*.xml")
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
    media_dir_path = path + '/src/media-serv/static/media/'

    with cd(path):
        run("svn up")

    with cd(media_dir_path):
        run("svn up")

@task
def compile_translation_strings_local():
    local("tx pull")
    local("pybabel compile -d translations")

@task
def compile_translation_strings():
    host, _, path = staging_remote_host_and_path.partition(':')

    media_db_path = path + '/src/media-serv/'
    client_path = path + '/src/sma-client/'

    print(cyan("Compiling translation strings ..."))
    with virtualenv(media_db_path + '/env/'):
        print(cyan("virtualenv ..."))
        with cd(media_db_path):
            run("svn up")
            print(cyan("Pulling from transifex ..."))
            run("tx pull")
            run("pybabel compile -d translations")

    print(cyan("Compiled translation strings ..."))

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
    print(cyan("Updating python and node environment packages ..."))

    with cd(path):
        run("svn up")

        with cd(media_db_path):
            local("pip install -r requirements.txt")

        with cd(client_path):
            local("npm update")
    print(cyan("Updated python and node environment packages ..."))

@task
def update_media_db():
    host, _, path = staging_remote_host_and_path.partition(':')

    media_db_path = path + '/src/media-serv/'
    media_dir_path = path + '/src/media-serv/static/media/'

    print(cyan("Installing media db..."))
    with cd(media_dir_path):
        print(cyan("Concept media directory..."))
        run("svn up")

    with cd(path):
        run("svn up")

        # reinstall db
        with cd(media_db_path):
            run("rm data/*.json")
            run("mv media_serv.db media_serv.db.bak")
            run("sh install_db.sh")
    print(cyan("Successfully installed media db..."))

@task
def npm_update_target(production=False):
    host, _, path = staging_remote_host_and_path.partition(':')

    client_path = path + '/src/sma-client/'
    if production:
        production = ' --production'
    else:
        production = ''

    print(cyan("Updating npm..."))

    with cd(client_path):
        run("svn up")

        # recompile client
        with cd(client_path):
            run("npm update")
    print(cyan("Updated npm..."))


@task
def brunch_build_target(production=False):
    host, _, path = staging_remote_host_and_path.partition(':')

    print(cyan("Rebuilding client src ..."))
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
    print(cyan("Rebuilt client src ..."))

@task
def brunch_build_target_prod(production=False):
    brunch_build_target(production=True)

@task
def deploy():
    """ everything: svn up, rebuild everything, recompile database and json
    """

    print(cyan("Beginning deploy..."))
    svn_up_target()
    compile_translation_strings()
    update_media_db()
    npm_update_target()
    brunch_build_target_prod()
    hup()
    print(cyan("Deploy process complete."))

@task
def hup():
    host, _, path = staging_remote_host_and_path.partition(':')

    media_db_path = path + '/src/media-serv/'
    client_path = path + '/src/sma-client/'

    print(cyan(" Hup'ing media serv ..."))
    # hup hup hup
    with cd(media_db_path):
        run("kill -HUP `cat pidfile`")
    print(cyan(" Hup'd media serv ..."))

