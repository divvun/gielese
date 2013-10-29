# -*- encoding: utf-8 -*-
""" This reads a media directory and outputs it to several formats.
The expected input format for the directory is as follows:

    media_dir/
        concepts/
            concepts.info
            1/
                concept.info
                images/
                    small.jpg
                    medium.jpg
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

Usage:
  read_media_directory.py read concepts <media_dir> [options]
  read_media_directory.py read categories <media_dir> [options]
  read_media_directory.py -h | --help
  read_media_directory.py show example concepts.info
  read_media_directory.py show example concept.info
  read_media_directory.py show example category.info

Options:
  --output=format       Specifies the output format. XML, JSON, supported. [default: JSON]
  --absolute-paths      Use absolute paths instead of relative from `cwd`. [default: False]

"""

import os, sys
import yaml
import simplejson as json
import docopt

concepts_info_example = """
semantics:
  - FACE
  - BODY
"""

concept_info_example = u"""
lemma: ååredæjja
semantics:
  - BODY
  - FACE
translations:
  - nob: ansikt
    swe: ansikt
"""

category_info_example = u"""
TODO
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
        images.append({
            'path': path,
            'size': '',
            'device': '',
        })

    return images


def read_concept_directory(concept_dir, concepts_meta={}):
    """ Read a directory containing concept.info, returning
    concept.info, merging concepts.info, and then append any images and
    audio to `media`.
    """

    print "  Found concept:"
    print "    " + concept_dir

    _concept_yaml = os.path.join(concept_dir, 'concept.info')

    with open(_concept_yaml) as F:
        concept_yaml = yaml.load(F)

    concepts_meta.update(concept_yaml)

    media = {
        'images': find_concept_images(concept_dir),
        'audio': find_concept_audio(concept_dir)
    }

    concept = concept_yaml.copy()
    concept.update({'media': media})

    return concept

def read_concepts_directory(concept_dir):
    """ Search a concepts directory for directories containing a
    `concept.info` file, and then return parsed concepts.
    """

    print "Found concept set: "
    print "  " + concept_dir

    concept_yaml = os.path.join(concept_dir, 'concepts.info')

    with open(concept_yaml) as F:
        concept_set_yaml = yaml.load(F)

    concept_directories = find_directories_with(concept_dir, 'concept.info')

    concepts = []

    for c_dir in concept_directories:
        concepts.append(
            read_concept_directory(c_dir, concepts_meta=concept_set_yaml)
        )

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

def concepts_to_xml(concepts):
    pass

def concepts_to_json(concepts):
    return json.dumps(concepts, indent=' ' * 2)

def read_concepts(arguments):
    """ Walk the concepts directories for concepts, and output them to
        JSON or XML.

    """

    _cwd = os.getcwd()
    media_dir = os.path.join(_cwd, arguments.get('<media_dir>'))

    if not arguments.get('--absolute-paths', False):
        common = os.path.commonprefix([_cwd, media_dir])
        media_dir = media_dir.replace(common, '.')

    concept_dir = os.path.join(media_dir, 'concepts')
    # category_dir = os.path.join(media_dir, 'categories')

    concepts = walk_for_concepts_sets(concept_dir)

    if arguments.get('--output', False):
        if arguments.get('--output') == 'JSON':
            serializer = concepts_to_json
        if arguments.get('--output') == 'XML':
            serializer = concepts_to_xml

        serialized = serializer(concepts)
        print >> sys.stdout, serialized

def main():
    arguments = docopt.docopt(__doc__, version='Media parser 0.1.0')

    if arguments.get('read', False):
        if arguments.get('concepts', False):
            read_concepts(arguments)

    if arguments.get('show', False):
        if arguments.get('example', False):
            extra_doc(arguments)

    # print arguments

if __name__ == "__main__":
    sys.exit(main())
