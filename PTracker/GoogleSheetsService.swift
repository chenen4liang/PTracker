import Foundation

// Google Sheets Service for PTracker
// This will handle all communication with Google Sheets API

class GoogleSheetsService {
    static let shared = GoogleSheetsService()
    
    private let baseURL = "https://sheets.googleapis.com/v4/spreadsheets"
    private var sheetID: String = "" // You'll add your sheet ID here
    private var apiKey: String = "" // For development, we'll use API key first
    
    private init() {}
    
    // Configure the service with your Google Sheet details
    func configure(sheetID: String, apiKey: String) {
        self.sheetID = sheetID
        self.apiKey = apiKey
    }
    
    // MARK: - Read Operations
    
    func fetchPeriods(completion: @escaping (Result<[[String]], Error>) -> Void) {
        let range = "Sheet1!A2:F" // Skip header row
        let urlString = "\(baseURL)/\(sheetID)/values/\(range)?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(GoogleSheetsError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(GoogleSheetsError.noData))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(GoogleSheetsResponse.self, from: data)
                completion(.success(response.values ?? []))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Write Operations
    
    func appendPeriod(_ period: Period, completion: @escaping (Result<Bool, Error>) -> Void) {
        let range = "Sheet1!A:F"
        let urlString = "\(baseURL)/\(sheetID)/values/\(range):append?valueInputOption=USER_ENTERED&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(GoogleSheetsError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dateFormatter = ISO8601DateFormatter()
        let values = [[
            period.id.uuidString,
            dateFormatter.string(from: period.startDate),
            period.endDate != nil ? dateFormatter.string(from: period.endDate!) : "",
            "\(period.duration)",
            "", // Cycle length will be calculated in the sheet
            dateFormatter.string(from: Date())
        ]]
        
        let body = GoogleSheetsAppendRequest(values: values)
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                completion(.success(true))
            } else {
                completion(.failure(GoogleSheetsError.requestFailed))
            }
        }.resume()
    }
    
    // MARK: - Update Operations
    
    func updatePeriod(_ period: Period, row: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        let range = "Sheet1!A\(row):F\(row)"
        let urlString = "\(baseURL)/\(sheetID)/values/\(range)?valueInputOption=USER_ENTERED&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(GoogleSheetsError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dateFormatter = ISO8601DateFormatter()
        let values = [[
            period.id.uuidString,
            dateFormatter.string(from: period.startDate),
            period.endDate != nil ? dateFormatter.string(from: period.endDate!) : "",
            "\(period.duration)",
            "", // Cycle length
            dateFormatter.string(from: Date())
        ]]
        
        let body = GoogleSheetsUpdateRequest(values: values)
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                completion(.success(true))
            } else {
                completion(.failure(GoogleSheetsError.requestFailed))
            }
        }.resume()
    }
}

// MARK: - Data Models

struct GoogleSheetsResponse: Codable {
    let range: String
    let majorDimension: String
    let values: [[String]]?
}

struct GoogleSheetsAppendRequest: Codable {
    let values: [[String]]
}

struct GoogleSheetsUpdateRequest: Codable {
    let values: [[String]]
}

// MARK: - Errors

enum GoogleSheetsError: LocalizedError {
    case invalidURL
    case noData
    case requestFailed
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .noData:
            return "No data received from Google Sheets"
        case .requestFailed:
            return "Failed to complete request"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}