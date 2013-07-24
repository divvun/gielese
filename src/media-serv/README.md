# Initializing media server

 * Create a virtualenv, run it and initialize from requirements.txt
 * `python manage.py init_db`
 * `python manage.py install_media -f ../data/sma_media.xml`
 * `python manage.py append_lexical_data -f ../data/n_smanob_test.xml`

The latter only installs/updates definitions for existing words from the
first step, if you want to just install everything, use:

 * `python manage.py install_lexicon -f ../data/n_smanob.xml`

## Final step

Prepare JSON files.

 * `python manage.py prepare_json`

# Internationalisation

    pybabel extract -F babel.cfg -k lazy_gettext -o translations/messages.pot .

However, NB: can't traverse symlinks so need to be specific

    pybabel extract -F babel.cfg -k lazy_gettext -o translations/messages.pot ../sma-client/

## initialising translations

    pybabel init -i translations/messages.pot -d translations -l sma
    pybabel init -i translations/messages.pot -d translations -l no
    pybabel init -i translations/messages.pot -d translations -l sv
    etc

## updating

    pybabel extract -F babel.cfg -k lazy_gettext -o translations/messages.pot .
    pybabel update -i translations/messages.pot -d translations


## compiling

    pybabel compile -d translations

## Updating from transifex

In order to use the transifex client, you need two things:

 * the gïelese virtual environment enabled
 * a user-specific configuration file for transifex in your own home
   directory: ~/.transifexrc ([docs](txdoc)), otherwise, the
   project-specific configuration is already checked in in 
   `src/media-serv/.tx/config`

 [txdoc]: http://support.transifex.com/customer/portal/articles/1000855-configuring-the-client

### user-specific file: ~/.transifexrc

The short of it is to copy all this, and replace the password. If more
is necessary, refer to docs. Token must be left blank.

    [https://www.transifex.com]
    hostname = https://www.transifex.com
    password = yourpasswordgoeshere!
    token = 
    username = aajegebot

### Basic operations

Once the virtualenv is enabled properly, this should mean that the
transifex command line client is available to use. Typically, all you
should need to be concerned with for fetching new translations is:

    tx pull

A specific language can be specified also: 

    tx pull -l sma
    tx pull --language sma

After updating translation strings in messages.pot, send them to the
server for translators to start working:

    tx push --source

If you have made modifications locally to any of the translation files,
you will need to include the `--translations` flag.

Further documentation on the command line tool's various options is [here](txopts).

  [txopts]: http://support.transifex.com/customer/portal/articles/960804-overview


### Additional docs: 

 * http://support.transifex.com/customer/portal/topics/440187-transifex-client/articles
 * `tx --help`



