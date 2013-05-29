""" Most of this is copied from NDS's lexicon XML parsers and classes
"""

import sys
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
        if context is None:
            context = False
        if type is None:
            type = False
        if hid is None:
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

        if te is not None:
            te_text = te.text
        if re is not None:
            re_text = re.text
        if tf is not None:
            tf_text = tf.text

        tx = tg.findall('t')

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
            try:
                yield self.clean(node)
            except Exception, e:
                print >> sys.stderr, "Error parsing node."
                print >> sys.stderr, etree.tostring(node, pretty_print=True)
                yield self.clean(node)

def flatten(_list):
    return list(sum(_list, []))

class MediaSimpleJSON(EntryNodeIterator):

    def clean(self, e):
        def _path(n):
            try:
                return n.find('path').text
            except:
                return False

        def image_features(n):
            from collections import defaultdict
            features = n.find('features')
            if features is None:
                return False
            feats = defaultdict(list)
            for c in features.iterchildren():
                feats[c.tag].append(c.text)
            return dict(feats)

        def sound_features(n):
            features = n.find('features')
            if features is None:
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

        media_type = False
        if media is not None:
            sounds = media.find('sounds')
            images = media.find('images')
            if sounds is not None:
                media_defs['sounds'] = [ {'path': _path(sound),
                                         'features': sound_features(sound)}
                                         for sound in sounds
                                       ]
                media_type = 'mp3'

            if images is not None:
                media_defs['images'] = [ {'path': _path(image),
                                          'features': image_features(image)}
                                         for image in images
                                       ]
                media_type = 'img'

        # TODO: redo translations
        return { 'lemma': lemma
               , 'context': lemma_context
               , 'pos': lemma_pos
               , 'lang': media_type
               , 'hid': lemma_hid
               , 'media': media_defs
               }

class LexiconSimpleJSON(EntryNodeIterator):

    def find_translation_text(self, tg):
        """ Overriding parent because we want to also mark what kind
        of translation this is here.
        """

        try:
            lang = tg.xpath('@xml:lang')[0]
        except:
            # TODO: logger
            print >> sys.stderr, " * No language specified for translation group"

        def orFalse(l):
            if len(l) > 0:
                return l[0]
            else:
                return False

        def fix_keys(attrs):
            _attrs = dict(attrs)
            if 'stat' in _attrs:
                if _attrs['stat'] == 'pref':
                    _attrs['tcomm_pref'] = True
                if _attrs['stat'] == 'notpref':
                    _attrs['tcomm_pref'] = False
                _attrs.pop('stat')

            if 'tcomm' in _attrs:
                if _attrs['tcomm'] == 'no':
                    _attrs['tcomm'] = False
                if _attrs['tcomm'] == 'yes':
                    _attrs['tcomm'] = True
            for k in _attrs.keys():
                if 'XML' in k and 'namespace' in k:
                    _attrs.pop(k)
            return _attrs

        text = False
        re = tg.find('re')
        te = tg.find('te')
        tf = tg.findall('tf')
        tx = tg.findall('t')

        translations = []

        for t in tx:
            _t = fix_keys(t.attrib)
            _t['language'] = lang
            _t['lemma'] = t.text
            _t['phrase'] = ''
            translations.append(_t)

        for t in tf:
            _t = fix_keys(t.attrib)
            _t['language'] = lang
            _t['lemma'] = ''
            if t.text is not None:
                _t['phrase'] = t.text
                translations.append(_t)
            # TODO: {'explanation': 'blah', 'stat': 'pref', 'tcomm': 'etc'}

        return translations

    def clean(self, e):

        lemma, lemma_pos, lemma_context, _, lemma_hid = self.l_node(e)
        tgs, ts = self.tg_nodes(e)

        translations = map(self.find_translation_text, tgs)

        lemma_features = e.find('lg/l').attrib
        lemma_features.pop('pos')

        # lexicon isn't in sync with database column names
        attrsfx = lemma_features.get('attr', False)
        if attrsfx:
            lemma_features.pop('attr')
            lemma_features['attrsuffix'] = attrsfx

        gen_constraint = lemma_features.get('gen_only', False)

        try:
            lemma_features.pop('gen_only')
        except KeyError:
            pass

        semantics = [a.attrib.get('class') for a in e.find('mg/semantics')]

        # TODO: current language
        return { 'lemma': lemma
               , 'context': lemma_context
               , 'pos': lemma_pos
               , 'translations': translations
               , 'hid': lemma_hid
               , 'features': lemma_features
               , 'generation_constraint': gen_constraint
               , 'semantics': semantics
               }

