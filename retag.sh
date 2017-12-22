version=${1?"Usage: $0 version_number"}
git tag -d ${version}
git push origin :refs/tags/${version}
git tag ${version}
git push --tags
