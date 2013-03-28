""" Most of this is copied from NDS's lexicon XML parsers and classes
"""

from lxml import etree
regexpNS = "http://exslt.org/regular-expressions"

class MediaXML(object):
    _all = etree.XPath('.//e')
    lemma = etree.XPath('.//e[lg/l/text() = $lemma]')
    lemmaPOS = etree.XPath(
        './/e[lg/l/text() = $lemma and re:match(lg/l/@pos, $pos, "i")]',
        namespaces={'re': regexpNS})

    def XPath(self, xpathobj, *args, **kwargs):
        return xpathobj(self.tree, *args, **kwargs)

    def allEntries(self):
        return self.XPath(self._all)

    def lookupLemma(self, lemma):
        return self.XPath( self.lemma
                         , lemma=lemma
                         )

    def lookupLemmaPOS(self, lemma, pos):
        # Can't insert variables in EXSLT expressions within a compiled
        # xpath statement, so doing this.
        pos = "^%s$" % pos
        return self.XPath( self.lemmaPOS
                         , lemma=lemma
                         , pos=pos
                         )

    def cleanEntry(self, e):
        ts = e.findall('mg/tg/t')
        ts_text = [t.text for t in ts]
        ts_pos = [t.get('pos') for t in ts]

        l = e.find('lg/l')
        right_text = [l.text]

        return {'left': ts_text, 'pos': ts_pos, 'right': right_text}

    def __init__(self, filename):
        self.tree = etree.parse(filename)

class EntryNodeIterator(object):
    """ A class for iterating through the result of an LXML XPath query,
    while cleaning the nodes into a more usable format.

    .clean() is where most of the magic happens, so if new formats are
    needed, just override this.

    """

    def l_node(self, entry):
        l = entry.find('lg/l')
        lemma = l.text
        pos = l.get('pos')
        context = l.get('context')
        type = l.get('type')
        hid = l.get('hid')
        if context == None:
            context = False
        if type == None:
            type = False
        if hid == None:
            hid = False

        return lemma, pos, context, type, hid

    def tg_nodes(self, entry):
        target_lang = self.query_kwargs.get('target_lang', False)

        if target_lang:
            ts = entry.xpath("mg/tg[@xml:lang='%s']/t" % target_lang)
            tgs = entry.xpath("mg/tg[@xml:lang='%s']" % target_lang)

        if not target_lang or len(tgs) == 0:
            ts = entry.findall('mg/tg/t')
            tgs = entry.findall('mg/tg')

        return tgs, ts

    def examples(self, tg):
        _ex = [ (xg.find('x').text, xg.find('xt').text)
                for xg in tg.findall('xg') ]
        if len(_ex) == 0:
            return False
        else:
            return _ex

    def find_translation_text(self, tg):

        def orFalse(l):
            if len(l) > 0:
                return l[0]
            else:
                return False

        text = False
        re = tg.find('re')
        te = tg.find('te')
        tf = tg.find('tf')

        te_text = ''
        re_text = ''
        tf_text = ''

        if te is not None:      te_text = te.text
        if re is not None:      re_text = re.text
        if tf is not None:      tf_text = tf.text

        tx = tg.findall('t')

        link = True

        if not tx:
            if te_text:
                text, te_text = [te_text], ''
            elif re_text:
                text, re_text = [re_text], ''
            elif tf_text:
                text, tf_text = [tf_text], ''
        else:
            text = [_tx.text for _tx in tx if _tx.text is not None]

        lang = tg.xpath('@xml:lang')

        annotations = [a for a in [te_text, re_text, tf_text] if a.strip()]

        return text, annotations, lang

    def __init__(self, nodes, *query_args, **query_kwargs):
        if not nodes or len(nodes) == 0:
            self.nodes = []
        else:
            self.nodes = nodes
        self.query_args = query_args
        self.query_kwargs = query_kwargs

    def __iter__(self):
        for node in self.nodes:
            yield self.clean(node)

def flatten(_list):
    return list(sum(_list, []))

class SimpleJSON(EntryNodeIterator):
    """ A simple JSON-ready format for /lookups/
    """

    def clean(self, e):
        def _path(n):
            try:
                return n.find('path').text
            except:
                return False

        def image_features(n):
            from collections import defaultdict
            features = n.find('features')
            if not features:
                return False
            feats = defaultdict(list)
            for c in features.iterchildren():
                feats[c.tag].append(c.text)
            return dict(feats)

        def sound_features(n):
            features = n.find('features')
            if not features:
                return False
            feats = {}
            for c in features.iterchildren():
                feats[c.tag] = c.attrib
            return feats

        lemma, lemma_pos, lemma_context, _, lemma_hid = self.l_node(e)
        tgs, ts = self.tg_nodes(e)

        translations = map(self.find_translation_text, tgs)
        right_text = flatten([a for a, b, c in translations])
        right_langs = flatten([c for a, b, c in translations])

        media = e.find('media')
        media_defs = {}

        if media is not None:
            sound = media.find('sound')
            image = media.find('img')
            if sound is not None:
                media_defs['sound'] = {'path': _path(sound),
                                       'features': sound_features(sound)}
            if image is not None:
                media_defs['image'] = {'path': _path(image),
                                       'features': image_features(image)}

        # TODO: redo translations
        return { 'lemma': lemma
               , 'context': lemma_context
               , 'pos': lemma_pos
               , 'translations': right_text
               , 'lang': right_langs
               , 'hid': lemma_hid
               , 'media': media_defs
               }

def install_media_references(_d, filename):
    _add = _d.session.add
    _commit = _d.session.commit

    word_elements = list(SimpleJSON(MediaXML(filename).allEntries()))

    print word_elements