def install_media_references(_d, filename):
    from lexicon_models import Concept, Semtype, Dialect

    _add = _d.session.add
    _commit = _d.session.commit

    def _get_or_create(model, **kwargs):
        instance = _d.session.query(model).filter_by(**kwargs).first()
        if instance:
            return instance
        else:
            instance = model(**kwargs)
            return instance

    word_elements = MediaSimpleJSON(MediaXML(filename).allEntries())

    for media_defs in word_elements:
        # Create a word, which later install process will add to
        # TODO: where to get source language
        wkws = dict( wordid=media_defs.get('lemma')
                   , lemma=media_defs.get('lemma')
                   , language='sma'
                   )

        if media_defs.get('pos', False):
            wkws['pos'] = media_defs.get('pos')

        if media_defs.get('hid', False):
            wkws['pos'] = media_defs.get('pos')

        word = _get_or_create(Concept, **wkws)

        _add(word)
        print " Installed word: %s" % word.lemma

        # Create WordTranslations with media defs.
        medias = media_defs.get('media', False)
        if 'images' in medias:
            image_medias = []
            for image in medias.get('images'):
                wt_kwargs = dict( language='img'
                                , lemma=image.get('path')
                                )
                # TODO: features / semantics, audio / voices
                wt = Concept(**wt_kwargs)
                word.translations_to.append(wt)
                image_medias.append(wt)
                print " Added image path: %s" % wt.lemma

        if 'sounds' in medias:
            audio_medias = []
            for sound in medias.get('sounds'):
                wt_kwargs = dict( language='mp3'
                                , lemma=sound.get('path')
                                )
                # TODO: features / semantics, audio / voices
                wt = Concept(**wt_kwargs)
                word.translations_to.append(wt)
                audio_medias.append(wt)
                print " Added audio path: %s" % wt.lemma

        # TODO: this
        if 'images' in medias and 'sounds' in medias:
            all_medias = audio_medias + image_medias
            for m in all_medias:
                for x in all_medias[:]:
                    if x != m:
                        m.translations_to.append(x)
                        m.translations_from.append(x)
            # audio_media.translations_to.append(image_media)
            # image_media.translations_to.append(audio_media)
            # audio_media.translations_from.append(image_media)
            # image_media.translations_from.append(audio_media)
            print " Crosslinking media."

        _commit()


def install_lexical_data(_d, filename):
    from lexicon_models import Concept, Semtype, Dialect

    # TODO: option for only installing data for lemmas existing in the
    # system? e.g., only want lexical data for which there is a media
    # entry
    _add = _d.session.add
    _commit = _d.session.commit

    def _get_or_create(model, **kwargs):
        instance = _d.session.query(model).filter_by(**kwargs).first()
        if instance:
            return instance
        else:
            instance = model(**kwargs)
            return instance

    tree = MediaXML(filename)
    word_elements = LexiconSimpleJSON(tree.allEntries())

    # Really only care about semantics, words, translations and dialects
    # here

    # Eventually wordforms, but can leave that out until absolutely
    # necessary

    lang = 'sma'
    for w in word_elements:

        # TODO: _get_or_create with word kwargs
        wkws = dict( wordid=w.get('lemma')
                   , language=lang
                   , lemma=w.get('lemma')
                   , pos=w.get('pos')
                   # TODO: , wordclass=wordclass # ?
                   , hid=w.get('hid')
                   # TODO: , valency=val
                   )

        # TODO: add columns to db maybe?
        features = w.get('features')
        if features:
            try:
                features.pop('margo')
            except:
                pass
            wkws.update(w.get('features'))

        word = _get_or_create(Concept, **wkws)

        for _sem in w.get('semantics', []):
            s = _get_or_create(Semtype, semtype=_sem)
            word.semtype.append(s)

        for _dial in w.get('dialects', []):
            d = _get_or_create(Dialect, dialect=_dial)
            word.dialects.append(d)

        # TODO: geography

        _add(word)

        # TODO: a bit more complex...
        for _tx in w.get('translations', []):
            for _t in _tx:
                if 'dict' in _t:
                    _t.pop('dict')
                # _t['word'] = word.id
                wt = Concept(**_t)
                word.translations_to.append(wt)

        _commit()
        print "Added: %s" % word.lemma
        print "  semantics: %s" % ', '.join([s.semtype for s in word.semtype])
        print "--"
        print ""

    # TODO: may need to commit with every word and obj, otherwise some sort of
    # integrity error

