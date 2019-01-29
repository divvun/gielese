# -*- encoding: utf-8 -*-
"""CSV -> XML thing

# TODO: update media xml format.

A two-step process for importing data.

 1. `convert` command converts a CSV into an XML file with media
    definitions.

 2. `copy_files` copies a directory structure with data from the CSV
    into a target directory with renamed files, with filenames based on CSV
    entries, and directory structure copied.

        /path/to/source/Lydfiler/KB/lydfile KB.mp3
          -> /path/to/target/Lydfiler/KB/term_name.mp3

Usage:
  make_xml.py convert --csv=<in_file> [-v | --verbose] [--rename=<target_path>]
  make_xml.py convert --csv=<in_file> --semantics=<semantic_tags> [-v | --verbose] [--rename=<target_path>]
  make_xml.py convert --csv=<in_file> --xml=<out_file> --semantics=<semantic_tags> [-v | --verbose] [--rename=<target_path>]
  make_xml.py copy_files --csv=<in_file> --source=<path_to_source_root> --target=<path_to_target_root> [-v | --verbose]

"""
import os, sys
import lxml

from csv import DictReader, Dialect, Sniffer
import csv

class TSV(Dialect):
    delimiter = '\t'
    quoting = csv.QUOTE_NONE
    lineterminator = '\n'

class CSV(Dialect):
    delimiter = ','
    quoting = csv.QUOTE_NONE
    lineterminator = '\n'

def pretty(node):
    from lxml.etree import tostring
    return tostring(node, pretty_print=True, encoding=unicode)

def adjust_string_to_filepath(_in):
    import re

    chars = {
        u'ï': u'_ii_',
        u'å': u'_aa_',
        u'ö': u'_oe_',
        u'æ': u'_ae_',
    }

    for k, v in chars.iteritems():
        if k in _in:
            _in = _in.replace(k, v)

    _in = re.sub('^_', '', _in)
    _in = re.sub('__', '_', _in)
    _in = re.sub('_$', '', _in)

    return _in.lower()

def create_entry(row, semantics=['TODO'], rename_files=False, verbose=False):
    import lxml.etree
    from lxml.builder import ElementMaker
    from lxml.etree import CDATA

    def wrapCDATA(str):
        return "<![CDATA[%s]]>" % str

    E = ElementMaker()
    XML_LANG = "{http://www.w3.org/XML/1998/namespace}lang"

    e = E.e
    lg = E.lg
    mg = E.mg
    t = E.t
    tg = E.tg
    l = E.l

    media = E.media
    img = E.img
    path = E.path
    sound = E.sound

    tgs = []

    _semantics = row.get('semantics', semantics)

    _sma = row.get('sma', False)
    _nob = row.get('nob', False)
    _swe = row.get('swe', False)

    lg_node = lg(l(_sma))

    def rename_file(_p):
        return adjust_file_name(_sma, _p, rename_files)

    semantics = []
    if _semantics:
        for _sem in _semantics:
            semantics.append(E.sem(**{'class':_sem}))

    semantics = E.semantics(*semantics)

    if _nob:
        tgs.append( tg( t(_nob), {XML_LANG: 'nob'}))

    if _swe:
        tgs.append( tg( t(_swe), {XML_LANG: 'swe'}))

    _img = row.get('img', False)
    _mp3 = row.get('mp3', False)

    medias = []
    if _img:
        _images = []
        for i in _img.split(';'):
            _p = path()
            _p.text = CDATA(rename_file(_img))
            _images.append(E.image(_p))
        medias.append(E.images(*_images))

    if _mp3:
        sounds = []
        for i in _mp3.split(';'):
            _m = path()
            _m.text = CDATA(rename_file(i))
            sounds.append(sound(_m))
        medias.append(E.sounds(*sounds))

    e_node = e(lg_node, media(*medias), mg(semantics, *tgs))

    return e_node

def read_csv(file_path):

    with open(file_path, 'rb') as F:
        lines = unicode(F.read().decode('utf-8')).splitlines()
        header, rest = lines[0].split(','), map(lambda x: x.split(','), lines[1::])

    _row_dicts = []
    for r in rest:
        row = dict(zip(header, r))
        _row_dicts.append(row)

    return header, rest, _row_dicts


