#!/bin/bash

if [ $1 == "staging" ]; then
  branch="master"
fi

cd /srv/$1
git pull --rebase origin $branch
git add .
git commit -m "Auto-commit `date`"
git push origin $branch
