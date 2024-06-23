
import zip_source
import convert_to_exe
import common

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('os', help='specify the os')
parser.add_argument('arch', choices=common.VALID_ARCHES, help='Specify 32 or 64 bit arch')


args = parser.parse_args()


common.set_build_target(args.os, args.arch)

# zip up the source code
zip_source.run()

# convert to executable program
convert_to_exe.run()

