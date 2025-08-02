import Foundation
import SwiftUI

// Simplified Google Sheets Manager using REST API
class GoogleSheetsManager: ObservableObject {
    static let shared = GoogleSheetsManager()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var isAuthenticated = false
    
    private let apiClient = GoogleSheetsAPIClient.shared
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Configuration
    
    func configureWithServiceAccount(jsonData: Data) {
        do {
            try GoogleAuthManager.shared.loadServiceAccount(from: jsonData)
            isAuthenticated = true
            UserDefaults.standard.set(jsonData, forKey: "GoogleServiceAccount")
        } catch {
            print("Failed to load service account: \(error)")
            isAuthenticated = false
        }
    }
    
    func configureWithAPIKey(_ apiKey: String) {
        apiClient.configure(apiKey: apiKey)
        isAuthenticated = true
        UserDefaults.standard.set(apiKey, forKey: "GoogleAPIKey")
    }
    
    private func loadConfiguration() {
        // Try to load service account first
        if let serviceAccountData = UserDefaults.standard.data(forKey: "GoogleServiceAccount") {
            do {
                try GoogleAuthManager.shared.loadServiceAccount(from: serviceAccountData)
                isAuthenticated = true
            } catch {
                print("Failed to load saved service account")
            }
        }
        
        // Check for bundled service account JSON
        if !isAuthenticated,
           let url = Bundle.main.url(forResource: "GoogleServiceAccount", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                try GoogleAuthManager.shared.loadServiceAccount(from: data)
                isAuthenticated = true
                print("Loaded bundled service account")
            } catch {
                print("Failed to load bundled service account: \(error)")
            }
        }
        
        // Try API key as fallback
        if !isAuthenticated, let apiKey = UserDefaults.standard.string(forKey: "GoogleAPIKey") {
            apiClient.configure(apiKey: apiKey)
            isAuthenticated = true
        }
        
        self.lastSyncDate = UserDefaults.standard.object(forKey: "LastSyncDate") as? Date
    }
    
    // MARK: - Sync Operations
    
    func syncPeriods(localPeriods: [Period], completion: @escaping (Result<[Period], Error>) -> Void) {
        isSyncing = true
        
        // For now, we'll use a simple approach
        // Later we can implement OAuth2 for full read/write access
        
        fetchPeriodsFromSheet { [weak self] result in
            self?.isSyncing = false
            
            switch result {
            case .success(let remotePeriods):
                // Merge local and remote periods
                let mergedPeriods = self?.mergePeriods(local: localPeriods, remote: remotePeriods) ?? localPeriods
                
                self?.lastSyncDate = Date()
                UserDefaults.standard.set(self?.lastSyncDate, forKey: "LastSyncDate")
                
                completion(.success(mergedPeriods))
                
            case .failure(let error):
                print("Sync failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Read from Google Sheets
    
    private func fetchPeriodsFromSheet(completion: @escaping (Result<[Period], Error>) -> Void) {
        guard isAuthenticated else {
            completion(.failure(GoogleSheetsError.authenticationRequired))
            return
        }
        
        // Read from Google Sheets using API client
        apiClient.readSheet(range: "A2:E") { result in
            switch result {
            case .success(let values):
                let periods = self.parsePeriods(from: values)
                completion(.success(periods))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Parse Data
    
    private func parsePeriods(from values: [[String]]) -> [Period] {
        let dateFormatter = ISO8601DateFormatter()
        var periods: [Period] = []
        
        for row in values {
            guard row.count >= 3,
                  let id = UUID(uuidString: row[0]),
                  let startDate = dateFormatter.date(from: row[1]) else {
                continue
            }
            
            let endDate = row.count > 2 && !row[2].isEmpty ? dateFormatter.date(from: row[2]) : nil
            
            let period = Period(
                id: id,
                startDate: startDate,
                endDate: endDate
            )
            periods.append(period)
        }
        
        return periods
    }
    
    // MARK: - Merge Logic
    
    private func mergePeriods(local: [Period], remote: [Period]) -> [Period] {
        var mergedPeriods = local
        
        // Add remote periods that don't exist locally
        for remotePeriod in remote {
            if !mergedPeriods.contains(where: { $0.id == remotePeriod.id }) {
                mergedPeriods.append(remotePeriod)
            }
        }
        
        return mergedPeriods.sorted { $0.startDate > $1.startDate }
    }
    
    // MARK: - Write to Google Sheets
    
    func writePeriodToSheet(_ period: Period, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard isAuthenticated else {
            completion(.failure(GoogleSheetsError.authenticationRequired))
            return
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let endDateString = period.endDate != nil ? dateFormatter.string(from: period.endDate!) : ""
        
        let values = [[
            period.id.uuidString,
            dateFormatter.string(from: period.startDate),
            endDateString,
            "\(period.duration)",
            ""
        ]]
        
        apiClient.appendToSheet(values: values) { result in
            switch result {
            case .success(let success):
                if success {
                    self.lastSyncDate = Date()
                    UserDefaults.standard.set(self.lastSyncDate, forKey: "LastSyncDate")
                }
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Export to CSV for manual upload
    
    func exportToCSV(periods: [Period]) -> String {
        let dateFormatter = ISO8601DateFormatter()
        var csv = "ID,StartDate,EndDate,Duration,Notes\n"
        
        for period in periods {
            let endDateString = period.endDate != nil ? dateFormatter.string(from: period.endDate!) : ""
            csv += "\(period.id.uuidString),\(dateFormatter.string(from: period.startDate)),\(endDateString),\(period.duration),\n"
        }
        
        return csv
    }
}

// MARK: - Data Models

struct GoogleSheetsValueResponse: Codable {
    let range: String?
    let majorDimension: String?
    let values: [[String]]?
}

// MARK: - Errors

enum GoogleSheetsError: LocalizedError {
    case notConfigured
    case invalidURL
    case noData
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Google Sheets not configured. Please add your Sheet ID."
        case .invalidURL:
            return "Invalid Google Sheets URL"
        case .noData:
            return "No data received from Google Sheets"
        case .authenticationRequired:
            return "Authentication required for this operation"
        }
    }
}