# -*- encoding: utf-8 -*-
""" This reads a media directory and outputs it to several formats.
The expected input format for the directory is as follows:

    media_dir/
        concepts/
            concepts.info
            1/
                concept.info
                images/
                    filename.jpg
                    filename2.jpg
                    filename-small-mobile.jpg
                    filename-medium-tablet.jpg
                audio/
                    AD.mp3
            2/
            3/
        categories/
            categories.info
            face/
                category.info

The structure may be fairly open, but the requirements are that concepts
must be in the concepts directory and categories in categories. Each
directory that should be treated specially has its own meta file:
concepts.info, concept.info, categories.info, category.info. This
allows you to create some subdirectory structure and apply meta data
to all subdirectories. Thus, maybe you want to organize concepts into
sub directories relating to semantics, you might do the following:

Image file names may be whatever, with two exceptions: to mark the size
and intended device type, they must follow the pattern:

    filename-small-mobile.jpg
    filename-medium-tablet.jpg

Or...

    filename-size-device.jpg

'Filename' may be replaced with anything, but avoid spaces.

    concepts/
        body/
            concepts.info
            1/
                concept.info
                ...
            2/
                concept.info
                ...

Thus, if the concepts.info file contains a key describing `semantics`
this key, will be copied to 1/concept.info, unless concept.info also
contains a `semantics` entry.

Each concept must have its own directory, which may be named anything,
but what recognizes this directory as a concept is the `concept.info`
file. This is a YAML file which defines the concept, and provides
additional instructions on how it is handled.

The same idea follows for `categories`, where the directory may be
structured however, but a `category.info` file is the trigger for this
directory to be processed as a category.

TODO: category needs a little more specific structure for media sizes,
write more there.

TODO: how to specify media sizes? additional meta, or rough guessing
from image size?

TODO: merge in stuff from make_xml, including an output directory, which
then copies and transforms files to a format compatible with Gielese

TODO: categories.info + category.info

Usage:
  read_media_directory.py read concepts <media_dir> [options]
  read_media_directory.py read categories <media_dir> [options]
  read_media_directory.py -h | --help
  read_media_directory.py show example concepts.info
  read_media_directory.py show example concept.info
  read_media_directory.py show example categories.info
  read_media_directory.py show example category.info

Options:
  --output=format       Specifies the output format. XML, JSON, supported. [default: JSON]
  --absolute-paths      Use absolute paths instead of relative from `cwd`. [default: False]
  --media-path=URL      Specify the path relative to the web root for media. [default: False]

"""

import os, sys
import yaml
import simplejson as json
import docopt

import lxml.etree
from lxml.builder import ElementMaker
from lxml.etree import CDATA
from lxml import etree

concepts_info_example = """
semantics:
  - FACE
  - BODY
"""

# things like this should really happen at a different phase. maybe
# build in conversion to an install process or something

# concepts_media_transforms = """
# media_transforms:
#   - size: "orig"
#     target:
#       size: "medium"
#       device: "tablet"
#       max_width: 350
#       max_height: 350
#   - size: "orig"
#     target:
#       size: "small"
#       device: "mobile"
#       max_width: 200
#       max_height: 200
# 
# media_matching:
#   - file_pattern: "(small)"
#     apply_attributes:
#       size: "small"
#       device: "mobile"
# 
#   - file_pattern: "(medium)"
#     apply_attributes:
#       size: "medium"
#       device: "tablet"
# 
#   - file_pattern: "(orig)"
#     apply_attributes:
#       size: "original"
#       device: ""
# """

concept_info_example = u"""
lemma: ååredæjja
semantics:
  - BODY
  - FACE
translations:
  - nob: ansikt
    swe: ansikt
"""

# TODO: include media, or assume media structure
categories_info_example = u"""
main_menu: true
"""

category_info_example = u"""
category: "BODYPART"
name: "Ååredæjja"
semantics:
  - "BODYPART"
"""

def extra_doc(arguments):
    if arguments.get('concepts.info', False):
        print >> sys.stdout, concepts_info_example.encode('utf-8')
    if arguments.get('concept.info', False):
        print >> sys.stdout, concept_info_example.encode('utf-8')
    if arguments.get('category.info', False):
        print >> sys.stdout, concept_info_example.encode('utf-8')

def find_directories_with(path, filename):
    """ Search a path returning directories that contain a filename.
    """

    directories = []

    for root, dirs, files in os.walk(path):
        if filename in files:
            directories.append(root)

    return directories

