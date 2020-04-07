#! /bin/sh

# Convert all git submodules to git subtrees
#
# Copyright (c) 2016 Pavel Roskin
# Based on earlier work by Alexander Mikhailian
# http://mikhailian.mova.org/node/233


set -e

if ! test -f .gitmodules; then
  echo "File .gitmodules not found in current directory" >&2
  exit 1
fi

SUBMODULES=`git config -f .gitmodules --list | sed -n 's/submodule\.\(.*\)\.path=.*/\1/p'`

if test -z "$SUBMODULES"; then
  echo "No submodules have been found" >&2
  exit 1
fi

echo "Submodules to be converted to subtrees:"
for sm in $SUBMODULES; do
  echo "  $sm"
done
echo "Press Enter to continue, Ctrl-C to cancel"
read

for sm in $SUBMODULES; do
  smpath=`git config -f .gitmodules --get "submodule.$sm.path" || :`
  if test -z "$smpath"; then
    echo "Cannot find path for submodule $sm" >&2
    exit 1
  fi

  smurl=`git config -f .gitmodules --get "submodule.$sm.url" || :`
  if test -z "$smurl"; then
    echo "Cannot find URL for submodule $sm" >&2
    exit 1
  fi

  smbranch=`git config -f .gitmodules --get "submodule.$sm.branch" || :`
  if test -z "$smbranch"; then
    smbranch="master"
  fi

  # deinit the submodule
  if ! git submodule deinit --force $smpath; then
    echo "Failed to deinit $smpath" >&2
    exit 1
  fi

  # remove the submodule from .gitmodules
  if ! git config -f .gitmodules --remove-section "submodule.$sm"; then
    echo "Failed to remove $sm from .gitmodules" >&2
    exit 1
  fi

  # update .gitmodules, remove if empty
  if test -s .gitmodules; then
    git add .gitmodules
  else
    rm -f .gitmodules
    git rm .gitmodules
  fi

  # remove the module from git
  if ! git rm -r --cached $smpath; then
    echo "Failed remove $smpath from git" >&2
    exit 1
  fi

  # remove the module from the filesystem
  if ! rm -rf $smpath; then
    echo "Failed remove $smpath from filesystem" >&2
    exit 1
  fi

  # commit the change
  if ! git commit -m "Remove $smpath submodule"; then
    echo "Cannot commit removal of $smpath" >&2
    exit 1
  fi

  # add the remote
  if ! git remote add --fetch -m $smbranch $sm $smurl; then
    echo "Cannot add remote $sm" >&2
    exit 1
  fi

  # add the subtree
  if ! git subtree add --prefix $smpath $sm $smbranch; then
    echo "Cannot add subtree $sm" >&2
    exit 1
  fi

  # fetch the files
  if ! git fetch $smurl $smbranch; then
    echo "Cannot fetch $sm" >&2
    exit 1
  fi

done
exit 0