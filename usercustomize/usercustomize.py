""" Put site.USER_SITE in front of sys.path """

import sys
import site

sys.path.remove(site.USER_SITE)
sys.path.insert(0, site.USER_SITE)
