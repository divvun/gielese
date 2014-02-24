"""
Media directory deployment for PhoneGap
---------------------------------------

This tool is intended to manage deployment of media files to the
PhoneGap source directories for the purpose of:

  * Removing original-sized media files that aren't in use in the
    application

NB: sound is ignored from this process for now, because these are all
expected to be compressed and not have much variance quality across
platforms

TODO: warn when the directory only contains an original size, and no
compressed versions.

    # For iPhone and Android Phones

    python deploy_media_directory.py copy media \
            static/media \
            ../sma-client/phonegap/gielese/www/static/media \
            --strip-formats=original,orig,medium \
            --keep-orphan-formats

    # For Tablets

    python deploy_media_directory.py copy media \
            static/media \
            ../sma-client/phonegap/gielese/www/static/media \
            --strip-formats=original,orig,small \
            --keep-orphan-formats

TODO: this process should also be used for deploying the standalone version,
      so media needs to be stored in another location.

TODO: copy json

Usage:
  deploy_media_directory.py list sizes <target_dir>
  deploy_media_directory.py copy json <source_dir> <target_dir> [options]
  deploy_media_directory.py copy media <source_dir> <target_dir> [options]
  deploy_media_directory.py -h | --help

Options:
  --keep-orphan-formats  Do not remove files if they are the only format available.
  --strip-formats=LIST   Specifies media formats to strip. Separate by comma.
  --prune-dry-run        Copies but does not prune.
"""

import os, sys

def copy_directory(src, targ):
    import shutil

    print >> sys.stderr, " * Copying <%s> to <%s>" % (src, targ)

    # TODO: directory exists, overwrite prompt?

    shutil.copytree(src, targ, symlinks=True)

    print >> sys.stderr, " * Copied."

def prune_concept_media(target, **prune_opts):
    """ This reads the concepts directory, and removes file sizes
    specified by --strip-formats. Only deletes if --prune-dry-run is not
    specified, and optionally warns if the --strip-formats setting will
    result in no more media sizes available; always need a fallback.
    """

    from collections import defaultdict
    from read_media_directory import walk_for_concepts_sets

    print >> sys.stderr, ""
    print >> sys.stderr, "Beginning concept pruning."
    print >> sys.stderr, ""

    prune_sizes = prune_opts.get('strip_formats', [])
    keep_orphans = prune_opts.get('keep_orphans', False)
    dry_run = prune_opts.get('dry_run', False)
    collect_media_sizes = prune_opts.get('media_sizes', False)

    if collect_media_sizes:
        dry_run = True

    concepts = walk_for_concepts_sets(target)

    remove_paths = []

    media_sizes = defaultdict(set)

    for concept in concepts:
        media = concept.get('media')
        images = media.get('images')
        audio = media.get('audio')
        videos = media.get('videos')
        name = concept.get('lemma')

        if collect_media_sizes:
            img_media_sizes = set([i.get('size', 'UNSPECIFIED') for i in images])
            # aud_media_sizes = set([i.get('size', 'UNSPECIFIED') for i in audio])
            vid_media_sizes = set([i.get('size', 'UNSPECIFIED') for i in videos])

            media_sizes['images'].update(img_media_sizes)
            # media_sizes['audio'].update(aud_media_sizes)
            media_sizes['videos'].update(vid_media_sizes)

            continue

        if len(images) == 1 and keep_orphans:
            print >> sys.stderr, "Concept <%s> images cannot be pruned: orphans would result." % name
        elif len(images) == 0 and keep_orphans:
            print >> sys.stderr, "Concept <%s> has no images." % name
        else:
            for img in images:
                print img.get('size')
                if img.get('size') in prune_sizes:
                    remove_paths.append(img.get('path'))

        if len(videos) == 1 and keep_orphans:
            print >> sys.stderr, "Concept <%s> videos cannot be pruned: orphans would result." % name
        elif len(videos) == 0 and keep_orphans:
            print >> sys.stderr, "Concept <%s> has no videos." % name
        else:
            for vid in videos:
                if vid.get('size') in prune_sizes:
                    remove_paths.append(vid.get('path'))

        # TODO: assuming audio is always compressed for now.
        # if len(audio) == 1 and keep_orphans:
        #     print >> sys.stderr, "Concept <%s> audio cannot be pruned: orphans would result." % name
        # elif len(audio) == 0 and keep_orphans:
        #     print >> sys.stderr, "Concept <%s> has no audio." % name
        # else:
        #     for aud in audio:
        #         print aud.get('path')
        #         raw_input()
        #         if aud.get('size') in prune_sizes:
        #             remove_paths.append(aud.get('path'))

    if dry_run:
        print >> sys.stderr, "DRY RUN, no deletion."
        for path in remove_paths:
            print >> sys.stderr, " * Marked for deletion: " + path
        print >> sys.stderr, "DRY RUN, no deletion."
    else:
        for path in remove_paths:
            os.remove(path)
            print >> sys.stderr, " * Deleted: " + path

    print >> sys.stderr, "Concept processing done."
    print >> sys.stderr, ""
    print >> sys.stderr, ""

    if collect_media_sizes:
        print >> sys.stderr, "Concept media sizes are:"
        # TODO: format
        for k, v in media_sizes.iteritems():
            print >> sys.stderr, "  " + k + "  :  " + ','.join(v)



