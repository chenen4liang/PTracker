import SwiftUI
#if canImport(UIKit)
import UniformTypeIdentifiers
#endif

struct SettingsView: View {
    @State private var showingExportSheet = false
    @State private var csvExport = ""
    @State private var csvFileURL: URL?
    
    @Binding var periods: [Period]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Data Export")) {
                    Button(action: exportToCSV) {
                        Label("Export to CSV", systemImage: "square.and.arrow.up")
                    }
                    
                    Text("Export your period data as a CSV file")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("About")) {
                    Text("Period Tracker helps you track your menstrual cycles and predict future periods.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Privacy")) {
                    Text("Your period data is stored locally on your device. No data is sent to external servers.")
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
        #if canImport(UIKit)
        .sheet(isPresented: $showingExportSheet) {
            if let fileURL = csvFileURL {
                ShareSheet(items: [fileURL])
            }
        }
        #else
        .sheet(isPresented: $showingExportSheet) {
            // Fallback for non-UIKit platforms
            VStack {
                Text("CSV Export")
                    .font(.title)
                    .padding()
                ScrollView {
                    Text(csvExport)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                Button("Done") {
                    showingExportSheet = false
                }
                .padding()
            }
        }
        #endif
    }
    
    private func exportToCSV() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var csv = "Start Date,End Date,Duration (days),Cycle Length (days)\n"
        
        let sortedPeriods = periods.sorted { $0.startDate < $1.startDate }
        
        for (index, period) in sortedPeriods.enumerated() {
            let startDate = dateFormatter.string(from: period.startDate)
            let endDate = period.endDate != nil ? dateFormatter.string(from: period.endDate!) : ""
            let duration = period.duration
            
            // Calculate cycle length to next period
            var cycleLength = ""
            if index < sortedPeriods.count - 1 {
                let nextPeriod = sortedPeriods[index + 1]
                let days = Calendar.current.dateComponents([.day], from: period.startDate, to: nextPeriod.startDate).day ?? 0
                cycleLength = "\(days)"
            }
            
            csv += "\(startDate),\(endDate),\(duration),\(cycleLength)\n"
        }
        
        csvExport = csv
        
        #if canImport(UIKit)
        // Create a temporary file
        let fileName = "period_tracker_export_\(Date().timeIntervalSince1970).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            // Share the file URL instead of the string
            csvFileURL = tempURL
        } catch {
            print("Failed to create CSV file: \(error)")
        }
        #endif
        
        showingExportSheet = true
    }
}

#if canImport(UIKit)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
#endif

struct InstructionsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Use Period Tracker")
                        .font(.title2)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Track Your Period", systemImage: "1.circle.fill")
                            .font(.headline)
                        Text("Tap the + button to log when your period starts. The app will automatically calculate cycle lengths and predict future periods.")
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Label("View Statistics", systemImage: "2.circle.fill")
                            .font(.headline)
                        Text("See your average cycle length, period duration, and other helpful statistics based on your tracked data.")
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Export Your Data", systemImage: "3.circle.fill")
                            .font(.headline)
                        Text("Export your period data as a CSV file that you can save or share with your healthcare provider.")
                    }
                }
                .padding()
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