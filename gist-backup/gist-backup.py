#! /usr/bin/env python

"""
Clone or update all GitHub gists of a user
Specify GitHub username in the GITHUB_USER environment variable
"""

from __future__ import absolute_import, print_function
import base64
import codecs
import getpass
import json
import os
import subprocess
import sys

try:
    import urllib.request as urllib2
except ImportError:
    import urllib2


def process_gist(gist, outfile):
    """Process one gist"""
    # Use name of the largest file in the gist for directory name
    gist_id = gist['id']
    if len(gist['files']) > 0:
        files = sorted(gist['files'].items(),
                       key=(lambda t: t[1]['size']),
                       reverse=True)
        gistname = files[0][0]
    else:
        gistname = gist_id

    # Remove extension if any
    gistname, _ = os.path.splitext(gistname)

    # Append underscore if the name is used by a file
    while os.path.exists(gistname) and not os.path.isdir(gistname):
        gistname += '_'

    # Clone or update repositories
    gist_url = 'https://gist.github.com/' + gist_id + '.git'
    if os.path.isdir(gistname):
        subprocess.call(['git', 'pull'], cwd=gistname)
    else:
        subprocess.call(['git', 'clone', gist_url, gistname])

    # Write contents.txt
    description = gist['description']
    if not description:
        description = '<no description>'
    description.strip()
    print(gistname + '\n' + gist_url + '\n' + description + '\n',
          file=outfile)


def get_json(url, auth_code):
    """Request and parse JSON from URL, exit on error"""

    utf8_decoder = codecs.getreader("utf-8")
    try:
        headers = {'Accept': 'application/vnd.github.v3+json'}
        req = urllib2.Request(url, None, headers)
        req.add_header("Authorization", "Basic " + auth_code)
        resp = urllib2.urlopen(req)
        return json.load(utf8_decoder(resp))
    except urllib2.HTTPError as exc:
        print("Cannot open:", url)
        print(exc.code, exc.reason)
        print(exc.read())
        sys.exit(1)


def main():
    """Main function"""

    perpage = 30

    if 'GITHUB_USER' in os.environ:
        user = os.environ['GITHUB_USER']
    else:
        user = os.environ['USER']

    password = getpass.getpass('GitHub password for user {0}:'.format(user))
    auth_data = (user + ':' + password).encode('utf-8')
    auth_code = base64.b64encode(auth_data).decode('utf-8')

    base_url = 'https://api.github.com/users/' + user
    user_info = get_json(base_url, auth_code)
    gistcount = user_info['public_gists']
    pages = (gistcount + perpage - 1) // perpage
    print("User: {0}, gists: {1}, pages: {2}".format(user, gistcount, pages))

    with open('./contents.txt', 'w') as outfile:
        for page in range(pages):
            url = base_url + '/gists?page=' + \
                str(page + 1) + '&per_page=' + str(perpage)
            gists = get_json(url, auth_code)

            for gist in gists:
                process_gist(gist, outfile)


if __name__ == '__main__':
    main()
