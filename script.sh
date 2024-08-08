#!/bin/bash
rm -rf /tmp/github_code/
mkdir -p /tmp/github_code/
echo "Setting variables"

export REPO_URL="$1"
export GITHUB_TOKEN="$2"
export ACCOUNT_REQUEST_ID="$3"
export ACCOUNT_NAME="$4"
export BRANCH_NAME="$5"
export ACCOUNT_NEW_LINES="$6"

cd /tmp/github_code/

git clone https://${GITHUB_TOKEN}@${REPO_URL} .

git config user.email "accountvendingautomation@github.com"
git config user.name "Account Vending Automation"

git checkout -b ${BRANCH_NAME}
echo "Appending new account details to accounts-config.yaml"
echo "${ACCOUNT_NEW_LINES}" >> accounts-config.yaml
git add accounts-config.yaml
git commit -m "Appended new account details ${ACCOUNT_NAME}"

git push https://${GITHUB_TOKEN}@${REPO_URL} ${BRANCH_NAME}
gh pr create --title "${ACCOUNT_NAME}" --body "Account_Request_ID-${ACCOUNT_REQUEST_ID},Account_Name- ${ACCOUNT_NAME}" --base main --head "${BRANCH_NAME}"  2>&1 | tee /tmp/result
pull_request_url=`cat /tmp/result | grep https`

echo ${pull_request_url}
pull_request_number="${pull_request_url##*/}"
echo ${pull_request_number}
BASE_BRANCH="main"
PR_BRANCH=${BRANCH_NAME}
PR_NUMBER=${pull_request_number}

git fetch origin
git checkout $BASE_BRANCH
git pull origin $BASE_BRANCH

if git merge --no-commit --no-ff $PR_BRANCH; 
then
echo "No conflicts detected. Ready to merge.";     
git merge --abort; 
else     
echo "Conflicts detected. Please resolve conflicts before merging."; 
git merge --abort;    
echo "NO action needed"
fi

echo "Merging changes"
gh pr merge $PR_NUMBER --merge

if [[ "$?" == "0" ]]
then 
echo " Pull request merged"
else 
echo "Pull request merge failed"
exit 1
fi 
