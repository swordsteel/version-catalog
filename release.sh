#!/bin/sh

setup() {
    git fetch
    git checkout develop
}

check_last_commit() {
    last_commit_message=$(git log -1 --pretty=format:%s)
    if [ "$last_commit_message" = "[RELEASE] - bump version" ]; then
        echo "Nothing to release!!!"
        exit 1
    fi
}

un_snapshot_catalog() {
    sed -i "s/^\($1\s*=\s*\"[0-9.]*\)-SNAPSHOT.*$/\1\"/" lulz.versions.toml
}

un_snapshot_version() {
    sed -i 's/\(version\s*=\s*[0-9.]*\)-SNAPSHOT/\1/' gradle.properties
}

get_current_version() {
    awk -F '=' '/version\s*=\s*[0-9.]*/ {gsub(/^ +| +$/,"",$2); print $2}' gradle.properties
}

stage_files() {
    for file in "$@"; do
        if git diff --exit-code --quiet -- "$file"; then
            echo "No changes in $file"
        else
            git add "$file"
            echo "Changes in $file staged for commit"
        fi
    done
}

commit_change() {
    stage_files gradle.properties lulz.versions.toml
    git commit -m "[RELEASE] - $1"
    git push --porcelain origin develop
}

add_tag() {
    gitTag="v$(get_current_version)"
    git tag -a "$gitTag" -m "release"
    git push --porcelain origin "$gitTag"
}

merge_into_master() {
    git checkout master
    git merge develop -m "release version '$(get_current_version)'" --ff-only
    git push --porcelain origin master
    git checkout develop
    git rebase origin/master
}

snapshot_version() {
    new_version="$(get_current_version | awk -F '.' '{print $1 "." $2+1 "." $3}')"
    sed -i "s/\(version\s*=\s*\)[0-9.]*/\1$new_version-SNAPSHOT/" gradle.properties
}

# gitCmd4Azure
setup

# checkLastCommit
check_last_commit

# unSnapshotCatalogVersion
un_snapshot_catalog lulzPluginCore
un_snapshot_catalog lulzPluginCommon
un_snapshot_catalog lulzLibraryTestUtility

# unSnapshotVersion
un_snapshot_version

# commitVersionChange
commit_change "release version: $(get_current_version)"

## preTagCommit
add_tag

## something
merge_into_master

## preTagCommit
snapshot_version

## commitVersionChange
commit_change 'bump version'
