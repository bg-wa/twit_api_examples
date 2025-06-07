#!/usr/bin/env python
# TWiT API Connection Test Script
# This script tests the connection to the TWiT.tv API

import requests
import json
import yaml
import os
import sys
from pathlib import Path

# Load credentials from shared credentials file
script_dir = os.path.dirname(os.path.abspath(__file__))
credentials_file = os.path.join(script_dir, '..', 'credentials.yml')

if os.path.exists(credentials_file):
    try:
        print(f"Loading credentials from: {credentials_file}")
        with open(credentials_file, 'r') as file:
            credentials_content = file.read()
            print(f"Credentials file content (first line): {credentials_content.splitlines()[0].strip()}")

        with open(credentials_file, 'r') as file:
            credentials = yaml.safe_load(file)
        print(f"Parsed YAML structure: {credentials}")

        APP_ID = credentials['twit_api']['app_id']
        APP_KEY = credentials['twit_api']['app_key']
        API_BASE_URL = credentials['twit_api'].get('base_url', 'https://twit.tv/api/v1.0')

        print(f"Using APP_ID: {APP_ID}")
        print(f"Using APP_KEY: {'*' * len(APP_KEY)}") # Mask the actual key for security
    except Exception as e:
        print(f"Error loading credentials: {e}")
        print("Please make sure your credentials.yml file is properly formatted.")
        print("You can copy credentials.yml.sample to credentials.yml and update with your actual credentials.")
        sys.exit(1)
else:
    print(f"Credentials file not found: {credentials_file}")
    print("Please copy credentials.yml.sample to credentials.yml and update with your actual credentials.")
    sys.exit(1)

# Test endpoint - shows is a simple endpoint to test
endpoint = '/shows'
url = f"{API_BASE_URL}{endpoint}"

# Create headers
headers = {
    'Accept': 'application/json',
    'app-id': APP_ID,
    'app-key': APP_KEY
}

print("\nTesting connection to TWiT API...")
print(f"Endpoint: {url}")
print(f"Headers: app-id={APP_ID}, app-key={APP_KEY}")

try:
    # Send request
    response = requests.get(url, headers=headers)

    # Parse and display response
    if response.status_code == 200:
        print(f"Connection successful! (HTTP {response.status_code})")

        # Parse JSON response
        result = response.json()

        # Display some basic info about the response
        if 'count' in result:
            print(f"Found {result['count']} shows")

        # Display first few items if available
        if 'shows' in result and result['shows']:
            print("\nFirst few shows:")
            for show in result['shows'][:3]:
                print(f"- {show['label']} ({show['id']})")
    else:
        print(f"Connection failed with HTTP status: {response.status_code}")
        print(f"Response body: {response.text}")

        # Check for specific error messages
        if response.status_code == 500 and 'usage limits are exceeded' in response.text:
            print("Error: API usage limits exceeded. Check your plan limits.")
        elif response.status_code in (401, 403):
            print("Error: Authentication failed. Check your APP_ID and APP_KEY.")
except Exception as e:
    print(f"Error connecting to API: {e}")
    import traceback
    print(traceback.format_exc())
