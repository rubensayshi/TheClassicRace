#!/bin/bash

# don't need to run the packager for pull requests
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  echo "Not packaging pull request."
  exit 1
fi
# only want to package master and tags
if [ "$TRAVIS_BRANCH" != "master" -a -z "$TRAVIS_TAG" ]; then
  echo "Not packaging \"${TRAVIS_BRANCH}\"."
  exit 1
fi
# don't need to run the packager if there is a tag pending
if [ -z "$TRAVIS_TAG" ]; then
  TRAVIS_TAG=$( git -C "$TRAVIS_BUILD_DIR" tag --points-at )
  if [ -n "$TRAVIS_TAG" ]; then
    echo "Found future tag \"${TRAVIS_TAG}\", not packaging."
    exit 1
  fi
fi

# all good!
exit 0
