# Git Release Guide

## Initialize Git Flow (first time only)

git config gitflow.prefix.versiontag v && git flow init -d

## Release Process

1. Update develop branch:
   
   git checkout develop && git pull origin develop
   
2. Start release:
   
   git flow release start v<version>
   
3. Update version and commit:
   
   npm version <version> --no-git-tag-version
   git add . && git commit -m "chore: bump version to v<version>"
   
4. Finish release:
   
   git flow release finish v<version>
   
5. Push all changes:
   
   git push origin master develop --tags