# TWiT API Client - Common Lisp Implementation

This is a Common Lisp implementation of the TWiT.tv API client. It provides a simple way to interact with the TWiT.tv API endpoints.

## Quick Start

The easiest way to get started is to use our setup script and run the client:

```bash
# Install dependencies and set up environment
./setup.sh

# Copy the sample credentials file and update with your API credentials
cp ../credentials.yml.sample ../credentials.yml
# Edit ../credentials.yml with your actual credentials

# Run the TWiT API client
./run-test-connection.sh test-connection.lisp
```

## Manual Installation

### 1. Install SBCL (Steel Bank Common Lisp)

```bash
sudo apt-get update
sudo apt-get install -y sbcl
```

### 2. Install Quicklisp (Common Lisp package manager)

```bash
curl -O https://beta.quicklisp.org/quicklisp.lisp
sbcl --load quicklisp.lisp --eval '(quicklisp-quickstart:install)' --eval '(ql:add-to-init-file)' --quit
```

### 3. Install required dependencies

Start SBCL and install the required packages:

```bash
sbcl --eval '(ql:quickload :dexador)' \
     --eval '(ql:quickload :jonathan)' \
     --eval '(ql:quickload :cl-ppcre)' \
     --eval '(ql:quickload :local-time)' \
     --quit
```

## Project Structure

- `test-connection.lisp` - The main TWiT API client implementation with test connection functionality
- `run-test-connection.sh` - Shell script to run the client
- `setup.sh` - Script to install dependencies and set up the environment
- `README.md` - This documentation file

## API Endpoints

The TWiT API client provides access to the following endpoints:

- `/shows` - Get a list of all shows
- `/shows/{id}` - Get a specific show by ID
- `/episodes` - Get a list of all episodes
- `/episodes/{id}` - Get a specific episode by ID
- `/streams` - Get live streams information
- `/people` - Get people information

## Features

- HTTP requests using Dexador
- JSON parsing with Jonathan
- Detailed logging with timestamps
- Error handling and reporting
- Support for all TWiT API endpoints
- Simple, clean implementation
- Credentials loaded from shared credentials.yml file

## Credentials

The client loads credentials from the shared `../credentials.yml` file. You need to create this file by copying the sample file and updating it with your actual credentials:

```bash
cp ../credentials.yml.sample ../credentials.yml
```

Then edit `../credentials.yml` and replace the placeholder values with your actual TWiT API credentials:

```yaml
twit_api:
  app_id: YOUR_APP_ID
  app_key: YOUR_APP_KEY
  base_url: https://twit.tv/api/v1.0
```

## Dependencies

This implementation uses the following Common Lisp libraries:

- dexador - HTTP client
- jonathan - JSON parser
- cl-ppcre - Regular expressions
- local-time - Date/time handling

## Development Process

This client was developed through several iterations:

1. Initial implementation with basic structure
2. Debugging and fixing package loading issues
3. Creating a minimal test client to verify dependencies
4. Implementing a full client with proper error handling
5. Final version with comprehensive logging and API endpoint support
6. Updated to load credentials from file instead of hardcoding them

## Troubleshooting

If you encounter any issues:

1. Make sure all dependencies are installed correctly
2. Check that the API credentials are valid and properly set in `../credentials.yml`
3. Review the detailed logs for error messages
4. Ensure your network can reach the TWiT.tv API servers

For API usage limits exceeded errors, wait and try again later.
