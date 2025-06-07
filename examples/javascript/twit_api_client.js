#!/usr/bin/env node
// TWiT API Client
// A more comprehensive client for interacting with the TWiT.tv API

const https = require('https');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

// Simple YAML parser for our basic needs
function parseYAML(content) {
  const lines = content.split('\n');
  const result = {};
  let currentSection = null;
  
  for (const line of lines) {
    // Skip comments and empty lines
    if (line.trim().startsWith('#') || !line.trim()) continue;
    
    // Handle section headers (keys with no value)
    if (!line.startsWith(' ') && line.includes(':')) {
      const parts = line.split(':');
      const key = parts[0].trim();
      const value = parts.slice(1).join(':').trim();
      
      if (!value) {
        currentSection = key;
        result[currentSection] = {};
      } else {
        // Remove any inline comments from the value
        const valueParts = value.split('#');
        result[key] = valueParts[0].trim();
      }
    } 
    // Handle indented properties (section values)
    else if (currentSection && line.trim().includes(':')) {
      const parts = line.trim().split(':');
      const key = parts[0].trim();
      const value = parts.slice(1).join(':').trim();
      
      // Remove any inline comments from the value
      const valueParts = value.split('#');
      result[currentSection][key] = valueParts[0].trim();
    }
  }
  
  return result;
}

class TwitApiClient {
  constructor(appId = null, appKey = null, baseUrl = null) {
    // Setup logger
    this.logger = {
      debug: (message) => console.debug(`[DEBUG] ${message}`),
      info: (message) => console.info(`[INFO] ${message}`),
      error: (message) => console.error(`[ERROR] ${message}`)
    };

    // Try to load credentials from file if not provided
    if (!appId || !appKey) {
      this.loadCredentialsFromFile();
    } else {
      this.appId = appId;
      this.appKey = appKey;
      this.baseUrl = baseUrl || 'https://twit.tv/api/v1.0';
    }
  }

  // Get a list of all shows
  async getShows(params = {}) {
    return this.makeRequest('/shows', params);
  }

  // Get a specific show by ID
  async getShow(id, params = {}) {
    return this.makeRequest(`/shows/${id}`, params);
  }

  // Get a list of all episodes
  async getEpisodes(params = {}) {
    return this.makeRequest('/episodes', params);
  }

  // Get a specific episode by ID
  async getEpisode(id, params = {}) {
    return this.makeRequest(`/episodes/${id}`, params);
  }

  // Get live streams information
  async getStreams(params = {}) {
    return this.makeRequest('/streams', params);
  }

  // Get people information
  async getPeople(params = {}) {
    return this.makeRequest('/people', params);
  }

  // Load credentials from the shared credentials file
  loadCredentialsFromFile() {
    const scriptDir = path.dirname(require.main ? require.main.filename : __filename);
    const credentialsFile = path.join(scriptDir, '..', 'credentials.yml');
    
    if (fs.existsSync(credentialsFile)) {
      try {
        const content = fs.readFileSync(credentialsFile, 'utf8');
        const credentials = parseYAML(content);
        this.appId = credentials.twit_api.app_id;
        this.appKey = credentials.twit_api.app_key;
        this.baseUrl = credentials.twit_api.base_url || 'https://twit.tv/api/v1.0';
        
        this.logger.debug(`Loaded credentials - APP_ID: ${this.appId}, BASE_URL: ${this.baseUrl}`);
      } catch (e) {
        this.logger.error(`Error loading credentials: ${e.message}`);
        throw new Error(`Failed to load credentials: ${e.message}. Please make sure your credentials.yml file is properly formatted.`);
      }
    } else {
      throw new Error(`Credentials file not found: ${credentialsFile}. Please copy credentials.yml.sample to credentials.yml and update with your actual credentials.`);
    }
  }

