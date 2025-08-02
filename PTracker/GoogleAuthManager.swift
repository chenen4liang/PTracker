import Foundation
import CryptoKit

// Google Service Account Authentication Manager
class GoogleAuthManager {
    static let shared = GoogleAuthManager()
    
    private var serviceAccountEmail: String = ""
    private var privateKey: String = ""
    private var privateKeyId: String = ""
    
    private init() {}
    
    // Load service account credentials from JSON
    func loadServiceAccount(from jsonData: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let email = json["client_email"] as? String,
              let privateKeyString = json["private_key"] as? String,
              let keyId = json["private_key_id"] as? String else {
            throw GoogleAuthError.invalidCredentials
        }
        
        self.serviceAccountEmail = email
        self.privateKey = privateKeyString
        self.privateKeyId = keyId
    }
    
    // Generate JWT for Google API authentication
    func generateJWT() throws -> String {
        let header = [
            "alg": "RS256",
            "typ": "JWT",
            "kid": privateKeyId
        ]
        
        let now = Int(Date().timeIntervalSince1970)
        let claims = [
            "iss": serviceAccountEmail,
            "scope": "https://www.googleapis.com/auth/spreadsheets",
            "aud": "https://oauth2.googleapis.com/token",
            "exp": now + 3600,
            "iat": now
        ]
        
        // Encode header and claims
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let claimsData = try JSONSerialization.data(withJSONObject: claims)
        
        let headerBase64 = headerData.base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        
        let claimsBase64 = claimsData.base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        
        let message = "\(headerBase64).\(claimsBase64)"
        
        // Sign with private key (simplified - in production use proper RSA signing)
        // For now, we'll use the JWT in the next step
        return message
    }
    
    // Get access token using service account
    func getAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        // For service account authentication, we need to:
        // 1. Create a JWT signed with the private key
        // 2. Exchange it for an access token
        
        // For now, let's use a simpler approach with API key
        // We'll implement full service account auth if needed
        
        completion(.failure(GoogleAuthError.notImplemented))
    }
}

// Simplified Google Sheets API Client
class GoogleSheetsAPIClient {
    static let shared = GoogleSheetsAPIClient()
    
    private let spreadsheetId = "1H3EOvKRu4YUl2BldU6dNR0YdaDUIMC0Oa4xkuqInET0"
    private let baseURL = "https://sheets.googleapis.com/v4/spreadsheets"
    
    // Store the API key or access token
    private var apiKey: String?
    private var accessToken: String?
    
    private init() {}
    
    func configure(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func configure(accessToken: String) {
        self.accessToken = accessToken
    }
    
    // Read data from sheet
    func readSheet(range: String, completion: @escaping (Result<[[String]], Error>) -> Void) {
        var urlString = "\(baseURL)/\(spreadsheetId)/values/\(range)"
        
        // Add authentication
        if let apiKey = apiKey {
            urlString += "?key=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(GoogleAuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        
        // Add bearer token if using OAuth
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(GoogleAuthError.noData))
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let values = json["values"] as? [[String]] {
                    DispatchQueue.main.async {
                        completion(.success(values))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(GoogleAuthError.invalidResponse))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Write data to sheet
    func writeSheet(range: String, values: [[String]], completion: @escaping (Result<Bool, Error>) -> Void) {
        var urlString = "\(baseURL)/\(spreadsheetId)/values/\(range)?valueInputOption=USER_ENTERED"
        
        if let apiKey = apiKey {
            urlString += "&key=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(GoogleAuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["values": values]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                DispatchQueue.main.async {
                    completion(.success(httpResponse.statusCode == 200))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(GoogleAuthError.invalidResponse))
                }
            }
        }.resume()
    }
    
    // Append data to sheet
    func appendToSheet(values: [[String]], completion: @escaping (Result<Bool, Error>) -> Void) {
        var urlString = "\(baseURL)/\(spreadsheetId)/values/A:E:append?valueInputOption=USER_ENTERED"
        
        if let apiKey = apiKey {
            urlString += "&key=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(GoogleAuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["values": values]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                DispatchQueue.main.async {
                    completion(.success(httpResponse.statusCode == 200))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(GoogleAuthError.invalidResponse))
                }
            }
        }.resume()
    }
}

// Errors
enum GoogleAuthError: LocalizedError {
    case invalidCredentials
    case invalidURL
    case noData
    case invalidResponse
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid service account credentials"
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response from server"
        case .notImplemented:
            return "Feature not yet implemented"
        }
    }
}