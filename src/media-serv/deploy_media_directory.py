"""
Media directory deployment for PhoneGap
---------------------------------------

This tool is intended to manage deployment of media files to the
PhoneGap source directories for the purpose of:

  * Removing original-sized media files that aren't in use in the
    application

TODO: warn when the directory only contains an original size, and no
compressed versions.

TODO: list sizes

TODO: this step should also be used for deploying the standalone version,
      so media needs to be stored in another location.

Usage:
  deploy_media_directory.py list sizes <target_dir>
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

    shutil.copytree(src, targ, symlinks=True)

    print >> sys.stderr, " * Copied."

def prune_category_media(target, **prune_opts):
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


    # TODO: actually delete the things

    if dry_run:
        print >> sys.stderr, "DRY RUN, no deletion."
        for path in remove_paths:
            print >> sys.stderr, " * Marked for deletion: " + path
        print >> sys.stderr, "DRY RUN, no deletion."
    else:
        for path in remove_paths:
            os.remove(path)
            print >> sys.stderr, " * Deleted: " + path


def main():
    """ Parse arguments. """
    import docopt

    arguments = docopt.docopt(__doc__, version='Media deployment 0.1.0')

    strip_files = arguments.get('--strip-formats')
    prune_dry_run = arguments.get('--prune-dry-run')
    keep_orphans = arguments.get('--keep-orphan-formats')

    source = arguments.get('<source_dir>')
    target = arguments.get('<target_dir>')

    target_path =  os.path.join( os.getcwd()
                               , target
                               )

    # TODO: copy_directory(source, target)

    prune_opts = {
        'strip_formats': strip_files.split(','),
        'keep_orphans': keep_orphans,
        'dry_run': prune_dry_run
    }

    prune_category_media(target_path, **prune_opts)

    # TODO: prune_concept_media


if __name__ == "__main__":
    sys.exit(main())