def find_concept_audio(concept_dir):
    """ Search a path, returning concepts matching audio/ in the
    mimetype.
    """
    import mimetypes

    audio_paths = []

    for root, dirs, files in os.walk(concept_dir):
        for _file in files:
            _type, _enc = mimetypes.guess_type(_file)
            if _type is not None and 'audio/' in _type:
                audio_paths.append(
                    os.path.join(root, _file)
                )

    audio = []

    for path in audio_paths:
        audio.append({
            'path': path,
        })

    return audio

def find_concept_images(concept_dir):
    """ Search a path, returning concepts matching image/ in the
    mimetype.
    """

    import mimetypes

    image_paths = []

    for root, dirs, files in os.walk(concept_dir):
        for _file in files:
            _type, _enc = mimetypes.guess_type(_file)
            if _type is not None and 'image/' in _type:
                image_paths.append(
                    os.path.join(root, _file)
                )

    images = []

    for path in image_paths:
        _file = os.path.basename(path)
        _f, _, _suffix = _file.partition('.')
        _ff = _f.split('-')
        if len(_ff) == 3:
            _, size, device = _ff
        else:
            size = 'orig'
            device = ''

        images.append({
            'path': path,
            'size': size,
            'device': device,
        })

    return images

def find_concept_video(concept_dir):
    """ Search a path, returning concepts matching image/ in the
    mimetype.
    """

    import mimetypes

    image_paths = []

    for root, dirs, files in os.walk(concept_dir):
        for _file in files:
            _type, _enc = mimetypes.guess_type(_file)
            if _type is not None and 'video/' in _type:
                image_paths.append(
                    os.path.join(root, _file)
                )

    video = []

    for path in image_paths:
        video.append({
            'path': path,
            'size': '',
            'device': '',
        })

    return video


def read_concept_directory(concept_dir, concepts_meta={}):
    """ Read a directory containing concept.info, returning
    concept.info, merging concepts.info, and then append any images and
    audio to `media`.
    """

    print >> sys.stderr, "  Found concept:"
    print >> sys.stderr, "    " + concept_dir

    _concept_yaml = os.path.join(concept_dir, 'concept.info')

    with open(_concept_yaml, 'r') as F:
        try:
            concept_yaml = yaml.load(F)
        except Exception, e:
            print >> sys.stderr, " Error parsing yaml at: " + _concept_yaml
            sys.exit()

    if concept_yaml is None:
        return

    concept_yaml.update(concepts_meta)

    media = {
        'images': find_concept_images(concept_dir),
        'video': find_concept_video(concept_dir),
        'audio': find_concept_audio(concept_dir)
    }

    concept = concept_yaml.copy()
    concept.update({'media': media})

    return concept

def read_concepts_directory(concept_dir):
    """ Search a concepts directory for directories containing a
    `concept.info` file, and then return parsed concepts.
    """

    print >> sys.stderr, "Found concept set: "
    print >> sys.stderr, "  " + concept_dir

    concept_yaml = os.path.join(concept_dir, 'concepts.info')

    with open(concept_yaml) as F:
        concept_set_yaml = yaml.load(F)

    concept_directories = find_directories_with(concept_dir, 'concept.info')

    concepts = []

    for c_dir in concept_directories:
        new_concept = read_concept_directory(c_dir, concepts_meta=concept_set_yaml)
        if new_concept is not None:
            concepts.append(new_concept)

    return concepts

def walk_for_concepts_sets(concept_path):
    """ Find all the directories that are marked as being concepts
    directories: containing a `concepts.info` file.
    """

    concept_directories = find_directories_with(concept_path, 'concepts.info')

    # Flatten and read all concepts
    concepts = sum(
        map(read_concepts_directory, concept_directories),
        []
    )

    return concepts

def replace_media_paths(concepts, replace_with):


    def replace_path(p):
        return replace_with + p[1::]
    
    def get_replace(media):
        if 'path' in media:
            media['path'] = replace_path(media['path'])
        return media

    fixed = []
    for c in concepts:
        media = c.get('media').copy()
        if 'images' in media:
            media['images'] = map(get_replace, media['images'])

        if 'audio' in media:
            media['audio'] = map(get_replace, media['audio'])

        if 'video' in media:
            media['video'] = map(get_replace, media['video'])

        c['media'] = media

        fixed.append(c)

    return fixed

