

LDOC_OUTPUT_PATH = "assets\\docs\\doc_output\\"

LDOC_INSTALL_PATH = "D:\\_PROGRAMMING\\LUA\\_SCRIPTS\\nm_LDoc\\LDoc\\ldoc.lua"


CONFIG_FNAME = "config.ld"

import os



assert os.path.exists(CONFIG_FNAME), "Not in correct directory: Run make_docs from the root directory of this project!"


def contains_col(line):
    i = line.find("#")
    if i > -1:
        return ":" in line[:i]

def invert_color(col):
    pass


'''
making changes to the css

with open(f"{LDOC_OUTPUT_PATH}ldoc.css") as f:
    lines = f.readlines()
    for i, line in enumerate(lines):
        if contains_col(line):
            pass
            ## TODO: Invert the CSS colors here or something.
            ## Play around with it, have fun! :)
'''


os.system(f"lua {LDOC_INSTALL_PATH} .")

