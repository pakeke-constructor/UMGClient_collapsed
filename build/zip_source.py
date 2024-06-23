
import shutil
import os

import common


INVALID_EXTENSIONS = [
    ".md", ".git", ".github"
]



def is_bad_extension(fname):
    _, exten = os.path.splitext(fname)
    for invalid_exten in INVALID_EXTENSIONS:
        if exten == invalid_exten:
            return True
    return False


assert is_bad_extension("hello.md")



ROOT = "."



from common import *


def should_ignore(dir):
    if BUILD_OUTPUT_FOLDER in dir:
        return True
        
    for ignore in IGNORE_FOLDERS:
        if ignore in dir:
            return True
    return False





def ignore(dir, files):
    '''
    returns a list of files that should be ignored.
    '''
    to_ignore = [] # a list of files to be ignored

    if should_ignore(dir):
        return files # ignore all files

    for file in files:
        if is_bad_extension(file):
            to_ignore.append(file)
    return to_ignore



opjoin = os.path.join


def run():
    # copy src files over
    dest = FILES_BUILD_OUTPUT_FOLDER
    shutil.copytree(ROOT, dest, ignore=ignore)
    # TODO: Convert all lua to bytecode here.

    # create the zipped src code (aka .love file)
    # this will be created inside the FILES_BUILD_OUTPUT_FOLDER
    exten = FILES_BUILD_OUTPUT_ZIP_EXTEN.replace(".", "")
    shutil.make_archive(FILES_BUILD_OUTPUT_ZIPNAME, exten, dest)
    # move zip into regular build folder
    fname = FILES_BUILD_OUTPUT_ZIPNAME + FILES_BUILD_OUTPUT_ZIP_EXTEN
    shutil.move(fname, BUILD_OUTPUT_FOLDER)

    # delete source files, since we have already zipped them
    shutil.rmtree(dest)


