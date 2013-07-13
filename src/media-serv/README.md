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

