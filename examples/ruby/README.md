# TWiT API Ruby Examples

This directory contains Ruby scripts for testing and interacting with the TWiT.tv API.

## Prerequisites

- Ruby (2.5 or higher recommended)
- API credentials from TWiT.tv's 3Scale service (app-id and app-key)

## Setting Up Credentials

1. Copy the sample credentials file to create your own:
   ```bash
   cp ../credentials.yml.sample ../credentials.yml
   ```

2. Edit `../credentials.yml` and replace the placeholder values with your actual TWiT API credentials:
   ```yaml
   twit_api:
     app_id: YOUR_APP_ID
     app_key: YOUR_APP_KEY
     base_url: https://twit.tv/api/v1.0
   ```

## Files

- `test_connection.rb`: A simple diagnostic script to test your connection to the TWiT API
- `twit_api_client.rb`: A comprehensive client library for interacting with all TWiT API endpoints

## How to Use

### Basic Connection Test

The test connection script is a simple diagnostic tool that verifies:
- Your credentials are working
- The API is accessible
- Basic response parsing works correctly

Run the script:

```bash
ruby test_connection.rb
```

You should see output confirming a successful connection and listing the first few shows.

### Using the TWiT API Client

The TWiT API client is a full-featured library that provides access to all API endpoints with proper error handling and response parsing. It can be run as a standalone script to test all endpoints:

```bash
ruby twit_api_client.rb
```

This will demonstrate connecting to the API and accessing multiple endpoints (shows, episodes, streams, etc.).

### Using the Client in Your Own Scripts

```ruby
require_relative 'twit_api_client'

# The client will automatically load credentials from ../credentials.yml
client = TwitApiClient.new
shows = client.get_shows
puts "Found #{shows['count']} shows"

# Get a specific show
show = client.get_show('1635')  # This Week in Tech
puts "Show title: #{show['label']}"

# Get episodes
episodes = client.get_episodes
puts "Found #{episodes['count']} episodes"

# Get streams
streams = client.get_streams
puts "Found #{streams['count']} streams"

# Alternatively, you can provide credentials directly
client = TwitApiClient.new('your_app_id', 'your_app_key')
```

## API Response Structure

The TWiT API returns JSON responses with the following structure:

- Shows endpoint (`/shows`):
  ```json
  {
    "count": 71,
    "shows": [
      {
        "id": "65161",
        "label": "All TWiT.tv Shows",
        "self": "https://twit.tv/api/v1.0/shows/65161",
        "description": "...",
        ...
      },
      ...
    ]
  }
  ```

- Similar structure for other endpoints (`/episodes`, `/streams`, `/people`)

## Error Handling

The client includes robust error handling for:
- Authentication errors (401, 403)
- Resource not found errors (404)
- Server errors (500)
- API usage limits exceeded
- Network connectivity issues

## API Authentication

API Authentication is provided by 3Scale at https://twit-tv.3scale.net. You'll need to register for an account and apply for access to the TWiT.tv API via an Application plan.

## API Endpoints

The client supports the following endpoints:

- `/shows`: Get information about TWiT.tv shows
- `/shows/{id}`: Get details about a specific show
- `/episodes`: Get episode information
- `/episodes/{id}`: Get details about a specific episode
- `/streams`: Get information about live streams
- `/people`: Get information about people at TWiT.tv

For more details, refer to the full API documentation.
