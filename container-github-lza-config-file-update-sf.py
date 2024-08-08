import json
import boto3
import time
import os
import subprocess

# Initialize client
secrets_client = boto3.client('secretsmanager')

# Fetch environment variables
repo_url = os.getenv('GITHUB_REPO_URL')

# Fetch the PAT from AWS Secrets Manager
def get_github_token(secret_name):
    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        secret = response['SecretString']
        return secret
    except Exception as e:
        raise e

def lambda_handler(event, context):
    try:
        dynamodb_record = event['checkCodePipelineStatusResult']['dynamodbRecord']
        github_token = get_github_token(os.getenv('GITHUB_TOKEN_SECRET_NAME'))
        request_id = dynamodb_record['NewImage']['request_id']['S']
        account_name = dynamodb_record['NewImage']['account_name']['S']
        branch_name = f"prc-{account_name}-{request_id}-{int(time.time())}"
  
        account_new_lines = f"""  - name: {dynamodb_record['NewImage']['account_name']['S']}
    description: >-
      {dynamodb_record['NewImage']['account_name']['S']}
    email: {dynamodb_record['NewImage']['account_email']['S']}
    organizationalUnit: {dynamodb_record['NewImage']['organizational_unit']['S']}"""
        
        command = f"./script.sh '{repo_url}' '{github_token}' '{request_id}' '{account_name}' {branch_name} '{account_new_lines}'"
        process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = process.communicate()
        if process.returncode != 0:
            print(f"Error executing script: {stderr.decode('utf-8')}")
            raise Exception('Error occured while merging the account details to main branch on GitHub.')
        else:
            return {
                "branchName": branch_name,
                "branchMergeStatus": 'success',
                "dynamodbRecord": dynamodb_record
            }
    except Exception as e:
        raise e
