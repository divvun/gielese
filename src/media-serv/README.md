# Initializing media server

 * Create a virtualenv, run it and initialize from requirements.txt
 * `python manage.py init_db`
 * `python manage.py install_media -f ../data/sma_media.xml`
 * `python manage.py append_lexical_data -f ../data/n_smanob_test.xml`

The latter only installs/updates definitions for existing words from the
first step, if you want to just install everything, use:

 * `python manage.py install_lexicon -f ../data/n_smanob.xml`

