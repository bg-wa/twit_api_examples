package tv.twit.api;

import org.json.JSONObject;

/**
 * TWiT API Connection Test Script
 * This script tests the connection to the TWiT.tv API
 */
public class TestConnection {
    
    /**
     * Main method to test connection to the TWiT API
     * 
     * @param args Command line arguments (not used)
     */
    public static void main(String[] args) {
        try {
            System.out.println("Loading credentials...");
            
            // Create a new TWiT API client (will load credentials from file)
            TwitApiClient client = new TwitApiClient();
            
            // Test endpoint - shows is a simple endpoint to test
            String endpoint = "/shows";
            System.out.println("\nTesting connection to TWiT API...");
            System.out.println("Endpoint: " + client.getBaseUrl() + endpoint);
            
            // Make the request
            JSONObject response = client.getShows();
            
            // Check for errors
            if (response.has("error")) {
                System.out.println("Connection failed with error: " + response.getString("error"));
                if (response.has("code")) {
                    System.out.println("HTTP Status: " + response.getInt("code"));
                }
                
                // Provide additional guidance based on error code
                if (response.has("code")) {
                    int code = response.getInt("code");
                    if (code == 401 || code == 403) {
                        System.out.println("Authentication failed. Check your APP_ID and APP_KEY.");
                    } else if (code == 404) {
                        System.out.println("Resource not found. Check that the API endpoint is correct.");
                    } else if (code == 500) {
                        System.out.println("Server error. If the message contains 'application is not active', " +
                                "you need to activate your API credentials in the TWiT.tv 3Scale portal.");
                    }
                }
            } else {
                // Success! Display some information about the response
                System.out.println("Connection successful!");
                
                if (response.has("count")) {
                    System.out.println("Found " + response.getInt("count") + " shows");
                }
                
                // Display first few items if available
                if (response.has("shows")) {
                    System.out.println("\nFirst few shows:");
                    for (int i = 0; i < Math.min(3, response.getJSONArray("shows").length()); i++) {
                        JSONObject show = response.getJSONArray("shows").getJSONObject(i);
                        System.out.println("- " + show.getString("label") + " (" + show.getString("id") + ")");
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
