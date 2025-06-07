# TWiT API PHP Examples

This directory contains PHP code for testing and interacting with the TWiT.tv API.

## Prerequisites

- PHP 7.0 or higher
- PHP cURL extension enabled
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

- `twit_api_client.php`: A comprehensive client for interacting with multiple TWiT API endpoints
- `test_connection.php`: A simple script to test your connection to the TWiT API

## How to Use

### Basic Connection Test

Run the test connection script:

```bash
php test_connection.php
```

### Using the TWiT API Client

Run the client directly:

```bash
php twit_api_client.php
```

### Using the Client in Your Own Code

```php
<?php
require_once 'twit_api_client.php';

// The client will automatically load credentials from ../credentials.yml
$client = new TwitApiClient();
$shows = $client->get_shows();

// Alternatively, you can provide credentials directly
$client = new TwitApiClient('your_app_id', 'your_app_key', 'https://twit.tv/api/v1.0');

// Get a specific show
$show = $client->get_show('twit');

// Get episodes with parameters
$episodes = $client->get_episodes(['limit' => 5, 'sort' => 'publishDate,desc']);

// Get live streams
$streams = $client->get_streams();

// Get people
$people = $client->get_people();
?>
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
