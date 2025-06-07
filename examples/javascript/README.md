# TWiT API JavaScript Examples

This directory contains JavaScript scripts for testing and interacting with the TWiT.tv API.

## Prerequisites

- Node.js (12.0 or higher recommended)
- API credentials from TWiT.tv's 3Scale service (app-id and app-key)
- No external dependencies required (uses only built-in Node.js modules)

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

- `test_connection.js`: A simple script to test your connection to the TWiT API
- `twit_api_client.js`: A more comprehensive client for interacting with multiple TWiT API endpoints

## How to Use

### Basic Connection Test

Run the script:

```bash
node test_connection.js
```

### Using the TWiT API Client

Run the client script:

```bash
node twit_api_client.js
```

### Using the Client in Your Own Scripts

```javascript
const TwitApiClient = require('./twit_api_client');

// The client will automatically load credentials from ../credentials.yml
const client = new TwitApiClient();
client.getShows()
  .then(shows => console.log(shows))
  .catch(error => console.error(error));

// Alternatively, you can provide credentials directly
const client = new TwitApiClient('your_app_id', 'your_app_key');
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