def reformat_file(arguments):
    from functools import partial
    from lxml.builder import ElementMaker

    _in_file = arguments.get('--csv')
    _out_file = arguments.get('--xml', False)
    semantics = arguments.get('--semantics', False)
    _verbose = arguments.get('--verbose', False)
    rename_files = arguments.get('--rename', False)

    E = ElementMaker()

    # TODO: file rename -- directory to take as relative root for all
    # filepaths in img and mp3

    # TODO: for images, create an orig/ dir, for later resize

    header, rest, _row_dicts = read_csv(_in_file)


    if semantics:
        _sems = semantics.split(',')
        create_entry_with_semantics = partial(create_entry, semantics=_sems, rename_files=rename_files, verbose=_verbose)
    else:
        create_entry_with_semantics = partial(create_entry, rename_files=rename_files, verbose=_verbose)

    _r = E.r(*map(create_entry_with_semantics, _row_dicts))

    if _out_file:
        with open(_out_file, 'w') as F:
            F.write(pretty(_r).encode('utf-8'))
            print >> sys.stdout, "Written to %s" % _out_file
    else:
        print >> sys.stdout, pretty(_r).encode('utf-8')

def fix_path(file_path):
    import os
    return os.path.normpath(file_path)

def adjust_file_name(term, source_path, target_base):
    import os

    dir_path = os.path.dirname(fix_path(source_path))
    source_name = os.path.basename(fix_path(source_path))
    source_file_type = source_name.split('.')[-1]

    new_file_name = '%s.%s' % (adjust_string_to_filepath(term), source_file_type)

    new_file_path = fix_path(
        os.path.join(target_base, dir_path, new_file_name)
    )

    return new_file_path

def create_target_paths(mv_pairs):
    import os
    dirs = set(
        [os.path.dirname(_p) for _, _p in mv_pairs]
    )
    for _dir in dirs:
        print >> sys.stdout, " mkdir %s" % _dir
        try:
            os.makedirs(_dir)
        except:
            continue

def copy_files(arguments):
    import shutil

    # Here we copy files to a new directory, renaming the files in
    # accordance to what will be in the XML file.

    # Maintain the directory structure past the root, but rename the
    # file itself. If a file doesn't exist, need to warn about all of
    # them.

    _in_file = arguments.get('--csv')

    _src_dir = arguments.get('--source').decode('utf-8')
    _trg_dir = arguments.get('--target').decode('utf-8')

    _verbose = arguments.get('--verbose', False) or arguments.get('-v', False)

    if '~' in _src_dir:
        print >> sys.stderr, "Use absolute paths."
        sys.exit()

    print >> sys.stdout, " * Copying files from <%s> to <%s>" % (_src_dir, _trg_dir)

    header, rest, _row_dicts = read_csv(_in_file)

    def add_src(t):
        return fix_path(_src_dir + '/' + t)

    missing = []

    def source_path_exists((_src, _trg)):
        import os
        import locale

        try:
            if os.stat(os.path.abspath(_src)):
                return True
            else:
                missing.append(_src)
                return False
        except:
            missing.append(_src)
            return False

    all_file_update_pairs = []

    for row in _row_dicts:
        term = row.get('sma')
        source_files = map( fix_path
                          , row.get('mp3').split(';')
                          )
        source_files += map( fix_path
                           , row.get('img').split(';')
                           )
        source_files_with_path = map(add_src, source_files)
        target_files = [adjust_file_name(term, s, _trg_dir) for s in source_files]

        pairs = filter( source_path_exists
                      , zip(source_files_with_path, target_files)
                      )

        all_file_update_pairs.extend(pairs)


    create_target_paths(all_file_update_pairs)

    errors = []
    for _from, _to in all_file_update_pairs:
        try:
            if _verbose:
                print " %s \n   -> %s" % (_from, _to)
            shutil.copyfile(_from, _to)
        except Exception, e:
            print e
            errors.append((_from, _to))

    if len(missing) > 0:
        print >> sys.stderr, "Missing files: "
        for pair in missing:
            print ' * %s' % pair[0]

    if len(errors) > 0:
        print >> sys.stderr, "Error moving: "
        for pair in errors:
            print ' * %s' % pair[0]


def main():
    from docopt import docopt

    arguments = docopt(__doc__, version='make_xml 0.0.1')

    if arguments.get('convert'):
        reformat_file(arguments)

    if arguments.get('copy_files'):
        copy_files(arguments)

if __name__ == "__main__":
    sys.exit(main())
