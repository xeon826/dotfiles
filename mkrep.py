#!/usr/bin/env python3
import os
import requests
import subprocess

# Replace 'your_access_token' with your personal access token
GITHUB_ACCESS_TOKEN = os.getenv('GITHUB_PERSONAL_ACCESS_TOKEN')
GITHUB_API_URL = 'https://api.github.com'

# Get the current directory name
current_directory = os.path.basename(os.getcwd())

def init_and_set_remote(repo_url):
    """Initialize git repository and set remote origin"""
    try:
        subprocess.run(['git', 'init'], check=True)
        subprocess.run(['git', 'remote', 'add', 'origin', repo_url], check=True)
        print(f'Initialized git repository and set remote to: {repo_url}')
        return True
    except subprocess.CalledProcessError as e:
        print(f'Failed to initialize git repository: {str(e)}')
        return False

def create_github_repo(repo_name):
   # Define headers with authorization
   headers = {
       'Authorization': f'token {GITHUB_ACCESS_TOKEN}',
       'Accept': 'application/vnd.github.v3+json'
   }

   # Define the repository data
   data = {
       'name': repo_name,
       'private': True  # Change to True if you want to make it private
   }

   # Send POST request to create the repository
   response = requests.post(f'{GITHUB_API_URL}/user/repos', json=data, headers=headers)

   # Check the response status
   if response.status_code == 201:
       print(f'Successfully created repository: {repo_name}')
       repo_data = response.json()
       repo_url = repo_data['clone_url']
       init_and_set_remote(repo_url)
   else:
       print(f'Failed to create repository: {response.json()}')

if __name__ == '__main__':
   # Create the repository using the current directory name
   create_github_repo(current_directory)
