# TWiT API Java Examples

This directory contains Java code for testing and interacting with the TWiT.tv API.

## Prerequisites

- Java 8 or higher
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

- `SimpleTestConnection.java`: A standalone test script that uses only standard Java libraries
- `src/main/java/tv/twit/api/TwitApiClient.java`: A comprehensive client for interacting with multiple TWiT API endpoints
- `src/main/java/tv/twit/api/TestConnection.java`: A simple script to test your connection to the TWiT API using the client

## How to Run

### Simple Connection Test (No Dependencies)

The `SimpleTestConnection.java` file can be compiled and run directly without any additional dependencies:

```bash
# Compile the file
javac SimpleTestConnection.java

# Run the compiled class
java SimpleTestConnection
```

This is the easiest way to test your connection to the TWiT API.

### Using the Full Client (With Dependencies)

If you have Maven installed:

```bash
# Build the project
mvn clean package

# Run the test connection
java -cp target/twit-api-examples-1.0-SNAPSHOT-jar-with-dependencies.jar tv.twit.api.TestConnection

# Run the client directly
java -cp target/twit-api-examples-1.0-SNAPSHOT-jar-with-dependencies.jar tv.twit.api.TwitApiClient
```

If you don't have Maven, you'll need to manually download and include the following dependencies in your classpath:
- org.apache.httpcomponents:httpclient
- org.json:json
- org.yaml:snakeyaml

## API Response Structure

The TWiT API returns JSON with a consistent structure across endpoints:

- Main data is in arrays named after the endpoint (`shows`, `episodes`, `streams`, etc.)
- Items have a `label` field (not `title`) for the display name
- Single item requests (e.g., `/shows/{id}`) return an object with the endpoint name as the key (e.g., `shows` object)

Example response structure:
```json
{
  "count": 71,
  "shows": [
    {
      "id": "65161",
      "label": "All TWiT.tv Shows",
      "description": "..."
    },
    ...
  ]
}
```

## Using the Client in Your Own Code

```java
import tv.twit.api.TwitApiClient;
import org.json.JSONObject;

// The client will automatically load credentials from ../credentials.yml
TwitApiClient client = new TwitApiClient();
JSONObject response = client.getShows();

// Access the shows array
if (response.has("shows")) {
    JSONArray shows = response.getJSONArray("shows");
    // Process shows...
}

// Get a specific show
JSONObject showResponse = client.getShow("1635");
if (showResponse.has("shows")) {
    JSONObject show = showResponse.getJSONObject("shows");
    String label = show.getString("label");
}
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
