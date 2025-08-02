import SwiftUI

struct SettingsView: View {
    @StateObject private var sheetsManager = GoogleSheetsManager.shared
    @State private var sheetID = ""
    @State private var showingInstructions = false
    @State private var showingExportSheet = false
    @State private var csvExport = ""
    @State private var showingDocumentPicker = false
    @State private var showingAuthAlert = false
    @State private var authAlertMessage = ""
    @State private var apiKey = ""
    
    @Binding var periods: [Period]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Google Sheets Authentication")) {
                    if sheetsManager.isAuthenticated {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Authenticated")
                                .foregroundColor(.green)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            // Option 1: Service Account (Full Access)
                            Button(action: {
                                showingDocumentPicker = true
                            }) {
                                Label("Upload Service Account JSON", systemImage: "doc.badge.plus")
                            }
                            .foregroundColor(.blue)
                            
                            Text("Or")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            // Option 2: API Key (Read-Only)
                            TextField("Google API Key", text: $apiKey)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if !apiKey.isEmpty {
                                Button(action: {
                                    sheetsManager.configureWithAPIKey(apiKey)
                                    authAlertMessage = "API Key configured successfully!"
                                    showingAuthAlert = true
                                }) {
                                    Label("Use API Key", systemImage: "key")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Button("How to authenticate?") {
                        showingInstructions = true
                    }
                    .foregroundColor(.blue)
                }
                
                Section(header: Text("Sync")) {
                    if sheetsManager.isSyncing {
                        HStack {
                            ProgressView()
                            Text("Syncing...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: syncData) {
                            Label("Sync with Google Sheets", systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        if let lastSync = sheetsManager.lastSyncDate {
                            Text("Last synced: \(lastSync, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Export")) {
                    Button(action: exportToCSV) {
                        Label("Export to CSV", systemImage: "square.and.arrow.up")
                    }
                    
                    Text("Export your data as CSV to manually import into Google Sheets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Privacy")) {
                    Text("Your period data is stored locally on your device. Google Sheets sync is optional and requires you to manually configure access.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingInstructions) {
            InstructionsView()
        }
        .sheet(isPresented: $showingExportSheet) {
            ShareSheet(items: [csvExport])
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                handleServiceAccountFile(url)
            }
        }
        .alert("Authentication", isPresented: $showingAuthAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authAlertMessage)
        }
    }
    
    private func handleServiceAccountFile(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            sheetsManager.configureWithServiceAccount(jsonData: data)
            authAlertMessage = "Service account configured successfully!"
            showingAuthAlert = true
        } catch {
            authAlertMessage = "Failed to load service account file: \(error.localizedDescription)"
            showingAuthAlert = true
        }
    }
    
    private func syncData() {
        sheetsManager.syncPeriods(localPeriods: periods) { result in
            switch result {
            case .success(let syncedPeriods):
                // Update local periods with synced data
                periods = syncedPeriods
            case .failure(let error):
                print("Sync error: \(error.localizedDescription)")
            }
        }
    }
    
    private func exportToCSV() {
        csvExport = sheetsManager.exportToCSV(periods: periods)
        showingExportSheet = true
    }
}

struct InstructionsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Set Up Google Sheets")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Create a Google Sheet")
                            .fontWeight(.semibold)
                        Text("Go to sheets.google.com and create a new spreadsheet")
                        
                        Text("2. Set up columns")
                            .fontWeight(.semibold)
                        Text("Add these headers in row 1:")
                        Text("• A1: ID\n• B1: StartDate\n• C1: EndDate\n• D1: Duration\n• E1: Notes")
                            .font(.caption)
                            .padding(.leading)
                        
                        Text("3. Get the Sheet ID")
                            .fontWeight(.semibold)
                        Text("Look at your sheet URL:")
                        Text("docs.google.com/spreadsheets/d/SHEET_ID/edit")
                            .font(.caption)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        Text("Copy the SHEET_ID part")
                        
                        Text("4. Make sheet readable")
                            .fontWeight(.semibold)
                        Text("Click Share → Change to 'Anyone with the link can view'")
                        Text("(For read-only sync)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Text("Note: Currently supports read-only sync. For full sync, OAuth2 setup is required.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding()
                }
            }
            .navigationTitle("Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#if canImport(UIKit)
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onPick(url)
        }
    }
}
#endif