#! /bin/bash
# Copyright (C) 2016 Robin Krahl <robin.krahl@wikipedia.de>
#
# This script bundles LrMediaWiki and uploads the bundled plugin to GitHub.
# You have to pass the version number (e. g. 1.0). The script will upload the
# bundled plugin to the release with the tag v<VERSION>, e. g. v1.0. This
# script requires that the environment variable GITHUB_TOKEN is set to a valid
# token for the repository to release a version for.
#
# Dependencies:
#  - github-release: https://github.com/aktau/github-release

if [[ "$#" -ne 1 ]]
then
  echo "USAGE: ./release.sh <version>"
  echo "  version: the semantic version name, e. g. 1.0"

  if [[ "$#" -gt 1 ]]
  then
    echo "1 argument required, $# given" >&2
    exit 1
  else
    exit 0
  fi
fi

# user input
VERSION="$1"
# github-release settings
GITHUB_USER="Hasenlaeufer"
GITHUB_REPO="LrMediaWiki"
# paths and file names
TMPDIR=`mktemp -d`
LRDEVPLUGIN="mediawiki.lrdevplugin"
LRPLUGIN="mediawiki.lrplugin"
TAG="v$1"
ARCHIVE_BASE_NAME="lrmediawiki-$VERSION"
ARCHIVE_NAME_ZIP="$ARCHIVE_BASE_NAME.zip"
ARCHIVE_NAME_TAR_GZ="$ARCHIVE_BASE_NAME.tar.gz"
CHECKSUM_NAME="checksums.md5"

# copy required files to the temporary directory
cp -r "$LRDEVPLUGIN" "$TMPDIR/$LRPLUGIN"
cp *.md *.txt "$TMPDIR/$LRPLUGIN"

cd $TMPDIR

# create archives
zip -r "$ARCHIVE_NAME_ZIP" "$LRPLUGIN"
tar -czf "$ARCHIVE_NAME_TAR_GZ" "$LRPLUGIN"
# create checksums
md5sum "$ARCHIVE_NAME_ZIP" "$ARCHIVE_NAME_TAR_GZ" > "$CHECKSUM_NAME"

# upload
for FILE in "$ARCHIVE_NAME_ZIP" "$ARCHIVE_NAME_TAR_GZ" "$CHECKSUM_NAME"
do
  github-release upload --tag "$TAG" --name "$FILE" --file "$FILE" --user "$GITHUB_USER" --repo "$GITHUB_REPO"
done

rm -r "$TMPDIR"
echo "DONE"
