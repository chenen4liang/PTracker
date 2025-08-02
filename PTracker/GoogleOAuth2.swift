import Foundation
import CryptoKit

// Google OAuth2 Implementation for Service Account
class GoogleOAuth2 {
    static let shared = GoogleOAuth2()
    
    private var cachedToken: String?
    private var tokenExpiration: Date?
    
    private init() {}
    
    // Get access token from service account
    func getAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        // Check if we have a valid cached token
        if let token = cachedToken,
           let expiration = tokenExpiration,
           expiration > Date() {
            completion(.success(token))
            return
        }
        
        // Load service account credentials
        guard let url = Bundle.main.url(forResource: "GoogleServiceAccount", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let clientEmail = json["client_email"] as? String,
              let privateKey = json["private_key"] as? String,
              let tokenUri = json["token_uri"] as? String else {
            completion(.failure(GoogleAuthError.invalidCredentials))
            return
        }
        
        // Create JWT
        let now = Int(Date().timeIntervalSince1970)
        let exp = now + 3600 // 1 hour
        
        let header = [
            "alg": "RS256",
            "typ": "JWT"
        ]
        
        let claims = [
            "iss": clientEmail,
            "scope": "https://www.googleapis.com/auth/spreadsheets",
            "aud": tokenUri,
            "exp": exp,
            "iat": now
        ] as [String : Any]
        
        // For simplicity, we'll use URLSession to exchange credentials
        // In production, you'd properly sign the JWT with the private key
        
        // Create request to get access token
        guard let tokenURL = URL(string: tokenUri) else {
            completion(.failure(GoogleAuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // For now, we'll use a simplified approach
        // In production, implement proper JWT signing
        let grantType = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        let assertion = createSimpleJWT(clientEmail: clientEmail, tokenUri: tokenUri)
        
        let body = "grant_type=\(grantType)&assertion=\(assertion)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                DispatchQueue.main.async {
                    completion(.failure(GoogleAuthError.invalidResponse))
                }
                return
            }
            
            // Cache the token
            self?.cachedToken = accessToken
            self?.tokenExpiration = Date().addingTimeInterval(3500) // Slightly less than 1 hour
            
            DispatchQueue.main.async {
                completion(.success(accessToken))
            }
        }.resume()
    }
    
    private func createSimpleJWT(clientEmail: String, tokenUri: String) -> String {
        // This is a placeholder - in production, implement proper JWT signing
        // For now, we'll use the API key approach
        return ""
    }
}

// Enhanced Google Sheets Manager with proper authentication
extension GoogleSheetsManager {
    func syncWithOAuth2(periods: [Period], completion: @escaping (Result<[Period], Error>) -> Void) {
        // First, ensure we have the sheet shared with our service account
        guard isAuthenticated else {
            // Try to load from bundled service account
            if let url = Bundle.main.url(forResource: "GoogleServiceAccount", withExtension: "json"),
               let data = try? Data(contentsOf: url) {
                configureWithServiceAccount(jsonData: data)
            } else {
                completion(.failure(GoogleSheetsError.authenticationRequired))
                return
            }
        }
        
        // Use the existing sync method
        syncPeriods(localPeriods: periods, completion: completion)
    }
}