import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Simple TWiT API Connection Test
 * Uses only standard Java libraries
 */
public class SimpleTestConnection {
    
    public static void main(String[] args) {
        try {
            System.out.println("Loading credentials from: " + Paths.get("..").toAbsolutePath().normalize().toString() + "/credentials.yml");
            
            // Load and parse credentials
            Map<String, String> credentials = parseCredentialsFile("../credentials.yml");
            String appId = credentials.get("app_id");
            String appKey = credentials.get("app_key");
            String baseUrl = credentials.get("base_url");
            
            if (appId == null || appKey == null || baseUrl == null) {
                System.err.println("Error: Missing required credentials. Check your credentials.yml file.");
                System.exit(1);
            }
            
            System.out.println("Using APP_ID: " + appId);
            System.out.println("Using APP_KEY: " + maskString(appKey));
            System.out.println("Using BASE_URL: " + baseUrl);
            System.out.println("\nTesting connection to TWiT API...");
            
            // Test endpoint
            String endpoint = "/shows";
            String urlString = baseUrl + endpoint;
            System.out.println("Endpoint: " + urlString);
            System.out.println("Headers: app-id=" + appId + ", app-key=" + maskString(appKey));
            
            // Make the request
            URL url = new URL(urlString);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setRequestProperty("Accept", "application/json");
            connection.setRequestProperty("app-id", appId);
            connection.setRequestProperty("app-key", appKey);
            
            int statusCode = connection.getResponseCode();
            
            if (statusCode == 200) {
                // Success
                System.out.println("Connection successful with HTTP status: " + statusCode);
                
                // Read the response
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()))) {
                    StringBuilder response = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null) {
                        response.append(line);
                    }
                    
                    // Print a snippet of the response
                    String responseStr = response.toString();
                    System.out.println("Response snippet: " + 
                            responseStr.substring(0, Math.min(100, responseStr.length())) + "...");
                    
                    // Check if response contains the expected structure
                    if (responseStr.contains("\"shows\"")) {
                        System.out.println("Response contains the 'shows' array as expected.");
                    } else if (responseStr.contains("\"_embedded\"")) {
                        System.out.println("Warning: Response contains '_embedded' structure which is outdated.");
                    }
                }
            } else {
                System.out.println("Connection failed with HTTP status: " + statusCode);
                
                // Read error response
                InputStream errorStream = connection.getErrorStream();
                if (errorStream != null) {
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(errorStream))) {
                        StringBuilder response = new StringBuilder();
                        String line;
                        while ((line = reader.readLine()) != null) {
                            response.append(line);
                        }
                        System.out.println("Response body: " + response.toString());
                    }
                }
                
                // Provide guidance based on status code
                if (statusCode == 401 || statusCode == 403) {
                    System.out.println("Authentication failed. Check your app-id and app-key.");
                } else if (statusCode == 404) {
                    System.out.println("Resource not found. Check that the API endpoint is correct.");
                } else if (statusCode == 500) {
                    System.out.println("Server error. If the message contains 'application is not active', " +
                            "you need to activate your API credentials in the TWiT.tv 3Scale portal.");
                }
            }
            
            connection.disconnect();
            
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Parse the YAML credentials file
     * 
     * @param filename Path to the credentials file
     * @return Map of credential keys and values
     */
    private static Map<String, String> parseCredentialsFile(String filename) throws IOException {
        Map<String, String> credentials = new HashMap<>();
        
        Path path = Paths.get(filename);
        if (!Files.exists(path)) {
            throw new IOException("Credentials file not found: " + path.toAbsolutePath());
        }
        
        boolean inTwitApiSection = false;
        Pattern keyValuePattern = Pattern.compile("\\s*(\\w+):\\s*([^#]*)(?:#.*)?");
        
        try (BufferedReader reader = new BufferedReader(new FileReader(path.toFile()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                // Check if we're entering the twit_api section
                if (line.trim().equals("twit_api:")) {
                    inTwitApiSection = true;
                    continue;
                }
                
                // If we're in the twit_api section, parse key-value pairs
                if (inTwitApiSection && line.contains(":")) {
                    Matcher matcher = keyValuePattern.matcher(line);
                    if (matcher.matches()) {
                        String key = matcher.group(1);
                        String value = matcher.group(2).trim();
                        credentials.put(key, value);
                    }
                }
                
                // If we hit a line that's not indented and not empty, we've left the twit_api section
                if (inTwitApiSection && !line.trim().isEmpty() && !line.startsWith(" ") && !line.startsWith("\t")) {
                    inTwitApiSection = false;
                }
            }
        }
        
        return credentials;
    }
    
    /**
     * Mask a string for display (e.g., for API keys)
     * 
     * @param input String to mask
     * @return Masked string
     */
    private static String maskString(String input) {
        if (input == null || input.length() <= 8) {
            return "********";
        }
        return input.substring(0, 4) + "********************************";
    }
}
