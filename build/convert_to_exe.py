
import time

import stat
import shutil
import common
import os
import subprocess
import configparser


from common import SEP, BUILD_OUTPUT_FOLDER, FILES_BUILD_OUTPUT_ZIPNAME, FILES_BUILD_OUTPUT_ZIP_EXTEN, LOVE_APPIMAGE_NAME, APPIMAGETOOL_PATH
from common import *


def copy_over_libs():
    dll_path = common.get_lib_path()
    shutil.copytree(dll_path, common.BUILD_OUTPUT_FOLDER, dirs_exist_ok=True)




def fuse_files(file_a, file_b, file_out):
    """
    fuses 2 files together
    (just concats their binary data)
    """
    with open(file_a, "rb") as f:
        a_data = f.read()

    with open(file_b, "rb") as zp:
        b_data = zp.read()

    with open(file_out, "wb+") as out:
        out.write(a_data + b_data)




opj = os.path.join


def grant_perms(file_path, perms):
    current_permissions = stat.S_IMODE(os.lstat(file_path).st_mode)
    new_permissions = current_permissions
    for perm in perms:
        new_permissions |= perm
    os.chmod(file_path, new_permissions)


def grant_exe_permissions(file_path):
    '''
    sets chmod +x to a file
    '''
    grant_perms(file_path, [stat.S_IXUSR, stat.S_IXGRP, stat.S_IXOTH])



def grant_write_permissions(file_path):
    'grants write access to a file'
    grant_perms(file_path, [stat.S_IWUSR, stat.S_IWGRP, stat.S_IWOTH])



def fuse_exe_linux():
    # extract appimage
    grant_exe_permissions(LOVE_APPIMAGE_PATH)

    os.chdir(BUILD_OUTPUT_FOLDER) # we want to extract into build_output
    output = subprocess.check_output([LOVE_APPIMAGE_NAME, "--appimage-extract"])
    os.chdir("../") # move back to root
    
    # prepare paths to fuse
    zip_path = opj(BUILD_OUTPUT_FOLDER, FILES_BUILD_OUTPUT_ZIPNAME) + FILES_BUILD_OUTPUT_ZIP_EXTEN
    squashfs_love_path = opj(SQUASHFS_BIN_PATH, SQUASHFS_LOVE_FNAME)
    executable_path = opj(SQUASHFS_BIN_PATH, SQUASHFS_EXE_FNAME)

    # create executable
    fuse_files(squashfs_love_path, zip_path, executable_path)

    # remove love exe 
    os.remove(squashfs_love_path)
    # remove zip
    os.remove(zip_path)

    # set chmod +x flag
    grant_exe_permissions(executable_path)


    # change icon
    # TODO, DO LATER. its not very hard

    # create launch script








def fuse_exe_windows():
    love_binary = None
    zip_binary = None

    love_path = common.get_love_path() + SEP + "love.exe"
    zip_path = BUILD_OUTPUT_FOLDER + SEP + FILES_BUILD_OUTPUT_ZIPNAME + FILES_BUILD_OUTPUT_ZIP_EXTEN
    exe_path = BUILD_OUTPUT_FOLDER + SEP + "umg.exe"

    # concat love exe with zipped file contents
    # (dont ask me why this works, it just does)
    fuse_files(love_path, zip_path, exe_path)



def copy_over_love():
    love_path = common.get_love_path()
    shutil.copytree(love_path, common.BUILD_OUTPUT_FOLDER, dirs_exist_ok=True)


def run():
    # copy shared object libs over
    copy_over_libs()

    # copy over love dlls, and love binary
    copy_over_love()

    if common.is_windows():
        fuse_exe_windows()
    elif common.is_linux():
        fuse_exe_linux()

