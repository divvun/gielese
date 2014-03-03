# -*- encoding: utf-8 -*-
import os
import sys

from fabric.colors import red, green, cyan, yellow
from fabric.api import local, task, cd, settings, abort, run
from fabric.api import env
from fabric.contrib.console import confirm
from fabvenv import virtualenv

#
## Host setup
#

env.use_ssh_config = True

def set_env(var, env):
    prod_remote_host_and_path = os.environ.get(var)
    if prod_remote_host_and_path is None:
        _print_and_exit("%s environment variable not set." % var)
        _print_and_exit("Must be in form of user@host://path/to/aajege/")
    setattr(env, 'host_path', prod_remote_host_and_path)
    _host, _, _stg_path = prod_remote_host_and_path.partition(':')
    env.host_path = prod_remote_host_and_path
    env.target_path = _stg_path
    env.hosts = [_host]

@task
def production():
    # Purposefully leaving this function name longer so I have to think
    # more before I run it ;)
    set_env("GIELESE_PROD_HOST", env)
    env.production = True
    env.development = False

@task
def dev():
    set_env("GIELESE_DEV_HOST", env)
    env.production = False
    env.development = True

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
    path = env.target_path

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
    path = env.target_path

    media_db_path = path + '/src/media-serv/'
    client_path = path + '/src/sma-client/'

    print(cyan("Compiling translation strings ..."))
    with virtualenv(media_db_path + '/env/'):
        print(cyan("virtualenv ..."))
        with cd(media_db_path):
            run("svn up")
            print(cyan("Pulling from transifex ..."))
            try:
                b = run("tx pull")
            except:
                print(red("Pulling from transifex failed."))
            run("pybabel compile -d translations")

    print(cyan("Compiled translation strings ..."))

@task
def clear_node_modules_rebuild():
    path = env.target_path

    client_path = path + '/src/sma-client/'

    with cd(path):
        run("svn up")

        with cd(client_path):
            run("rm -rf node_modules/")
            run("npm install")
            run("brunch build")

@task
def update_target_envs():
    path = env.target_path

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
    path = env.target_path

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
    path = env.target_path

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
    path = env.target_path

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
def deploy_client(production=False):
    brunch_build_target()

@task
def hup_dev():
    path = env.target_path

    media_db_path = path + '/src/media-serv/'
    client_path = path + '/src/sma-client/'

    print(cyan(" Hup'ing media serv ..."))
    # hup hup hup
    with cd(media_db_path):
        run("kill -HUP `cat pidfile`")
    print(cyan(" Hup'd media serv ..."))

@task
def hup():
    if env.development:
        hup_dev()
    elif env.production:
        print(red(" Not available eyt "))

@task
def build_ios():
	client_path = "/Users/pyry/aajege/src/sma-client/"
	phonegap_path = "/Users/pyry/aajege/src/sma-client/phonegap/gielese/"

    # 
    with cd(client_path):
        local("brunch build --production")
    with cd(phonegap_path):
        local("phonegap build ios")


@task
def build_android():
	client_path = "/Users/pyry/aajege/src/sma-client/"
	phonegap_path = "/Users/pyry/aajege/src/sma-client/phonegap/gielese/"
	android_path = "/Users/pyry/aajege/src/sma-client/phonegap/gielese/platforms/android/"

    # 
    with cd(client_path):
        local("brunch build --production")
    with cd(phonegap_path):
        local("cordova build android")
    with cd(android_path):
        local("ant release")

@task
def extract_strings():
    """ Extract all the translation strings to the template and *.po files. """

    print(cyan("** Extracting strings"))
    cmd = "pybabel extract -F babel.cfg -o translations/messages.pot ../sma-client/ ."
    extract_cmd = local(cmd)
    if extract_cmd.failed:
        print(red("** Extraction failed, aborting."))
    else:
        print(cyan("** Extraction worked, updating files."))
        cmd = "pybabel update -i translations/messages.pot -d translations"
        update_cmd = local(cmd)
        if update_cmd.failed:
            print(red("** Update failed."))
        else:
            print(green("** Update worked. "))
            print(yellow("** Now you should push these changes to transifex."))
            print(yellow(""))
            print(yellow("      $ tx push --source"))