def append_lexicon(_d, filename):
    from lexicon_models import Concept, Semtype, Dialect

    # TODO: option for only installing data for lemmas existing in the
    # system? e.g., only want lexical data for which there is a media
    # entry
    _add = _d.session.add
    _commit = _d.session.commit
    _merge = _d.session.merge

    def _get_or_create(model, **kwargs):
        instance = _d.session.query(model).filter_by(**kwargs).first()
        if instance:
            return instance
        else:
            instance = model(**kwargs)
            return instance

    def _get(model, **kwargs):
        return _d.session.query(model).filter_by(**kwargs).first()

    tree = MediaXML(filename)
    word_elements = LexiconSimpleJSON(tree.allEntries())

    lang = 'sma'

    existing_ws = []

    def _get_existing(word_elem):
        _pos = word_elem.get('pos', False)
        _lem = word_elem.get('lemma', False)
        _wordid = word_elem.get('wordid', False)
        _hid = word_elem.get('hid', False)

        _kwargs = {}

        # if _pos:
        #     _kwargs['pos'] = _pos
        # if _hid:
        #     _kwargs['hid'] = _hid
        if _wordid:
            _kwargs['wordid'] = _wordid
        if _lem:
            _kwargs['lemma'] = _lem

        return _get(Concept, **_kwargs)

    def existing(word_elem):
        _w_obj = _get_existing(word_elem)
        if _w_obj is not None:
            existing_ws.append(_w_obj)
            return True
        else:
            return False

    lang = 'sma'
    print " * Words in database: %d" % _d.session.query(Concept).count()
    print " * Filtering out pre-existing entries"
    existing_words = filter(existing, word_elements)
    print len(list(existing_words))
    for w_infos in existing_words:

        w = _get_existing(w_infos)

        # update w object with w_infos

        # TODO: _get_or_create with word kwargs
        wkws = dict( wordid=w_infos.get('lemma')
                   , language=lang
                   , lemma=w_infos.get('lemma')
                   , pos=w_infos.get('pos')
                   # TODO: , wordclass=wordclass # ?
                   , hid=w_infos.get('hid')
                   # TODO: , valency=val
                   , id=w.id
                   )

        # TODO: geography

        features = w_infos.get('features')
        if features:
            try:
                features.pop('margo')
            except:
                pass
            wkws.update(w_infos.get('features'))

        word = Concept(**wkws)
        new_word = _merge(word)
        print " Installed word: %s" % new_word.lemma

        # NB: Merge object instead.

        for _sem in w_infos.get('semantics', []):
            s = _get_or_create(Semtype, semtype=_sem)
            new_word.semtype.append(s)

        for _dial in w_infos.get('dialects', []):
            d = _get_or_create(Dialect, dialect=_dial)
            new_word.dialects.append(d)


        # TODO: new_word.id, or find existing word pre-merge?
        for _tx in w_infos.get('translations', []):
            for _t in _tx:
                if 'dict' in _t:
                    _t.pop('dict')
                # _t['word'] = new_word.id
                wt = Concept(**_t)
                new_word.translations_to.append(wt)

        _commit()
        print "Merged: %s" % new_word.lemma
        print "  semantics: %s" % ', '.join([s.semtype for s in new_word.semtype])
        print "--"
        print ""

    # TODO: may need to commit with every word and obj, otherwise some sort of
    # integrity error

