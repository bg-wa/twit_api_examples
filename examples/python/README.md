# TWiT API Python Examples

This directory contains Python scripts for testing and interacting with the TWiT.tv API.

## Prerequisites

- Python (3.6 or higher recommended)
- API credentials from TWiT.tv's 3Scale service (app-id and app-key)
- Required Python packages: `requests`, `pyyaml`

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

- `test_connection.py`: A simple script to test your connection to the TWiT API
- `twit_api_client.py`: A more comprehensive client for interacting with multiple TWiT API endpoints

## How to Use

### Basic Connection Test

Run the script:

```bash
python test_connection.py
```

### Using the TWiT API Client

Run the client script:

```bash
python twit_api_client.py
```

### Using the Client in Your Own Scripts

```python
from twit_api_client import TwitApiClient

# The client will automatically load credentials from ../credentials.yml
client = TwitApiClient()
shows = client.get_shows()
print(shows)

# Alternatively, you can provide credentials directly
client = TwitApiClient('your_app_id', 'your_app_key')
```

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