def prune_category_media(target, **prune_opts):
    """ This reads the category directory, and removes file sizes
    specified by --strip-formats. Only deletes if --prune-dry-run is not
    specified, and optionally warns if the --strip-formats setting will
    result in no more media sizes available; always need a fallback.
    """

    from read_media_directory import walk_for_categories_sets

    prune_sizes = prune_opts.get('strip_formats', [])
    keep_orphans = prune_opts.get('keep_orphans', False)
    dry_run = prune_opts.get('dry_run', False)

    categories = walk_for_categories_sets(target)

    remove_paths = []

    for category in categories.get('categories'):
        # print category.get('media')
        media = category.get('media')
        images = media.get('image')
        icons = media.get('icon')
        name = category.get('name')

        if len(images) == 1 and keep_orphans:
            print >> sys.stderr, "Category <%s> images cannot be pruned: orphans would result." % name
        elif len(images) == 0 and keep_orphans:
            print >> sys.stderr, "Category <%s> has no images." % name
        else:
            for img in images:
                if img.get('size') in prune_sizes:
                    remove_paths.append(img.get('path'))

        if len(icons) == 1 and keep_orphans:
            print >> sys.stderr, "Category <%s> icons cannot be pruned: orphans would result." % name
        elif len(icons) == 0 and keep_orphans:
            print >> sys.stderr, "Category <%s> has no icons." % name
        else:
            for icon in icons:
                if icon.get('size') in prune_sizes:
                    remove_paths.append(icon.get('path'))

    if dry_run:
        print >> sys.stderr, "DRY RUN, no deletion."
        for path in remove_paths:
            print >> sys.stderr, " * Marked for deletion: " + path
        print >> sys.stderr, "DRY RUN, no deletion."
    else:
        for path in remove_paths:
            os.remove(path)
            print >> sys.stderr, " * Deleted: " + path

    print >> sys.stderr, "Category processing done."
    print >> sys.stderr, ""
    print >> sys.stderr, ""

def main():
    """ Parse arguments. """
    import docopt

    arguments = docopt.docopt(__doc__, version='Media deployment 0.1.0')

    strip_files = arguments.get('--strip-formats', '')
    if strip_files is None:
        strip_files = ''
    prune_dry_run = arguments.get('--prune-dry-run')
    keep_orphans = arguments.get('--keep-orphan-formats')

    collect_media_sizes = arguments.get('list') and arguments.get('sizes')

    source = arguments.get('<source_dir>')
    target = arguments.get('<target_dir>')

    target_path =  os.path.join( os.getcwd()
                               , target
                               )

    # TODO: copy_directory(source, target)

    prune_opts = {
        'strip_formats': strip_files.split(','),
        'media_sizes': collect_media_sizes,
        'keep_orphans': keep_orphans,
        'dry_run': prune_dry_run
    }

    # TODO: prune_category_media(target_path, **prune_opts)

    prune_concept_media(target_path, **prune_opts)

    # TODO: prune_concept_media


if __name__ == "__main__":
    sys.exit(main())