def concepts_to_xml(concepts):

    E = ElementMaker()

    def create_entry(concept, rename_files=False, verbose=False):

        def wrapCDATA(str):
            return "<![CDATAA[%s]]>" % str

        XML_LANG = "{http://www.w3.org/XML/1998/namespace}lang"

        e, lg, mg = E.e, E.lg, E.mg
        t, tg = E.t, E.tg

        l = E.l

        media = E.media
        img, path_node, sound = E.img, E.path, E.sound

        tgs = []

        _semantics = concept.get('semantics', [])
        lemma = concept.get('lemma', False)
        translations = concept.get('translations', [])

        _meds = concept.get('media', {})
        _images = _meds.get('images', False)
        _video = _meds.get('video', False)
        _audio = _meds.get('audio', False)

        lg_node = lg(l(lemma))

        def rename_file(_p):
            if rename_files:
                return adjust_file_name(_sma, _p, rename_files)
            else:
                return _p

        semantics = []
        if _semantics:
            for _sem in _semantics:
                semantics.append(E.sem(**{'class':_sem}))

        semantics = E.semantics(*semantics)

        for tgroup in translations:
            _tg = []
            for lang, translation in tgroup.iteritems():
                try:
                    _tg_node = tg( t(translation), {XML_LANG: lang})
                except TypeError:
                    print "Unable to build <tg /> node. Possible yaml formatting error."
                    print translation, lang
                    print concept
                    sys.exit()
                _tg.append(_tg_node)
            tgs.extend(_tg)

        medias = []
        if _images:
            images = []
            for i in _images:

                style_kwargs = {}
                if i.get('size', False):
                    style_kwargs['size'] = i['size']
                if i.get('device', False):
                    style_kwargs['device'] = i['device']

                file_path = rename_file(i.get('path'))
                _p = path_node()
                _p.text = CDATA(file_path)

                images.append(
                    E.image(_p, style_kwargs)
                )

            medias.append(E.images(*images))

        if _video:
            video = []
            for i in _video:

                style_kwargs = {}
                if i.get('size', False):
                    style_kwargs['size'] = i['size']
                if i.get('device', False):
                    style_kwargs['device'] = i['device']

                file_path = rename_file(i.get('path'))
                _p = path_node()
                _p.text = CDATA(file_path)

                video.append(
                    E.video(_p, style_kwargs)
                )

            medias.append(E.video(*video))

        if _audio:
            audio = []
            for i in _audio:
                _m = path_node()
                _m.text = CDATA(rename_file(i.get('path')))
                audio.append(sound(_m))
            medias.append(E.sounds(*audio))

        meaning_group = mg(semantics, *tgs)
        e_node = e(lg_node, media(*medias), meaning_group)

        return e_node

    _r = E.r
    nodes = _r(*map(create_entry, concepts))

    return etree.tostring(nodes, pretty_print=True, encoding=unicode)


def concepts_to_json(concepts):
    return json.dumps(concepts, indent=' ' * 2)

def read_concepts(arguments):
    """ Walk the concepts directories for concepts, and output them to
        JSON or XML.
    """

    _cwd = os.getcwd()
    media_dir = os.path.join(_cwd, arguments.get('<media_dir>'))

    # specify media path, requires relative paths
    if arguments.get('--media-path', False):
        replace_path = arguments.get('--media-path')
        common = os.path.commonprefix([_cwd, media_dir])
        media_dir = media_dir.replace(common, '.')
    else:
        replace_path = False

        if not arguments.get('--absolute-paths', False):
            common = os.path.commonprefix([_cwd, media_dir])
            media_dir = media_dir.replace(common, '.')

    concept_dir = os.path.join(media_dir, 'concepts')

    concepts = walk_for_concepts_sets(concept_dir)

    if replace_path:
        concepts = replace_media_paths(concepts, replace_path)

    if arguments.get('--output', False):

        if arguments.get('--output') == 'JSON':
            serializer = concepts_to_json
        if arguments.get('--output') == 'XML':
            serializer = concepts_to_xml

        serialized = serializer(concepts)
        print >> sys.stdout, serialized.encode('utf-8')

def read_categories(arguments):

    # TODO: consider subcategories -- need to find out if one category
    # is contained by another

    _cwd = os.getcwd()
    media_dir = os.path.join(_cwd, arguments.get('<media_dir>'))

    if not arguments.get('--absolute-paths', False):
        common = os.path.commonprefix([_cwd, media_dir])
        media_dir = media_dir.replace(common, '.')

    categories = walk_for_categories_sets(concept_dir)

    if arguments.get('--output', False):

        if arguments.get('--output') == 'JSON':
            serializer = concepts_to_json
        if arguments.get('--output') == 'XML':
            serializer = concepts_to_xml

        serialized = serializer(categories)
        print >> sys.stdout, serialized

def main():
    arguments = docopt.docopt(__doc__, version='Media parser 0.1.0')

    if arguments.get('read', False):
        if arguments.get('concepts', False):
            read_concepts(arguments)
        if arguments.get('categories', False):
            read_categories(arguments)

    if arguments.get('show', False):
        if arguments.get('example', False):
            extra_doc(arguments)

    # print arguments

if __name__ == "__main__":
    sys.exit(main())
