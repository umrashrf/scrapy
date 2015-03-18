#!/bin/bash

# startover
git checkout master # in future comment this so you can checkout your desired commit
git branch -D selectors selector-code utils-code tests-code selectors-separation

# split scrapy/selector dir to selector-code branch
git checkout -b selector-code
git filter-branch -f --prune-empty \
    --subdirectory-filter scrapy/selector -- selector-code
# mv files to selectors/ dir without new commit
git filter-branch -f \
    --index-filter '
        git ls-files -s \
        | sed "s-\t-&selectors/-" \
        | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info \
        && mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE'

# now we need to split utils
git checkout master

# split scrapy/utils dir to utils-code branch
git checkout -b utils-code
git filter-branch -f --prune-empty \
    --subdirectory-filter scrapy/utils -- utils-code
# only keep required utils files
git filter-branch -f \
    --prune-empty \
    --index-filter '
        git ls-tree -z -r --name-only --full-tree $GIT_COMMIT \
        | grep -z -v "^__init__.py$" \
        | grep -z -v "^decorator.py$" \
        | grep -z -v "^misc.py$" \
        | grep -z -v "^python.py$" \
        | xargs -0 -r git rm --cached -r
    ' \
    -- \
    utils-code
# mv files to selectors/utils/ dir without new commit
git filter-branch -f \
    --index-filter '
        git ls-files -s \
        | sed "s-\t-&selectors/utils/-" \
        | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info \
        && mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE'

# now we need to split tests
git checkout master

# split tests dir to tests-code branch
git checkout -b tests-code
git filter-branch -f --prune-empty \
    --subdirectory-filter tests -- tests-code
# only keep required tests files
git filter-branch -f \
    --prune-empty \
    --index-filter '
        git ls-tree -z -r --name-only --full-tree $GIT_COMMIT \
        | grep -z -v "^__init__.py$" \
        | grep -z -v "^test_selector.py$" \
        | grep -z -v "^test_selector_csstranslator.py$" \
        | xargs -0 -r git rm --cached -r
    ' \
    -- \
    tests-code
# mv files to tests/ dir without new commit
git filter-branch -f \
    --index-filter '
        git ls-files -s \
        | sed "s-\t-&tests/-" \
        | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info \
        && mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE'

# centralized branch for all selectors code
git checkout --orphan selectors
git rm -r -f .

# merge and rebase separate branches
git merge selector-code
git rebase utils-code
git rebase tests-code

# release branches
git branch -D selector-code utils-code tests-code

# now we can apply selectors patches
for f in $(ls patches/selectors/2015-03-18/); do
    git am < patches/selectors/2015-03-18/$f;
done

# now we can remove selectors from scrapy
git checkout master
git checkout -b selectors-separation
# apply scrapy patches
for f in $(ls patches/scrapy/2015-03-18/); do
    git am < patches/scrapy/2015-03-18/$f;
done

# references
# http://git-scm.com/docs/git-filter-branch
# http://git-scm.com/docs/git-ls-tree
# examples
# https://stackoverflow.com/questions/359424/detach-subdirectory-into-separate-git-repository
# https://stackoverflow.com/questions/359424/detach-subdirectory-into-separate-git-repository
# https://github.com/apenwarr/git-subtree/blob/master/git-subtree.txt
# https://stackoverflow.com/questions/6403715/git-how-to-split-off-library-from-project-filter-branch-subtree?rq=1
# https://stackoverflow.com/questions/5998987/splitting-a-set-of-files-within-a-git-repo-into-their-own-repository-preserving
# https://www.kernel.org/pub/software/scm/git/docs/git-filter-branch.html
# http://stackoverflow.com/a/7396584
# https://stackoverflow.com/questions/8131135/git-how-to-diff-two-different-files-in-different-branches
