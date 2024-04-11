#!/bin/sh

# This is a local release script and should be replaced with a pipeline thing.

checkActiveBranch() {
  if [ "$(git rev-parse --abbrev-ref HEAD)" != "$1" ]; then
    echo "Error: The current branch is not $1."
    exit 1
  fi
}

checkUncommittedChanges() {
  if [ -n "$(git status --porcelain)" ]; then
    echo "Error: There are uncommitted changes in the repository."
    exit 1
  fi
}

prepareEnvironment() {
  git fetch origin
}

checkLastCommit() {
  last_commit_message=$(git log -1 --pretty=format:%s)
  if [ "$last_commit_message" = "[RELEASE] - bump version" ]; then
    echo "Warning: Nothing to release!!!"
    exit 1
  fi
}

checkDifferences() {
  if ! git diff --quiet origin/"$1" "$1"; then
    echo "Error: The branches origin/$1 and $1 have differences."
    exit 1
  fi
}

unSnapshotVersion() {
  sed -i "s/\(version\s*=\s*[0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/" gradle.properties
}

unSnapshotCatalog() {
  sed -i "s/\($1\s*=\s*\"[0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1\"/" lulz.versions.toml
}

stageFiles() {
  for file in "$@"; do
    if git diff --exit-code --quiet -- "$file"; then
      echo "No changes in $file"
    else
      git add "$file"
      echo "Changes in $file staged for commit"
    fi
  done
}

commitChange() {
  stageFiles gradle.properties lulz.versions.toml
  git commit -m "[RELEASE] - $1"
  git push --porcelain origin develop
}

currentVersion() {
  awk -F '=' '/version\s*=\s*[0-9.]*/ {gsub(/^ +| +$/,"",$2); print $2}' gradle.properties
}

addReleaseTag() {
  gitTag="v$(currentVersion)"
  git tag -a "$gitTag" -m "Release version $gitTag"
  git push --porcelain origin "$gitTag"
}

mergeIntoMaster() {
  git checkout master
  git merge develop -m "release version '$(currentVersion)'" --ff-only
  git push --porcelain origin master
  git checkout develop
  git rebase origin/master
}

snapshotVersion() {
  new_version="$(currentVersion | awk -F '.' '{print $1 "." $2+1 "." $3}')"
  sed -i "s/\(version\s*=\s*\)[0-9.]*/\1$new_version-SNAPSHOT/" gradle.properties
}

publishMaster() {
  git checkout master
  ./gradlew clean publish
}

# check and prepare for release
checkActiveBranch develop
checkUncommittedChanges
prepareEnvironment
checkLastCommit
checkDifferences master
checkDifferences develop

# un-snapshot version for release
unSnapshotCatalog lulzPluginCore
unSnapshotVersion

# release changes and prepare for next release
commitChange "release version: $(currentVersion)"
addReleaseTag
mergeIntoMaster
snapshotVersion
commitChange 'bump version'

# disable
# publishMaster
