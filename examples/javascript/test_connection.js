#!/usr/bin/env node
// TWiT API Connection Test Script
// This script tests the connection to the TWiT.tv API

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

// Load credentials from shared credentials file
const scriptDir = path.dirname(__filename);
const credentialsFile = path.join(scriptDir, '..', 'credentials.yml');

if (fs.existsSync(credentialsFile)) {
  try {
    console.log(`Loading credentials from: ${credentialsFile}`);
    const credentialsContent = fs.readFileSync(credentialsFile, 'utf8');
    console.log(`Credentials file content (first line): ${credentialsContent.split('\n')[0].trim()}`);

    const credentials = parseYAML(credentialsContent);
    console.log(`Parsed YAML structure: ${JSON.stringify(credentials)}`);

    const APP_ID = credentials.twit_api.app_id;
    const APP_KEY = credentials.twit_api.app_key;
    const API_BASE_URL = credentials.twit_api.base_url || 'https://twit.tv/api/v1.0';

    console.log(`Using APP_ID: ${APP_ID}`);
    console.log(`Using APP_KEY: ${'*'.repeat(APP_KEY.length)}`); // Mask the actual key for security
    console.log(`Using BASE_URL: ${API_BASE_URL}`);

    // Test endpoint - shows is a simple endpoint to test
    const endpoint = '/shows';
    const url = `${API_BASE_URL}${endpoint}`;
    
    try {
      const parsedUrl = new URL(url);

      // Create options for request
      const options = {
        hostname: parsedUrl.hostname,
        path: parsedUrl.pathname + parsedUrl.search,
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'app-id': APP_ID,
          'app-key': APP_KEY
        }
      };

      console.log("\nTesting connection to TWiT API...");
      console.log(`Endpoint: ${url}`);
      console.log(`Headers: app-id=${APP_ID}, app-key=${APP_KEY}`);

      // Send request
      const req = https.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
          data += chunk;
        });
        
        res.on('end', () => {
          // Parse and display response
          if (res.statusCode === 200) {
            console.log(`Connection successful! (HTTP ${res.statusCode})`);

            // Parse JSON response
            try {
              const result = JSON.parse(data);

              // Display some basic info about the response
              if (result.count) {
                console.log(`Found ${result.count} shows`);
              }

              // Display first few items if available
              if (result.shows && result.shows.length > 0) {
                console.log("\nFirst few shows:");
                result.shows.slice(0, 3).forEach(show => {
                  console.log(`- ${show.label} (${show.id})`);
                });
              }
            } catch (e) {
              console.error(`Error parsing JSON response: ${e.message}`);
            }
          } else {
            console.log(`Connection failed with HTTP status: ${res.statusCode}`);
            console.log(`Response body: ${data}`);

            // Check for specific error messages
            if (res.statusCode === 500 && data.includes('usage limits are exceeded')) {
              console.log("Error: API usage limits exceeded. Check your plan limits.");
            } else if (res.statusCode === 401 || res.statusCode === 403) {
              console.log("Error: Authentication failed. Check your APP_ID and APP_KEY.");
            } else if (res.statusCode === 404) {
              console.log("Error: Resource not found. Check that the API endpoint is correct.");
              console.log("The API might be at a different URL or the path might be incorrect.");
            }
          }
        });
      });

      req.on('error', (e) => {
        console.error(`Error connecting to API: ${e.message}`);
      });

      req.end();
    } catch (e) {
      console.error(`Error with URL: ${e.message}`);
      console.log(`Invalid URL: ${url}`);
      console.log("Please check the base_url in your credentials.yml file.");
    }
  } catch (e) {
    console.error(`Error loading credentials: ${e.message}`);
    console.log("Please make sure your credentials.yml file is properly formatted.");
    console.log("You can copy credentials.yml.sample to credentials.yml and update with your actual credentials.");
    process.exit(1);
  }
} else {
  console.error(`Credentials file not found: ${credentialsFile}`);
  console.log("Please copy credentials.yml.sample to credentials.yml and update with your actual credentials.");
  process.exit(1);
}