  // Make an HTTP request to the TWiT API
  makeRequest(endpoint, params = {}) {
    return new Promise((resolve, reject) => {
      try {
        // Build URL with query parameters if any
        let url = `${this.baseUrl}${endpoint}`;
        
        // Add query parameters if any
        if (Object.keys(params).length > 0) {
          const queryParams = new URLSearchParams();
          for (const key in params) {
            queryParams.append(key, params[key]);
          }
          url += `?${queryParams.toString()}`;
        }
        
        const parsedUrl = new URL(url);
        
        // Create options for request
        const options = {
          hostname: parsedUrl.hostname,
          path: parsedUrl.pathname + parsedUrl.search,
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'app-id': this.appId,
            'app-key': this.appKey
          }
        };
        
        this.logger.debug(`Making request to: ${url}`);
        
        const req = https.request(options, (res) => {
          let data = '';
          
          res.on('data', (chunk) => {
            data += chunk;
          });
          
          res.on('end', () => {
            const status = res.statusCode;
            
            if (status === 200) {
              try {
                const jsonData = JSON.parse(data);
                resolve(jsonData);
              } catch (e) {
                this.logger.error(`Error parsing JSON response: ${e.message}`);
                reject(new Error(`Error parsing JSON response: ${e.message}`));
              }
            } else if (status === 401 || status === 403) {
              this.logger.error("Authentication error: Check your app-id and app-key");
              resolve({ "error": "Authentication failed", "code": status });
            } else if (status === 404) {
              this.logger.error(`Resource not found: ${endpoint}`);
              resolve({ "error": "Resource not found. Check that the API endpoint is correct.", "code": status });
            } else if (status === 500) {
              if (data.includes('usage limits are exceeded')) {
                this.logger.error("API usage limits exceeded");
                resolve({ "error": "API usage limits exceeded", "code": status });
              } else {
                this.logger.error(`Server error: ${data}`);
                resolve({ "error": "Server error", "code": status });
              }
            } else {
              this.logger.error(`Unexpected response: ${status} - ${data}`);
              resolve({ "error": "Unexpected response", "code": status, "body": data });
            }
          });
        });
        
        req.on('error', (e) => {
          this.logger.error(`Request failed: ${e.message}`);
          resolve({ "error": e.message });
        });
        
        req.end();
      } catch (e) {
        this.logger.error(`Error creating request: ${e.message}`);
        resolve({ "error": `Error creating request: ${e.message}` });
      }
    });
  }
}

// Example usage
if (require.main === module) {
  (async () => {
    try {
      const client = new TwitApiClient();
      
      console.log("Testing connection to TWiT API...");
      
      // Test getting shows
      const result = await client.getShows();
      
      if (result.error) {
        console.log(`Error: ${result.error}`);
      } else {
        console.log("Connection successful!");
        console.log(`Found ${result.count} shows`);
        
        if (result.shows && result.shows.length > 0) {
          console.log("\nFirst few shows:");
          result.shows.slice(0, 3).forEach(show => {
            console.log(`- ${show.label} (${show.id})`);
          });
          
          // Try to get a specific show (using the first show's ID if available)
          const firstShowId = result.shows[0].id;
          console.log(`\nGetting details for show ID: ${firstShowId}`);
          
          const showDetails = await client.getShow(firstShowId);
          if (!showDetails.error) {
            // For single show, the response has a 'shows' object, not an array
            if (showDetails.shows) {
              const show = showDetails.shows;
              console.log(`Show title: ${show.label}`);
              if (show.description) {
                console.log(`Description: ${show.description.substring(0, 100)}...`);
              }
            }
          }
        }
        
        // Get streams information
        console.log("\nGetting live streams information...");
        const streams = await client.getStreams();
        if (!streams.error && streams.streams) {
          console.log(`Found ${streams.count} streams`);
          streams.streams.slice(0, 2).forEach(stream => {
            console.log(`- ${stream.label} (${stream.streamType})`);
          });
        }
      }
    } catch (e) {
      console.error(`Error: ${e.message}`);
    }
  })();
}

module.exports = TwitApiClient;
