import os, sys
import lxml

from csv import DictReader, Dialect, Sniffer
import csv

class TSV(Dialect):
    delimiter = '\t'
    quoting = csv.QUOTE_NONE
    lineterminator = '\n'

def pretty(node):
    from lxml.etree import tostring
    return tostring(node, pretty_print=True, encoding=unicode)

def create_entry(row, semantics=['TODO']):
    import lxml.etree
    from lxml.builder import ElementMaker
    from lxml.etree import CDATA

    def wrapCDATA(str):
        return "<![CDATAA[%s]]>" % str

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

    semantics = []
    if _semantics:
        for _sem in _semantics:
            semantics.append(E.sem(**{'class':_sem}))

    semantics = E.semantics(*semantics)

    if _nob:
        tgs.append( tg( t(_nob, {XML_LANG: 'nob'})))

    if _swe:
        tgs.append( tg( t(_swe, {XML_LANG: 'swe'})))

    _img = row.get('img', False)
    _mp3 = row.get('mp3', False)

    medias = []
    if _img:
        _images = []
        for i in _img.split(','):
            _p = path()
            _p.text = CDATA(_img)
            _images.append(E.image(_p))
        medias.append(E.images(*_images))

    if _mp3:
        sounds = []
        for i in _mp3.split(','):
            _m = path()
            _m.text = CDATA(i)
            sounds.append(sound(_m))
        medias.append(E.sounds(*sounds))

    e_node = e(lg_node, media(*medias), mg(semantics, *tgs))

    return e_node

def main():
    from functools import partial
    from lxml.builder import ElementMaker
    E = ElementMaker()

    with open(sys.argv[1], 'rb') as F:
        lines = unicode(F.read().decode('utf-8')).splitlines()
        header, rest = lines[0].split('\t'), map(lambda x: x.split('\t'), lines[1::])

    _row_dicts = []
    for r in rest:
        row = dict(zip(header, r))
        _row_dicts.append(row)

    if len(sys.argv) > 2:
        _sems = sys.argv[2].split(',')
        create_entry_with_semantics = partial(create_entry, semantics=_sems)
    else:
        create_entry_with_semantics = partial(create_entry)

    _r = E.r(*map(create_entry_with_semantics, _row_dicts))

    print >> sys.stdout, pretty(_r).encode('utf-8')


if __name__ == "__main__":
    sys.exit(main())
