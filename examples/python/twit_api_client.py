#!/usr/bin/env python
# TWiT API Client
# A more comprehensive client for interacting with the TWiT.tv API

import requests
import json
import logging
import yaml
import os
import sys

class TwitApiClient:
    def __init__(self, app_id=None, app_key=None, base_url=None):
        # Try to load credentials from file if not provided
        if app_id is None or app_key is None:
            self.load_credentials_from_file()
        else:
            self.app_id = app_id
            self.app_key = app_key
            self.base_url = base_url or 'https://twit.tv/api/v1.0'
        
        # Setup logger
        self.logger = logging.getLogger('twit_api')
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)
        self.logger.setLevel(logging.INFO)

    # Get a list of all shows
    def get_shows(self, params=None):
        return self.make_request('/shows', params or {})

    # Get a specific show by ID
    def get_show(self, id, params=None):
        return self.make_request(f'/shows/{id}', params or {})

    # Get a list of all episodes
    def get_episodes(self, params=None):
        return self.make_request('/episodes', params or {})

    # Get a specific episode by ID
    def get_episode(self, id, params=None):
        return self.make_request(f'/episodes/{id}', params or {})

    # Get live streams information
    def get_streams(self, params=None):
        return self.make_request('/streams', params or {})

    # Get people information
    def get_people(self, params=None):
        return self.make_request('/people', params or {})

    # Load credentials from the shared credentials file
    def load_credentials_from_file(self):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        credentials_file = os.path.join(script_dir, '..', 'credentials.yml')
        
        if os.path.exists(credentials_file):
            try:
                with open(credentials_file, 'r') as file:
                    credentials = yaml.safe_load(file)
                self.app_id = credentials['twit_api']['app_id']
                self.app_key = credentials['twit_api']['app_key']
                self.base_url = credentials['twit_api'].get('base_url', 'https://twit.tv/api/v1.0')
            except Exception as e:
                self.logger.error(f"Error loading credentials: {e}")
                raise Exception(f"Failed to load credentials: {e}. Please make sure your credentials.yml file is properly formatted.")
        else:
            raise FileNotFoundError(f"Credentials file not found: {credentials_file}. Please copy credentials.yml.sample to credentials.yml and update with your actual credentials.")

    # Make an HTTP request to the TWiT API
    def make_request(self, endpoint, params=None):
        # Build URL with query parameters if any
        url = f"{self.base_url}{endpoint}"
        
        # Create headers
        headers = {
            'Accept': 'application/json',
            'app-id': self.app_id,
            'app-key': self.app_key
        }
        
        self.logger.debug(f"Making request to: {url}")
        
        try:
            response = requests.get(url, headers=headers, params=params)
            
            if response.status_code == 200:
                return response.json()
            elif response.status_code in (401, 403):
                self.logger.error("Authentication error: Check your app-id and app-key")
                return {"error": "Authentication failed", "code": response.status_code}
            elif response.status_code == 404:
                self.logger.error(f"Resource not found: {endpoint}")
                return {"error": "Resource not found", "code": response.status_code}
            elif response.status_code == 500:
                if 'usage limits are exceeded' in response.text:
                    self.logger.error("API usage limits exceeded")
                    return {"error": "API usage limits exceeded", "code": response.status_code}
                else:
                    self.logger.error(f"Server error: {response.text}")
                    return {"error": "Server error", "code": response.status_code}
            else:
                self.logger.error(f"Unexpected response: {response.status_code} - {response.text}")
                return {"error": "Unexpected response", "code": response.status_code, "body": response.text}
        except Exception as e:
            self.logger.error(f"Request failed: {e}")
            return {"error": str(e)}


# Example usage
if __name__ == "__main__":
    try:
        client = TwitApiClient()
        
        print("Testing connection to TWiT API...")
        
        # Test getting shows
        result = client.get_shows()
        
        if "error" in result:
            print(f"Error: {result['error']}")
        else:
            print("Connection successful!")
            print(f"Found {result['count']} shows")
            
            if 'shows' in result and result['shows']:
                print("\nFirst few shows:")
                for show in result['shows'][:3]:
                    print(f"- {show['label']} ({show['id']})")
            
            # Try to get a specific show (using the first show's ID if available)
            if 'shows' in result and result['shows']:
                first_show_id = result['shows'][0]['id']
                print(f"\nGetting details for show ID: {first_show_id}")
                
                show_details = client.get_show(first_show_id)
                if "error" not in show_details:
                    # For single show, the response has a 'shows' object, not an array
                    if 'shows' in show_details:
                        show = show_details['shows']
                        print(f"Show title: {show['label']}")
                        if 'description' in show:
                            print(f"Description: {show['description'][:100]}...")
            
            # Get streams information
            print("\nGetting live streams information...")
            streams = client.get_streams()
            if "error" not in streams and 'streams' in streams:
                print(f"Found {streams['count']} streams")
                for stream in streams['streams'][:2]:
                    print(f"- {stream['label']} ({stream['streamType']})")
    except Exception as e:
        print(f"Error: {e}")
