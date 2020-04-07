'''Quickly check python files for broken syntax'''

import sys

for filename in sys.argv[1:]:
    with open(filename, 'r') as fd:
        compile(fd.read(), filename, 'exec')
