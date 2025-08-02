//
//  ContentView.swift
//  PTracker
//
//  Created by Chenen Liang on 8/1/25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var periods: [Period] = []
    @State private var showingAddPeriod = false
    @State private var selectedDate = Date()
    @State private var showingEditPeriod = false
    @State private var periodToEdit: Period?
    @State private var showingChartView = false
    
    var averageCycleLength: Int {
        guard periods.count >= 2 else { return 28 }
        
        let sortedPeriods = periods.sorted { $0.startDate < $1.startDate }
        var cycleLengths: [Int] = []
        
        for i in 1..<sortedPeriods.count {
            let daysBetween = Calendar.current.dateComponents([.day], 
                from: sortedPeriods[i-1].startDate, 
                to: sortedPeriods[i].startDate).day ?? 28
            cycleLengths.append(daysBetween)
        }
        
        return cycleLengths.isEmpty ? 28 : cycleLengths.reduce(0, +) / cycleLengths.count
    }
    
    var nextPeriodDate: Date? {
        guard let lastPeriod = periods.sorted(by: { $0.startDate > $1.startDate }).first else {
            return nil
        }
        
        return Calendar.current.date(byAdding: .day, value: averageCycleLength, to: lastPeriod.startDate)
    }
    
    var daysUntilNextPeriod: Int? {
        guard let next = nextPeriodDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: next).day
    }
    
    var currentCycleDay: Int {
        guard let lastPeriod = periods.sorted(by: { $0.startDate > $1.startDate }).first else {
            return 1
        }
        
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod.startDate, to: Date()).day ?? 0
        return daysSinceLastPeriod + 1
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Circular Cycle View
                VStack(spacing: 20) {
                    CycleCircleView(
                        currentDay: currentCycleDay,
                        averageCycleLength: averageCycleLength,
                        daysUntilNextPeriod: daysUntilNextPeriod ?? 0
                    )
                    
                    Text("Today is day \(currentCycleDay) of your cycle.")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 40) {
                        VStack {
                            Image(systemName: "arrow.right.circle")
                                .font(.title)
                                .foregroundColor(.white)
                            Text("Next \(daysUntilNextPeriod ?? 0)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            showingChartView = true
                        }) {
                            VStack {
                                Image(systemName: "list.bullet.circle")
                                    .font(.title)
                                    .foregroundColor(.white)
                                Text("Cycle History")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.teal, Color.teal.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .padding()
                
                // Summary Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hello,")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.teal)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Your next period:")
                                .font(.body)
                                .foregroundColor(.teal)
                            Text("Average cycle length:")
                                .font(.body)
                                .foregroundColor(.teal)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            if let nextDate = nextPeriodDate {
                                Text(nextDate, style: .date)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.teal)
                            } else {
                                Text("--")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.teal)
                            }
                            
                            Text("\(averageCycleLength) days")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.teal)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // Period History
                List {
                    Section(header: Text("Period History")) {
                        if periods.isEmpty {
                            Text("No periods logged yet")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(periods.sorted(by: { $0.startDate > $1.startDate })) { period in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(period.startDate, style: .date)
                                            .font(.headline)
                                        
                                        if let endDate = period.endDate {
                                            Text("Duration: \(period.duration) days")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Ongoing")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        deletePeriod(period)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .font(.callout)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    periodToEdit = period
                                    showingEditPeriod = true
                                }
                            }
                            .onDelete(perform: deletePeriods)
                        }
                    }
                }
                
                // Add Period Button
                Button(action: {
                    showingAddPeriod = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Period")
                    }
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Period Tracker")
            .onAppear {
                loadPeriods()
                requestNotificationPermission()
                scheduleNextPeriodNotification()
            }
        }
        .sheet(isPresented: $showingAddPeriod) {
            AddPeriodView { startDate, endDate in
                let period = Period(
                    id: UUID(),
                    startDate: startDate,
                    endDate: endDate
                )
                periods.append(period)
                savePeriods()
                scheduleNextPeriodNotification()
            }
        }
        .sheet(isPresented: $showingEditPeriod) {
            if let period = periodToEdit {
                EditPeriodView(period: period) { updatedPeriod in
                    if let index = periods.firstIndex(where: { $0.id == period.id }) {
                        periods[index] = updatedPeriod
                        savePeriods()
                        scheduleNextPeriodNotification()
                    }
                } onDelete: {
                    periods.removeAll { $0.id == period.id }
                    savePeriods()
                    scheduleNextPeriodNotification()
                }
            }
        }
        .sheet(isPresented: $showingChartView) {
            CycleChartView(periods: periods)
        }
    }
    
    func loadPeriods() {
        if let data = UserDefaults.standard.data(forKey: "SavedPeriods"),
           let decoded = try? JSONDecoder().decode([Period].self, from: data) {
            periods = decoded
        } else {
            // Import historical data if no periods exist
            importHistoricalData()
        }
    }
    
    func importHistoricalData() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        // Historical periods from your data with exact dates and durations
        let historicalPeriods = [
            ("Jan 14, 2025", 7),  // Cycle: 32d (from previous period)
            ("Feb 15, 2025", 7),  // Cycle: 29d (from Jan 14 + 32 = Feb 15)
            ("Mar 16, 2025", 7),  // Cycle: 30d (from Feb 15 + 29 = Mar 16) 
            ("Apr 15, 2025", 7),  // Cycle: 25d (from Mar 16 + 30 = Apr 15)
            ("May 10, 2025", 7),  // Cycle: 30d (from Apr 15 + 25 = May 10)
            ("Jun 9, 2025", 7),   // Cycle: 30d (from May 10 + 30 = Jun 9)
            ("Jul 9, 2025", 7)    // Cycle: N/A (most recent)
        ]
        
        var importedPeriods: [Period] = []
        
        for (dateString, duration) in historicalPeriods {
            if let startDate = dateFormatter.date(from: dateString) {
                let endDate = Calendar.current.date(byAdding: .day, value: duration - 1, to: startDate)
                let period = Period(
                    id: UUID(),
                    startDate: startDate,
                    endDate: endDate
                )
                importedPeriods.append(period)
            }
        }
        
        periods = importedPeriods
        savePeriods()
    }
    
    func savePeriods() {
        if let encoded = try? JSONEncoder().encode(periods) {
            UserDefaults.standard.set(encoded, forKey: "SavedPeriods")
        }
    }
    
    func deletePeriods(at offsets: IndexSet) {
        periods.remove(atOffsets: offsets)
        savePeriods()
        scheduleNextPeriodNotification()
    }
    
    func deletePeriod(_ period: Period) {
        periods.removeAll { $0.id == period.id }
        savePeriods()
        scheduleNextPeriodNotification()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    func scheduleNextPeriodNotification() {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard let nextDate = nextPeriodDate else { return }
        
        // Schedule notification 3 days before
        if let notificationDate = Calendar.current.date(byAdding: .day, value: -3, to: nextDate) {
            let content = UNMutableNotificationContent()
            content.title = "Period Reminder"
            content.body = "Your period is expected in 3 days"
            content.sound = .default
            
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour], from: notificationDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let request = UNNotificationRequest(identifier: "periodReminder", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
        
        // Schedule notification on the day
        let content = UNMutableNotificationContent()
        content.title = "Period Expected Today"
        content.body = "Based on your average cycle of \(averageCycleLength) days"
        content.sound = .default
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour], from: nextDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: "periodDay", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

struct Period: Identifiable, Codable {
    let id: UUID
    var startDate: Date
    var endDate: Date?
    
    var duration: Int {
        guard let endDate = endDate else { return 1 }
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day! + 1
    }
}

struct AddPeriodView: View {
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var hasEnded = false
    @Environment(\.dismiss) var dismiss
    let onSave: (Date, Date?) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Period Start Date")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                
                Section(header: Text("Period End Date")) {
                    Toggle("Period has ended", isOn: $hasEnded)
                    
                    if hasEnded {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            .disabled(endDate < startDate)
                    }
                }
            }
            .navigationTitle("Log Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(startDate, hasEnded ? endDate : nil)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditPeriodView: View {
    let period: Period
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var hasEnded: Bool
    @Environment(\.dismiss) var dismiss
    let onSave: (Period) -> Void
    let onDelete: () -> Void
    
    init(period: Period, onSave: @escaping (Period) -> Void, onDelete: @escaping () -> Void) {
        self.period = period
        self._startDate = State(initialValue: period.startDate)
        self._endDate = State(initialValue: period.endDate ?? Date())
        self._hasEnded = State(initialValue: period.endDate != nil)
        self.onSave = onSave
        self.onDelete = onDelete
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Period Start Date")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                
                Section(header: Text("Period End Date")) {
                    Toggle("Period has ended", isOn: $hasEnded)
                    
                    if hasEnded {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            .disabled(endDate < startDate)
                    }
                }
                
                Section {
                    Button(action: {
                        onDelete()
                        dismiss()
                    }) {
                        Text("Delete Period")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Edit Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedPeriod = period
                        updatedPeriod.startDate = startDate
                        updatedPeriod.endDate = hasEnded ? endDate : nil
                        onSave(updatedPeriod)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CycleCircleView: View {
    let currentDay: Int
    let averageCycleLength: Int
    let daysUntilNextPeriod: Int
    
    var body: some View {
        ZStack {
            // Background circle with dots
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 200, height: 200)
            
            // Cycle dots
            ForEach(0..<averageCycleLength, id: \.self) { day in
                let angle = Double(day) * 360.0 / Double(averageCycleLength) - 90
                let color = getDotColor(for: day + 1)
                
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .offset(x: cos(angle * .pi / 180) * 100, y: sin(angle * .pi / 180) * 100)
            }
            
            // Current day indicator
            VStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("day")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(currentDay)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 2) {
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text("remaining")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(daysUntilNextPeriod)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func getDotColor(for day: Int) -> Color {
        if day <= 7 {
            // Period days (red/pink)
            return day <= 5 ? Color.red : Color.pink
        } else if day <= currentDay {
            // Past days (gray)
            return Color.gray.opacity(0.6)
        } else {
            // Future days (white)
            return Color.white
        }
    }
}

struct CycleChartView: View {
    let periods: [Period]
    @State private var showingCycleLength = true
    @Environment(\.dismiss) var dismiss
    
    var cycleLengths: [Int] {
        guard periods.count >= 2 else { return [] }
        
        let sortedPeriods = periods.sorted { $0.startDate < $1.startDate }
        var lengths: [Int] = []
        
        for i in 1..<sortedPeriods.count {
            let daysBetween = Calendar.current.dateComponents([.day], 
                from: sortedPeriods[i-1].startDate, 
                to: sortedPeriods[i].startDate).day ?? 28
            lengths.append(daysBetween)
        }
        
        return lengths
    }
    
    var durations: [Int] {
        return periods.map { $0.duration }
    }
    
    var averageCycleLength: Double {
        guard !cycleLengths.isEmpty else { return 28.0 }
        return Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)
    }
    
    var minCycleLength: Int {
        cycleLengths.min() ?? 25
    }
    
    var maxCycleLength: Int {
        cycleLengths.max() ?? 45
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Summary")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Toggle buttons
                    HStack(spacing: 0) {
                        Button(action: {
                            showingCycleLength = true
                        }) {
                            Text("Cycle Length")
                                .font(.callout)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(showingCycleLength ? Color.white : Color.clear)
                                .foregroundColor(showingCycleLength ? .teal : .white)
                                .cornerRadius(20, corners: [.topLeft, .bottomLeft])
                        }
                        
                        Button(action: {
                            showingCycleLength = false
                        }) {
                            Text("Duration")
                                .font(.callout)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(!showingCycleLength ? Color.white : Color.clear)
                                .foregroundColor(!showingCycleLength ? .teal : .white)
                                .cornerRadius(20, corners: [.topRight, .bottomRight])
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    
                    // Date range
                    if let firstPeriod = periods.sorted(by: { $0.startDate < $1.startDate }).first,
                       let lastPeriod = periods.sorted(by: { $0.startDate > $1.startDate }).first {
                        Text("\(firstPeriod.startDate, formatter: chartDateFormatter) - \(lastPeriod.startDate, formatter: chartDateFormatter)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.teal, Color.teal.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Chart
                if showingCycleLength {
                    CycleHistoryChartView()
                        .frame(height: 250)
                        .padding()
                } else {
                    CycleLineChart(
                        data: durations,
                        averageValue: Double(durations.reduce(0, +)) / Double(durations.count),
                        minValue: durations.min() ?? 1,
                        maxValue: durations.max() ?? 10
                    )
                    .frame(height: 250)
                    .padding()
                }
                
                // Stats
                VStack(spacing: 16) {
                    HStack {
                        Text("Min: \(minCycleLength) d")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Max: \(maxCycleLength) d")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.teal.opacity(0.3))
                    .cornerRadius(12)
                }
                .padding()
                
                // Period history list
                List {
                    ForEach(periods.sorted(by: { $0.startDate > $1.startDate })) { period in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("First Day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(period.startDate, formatter: listDateFormatter)
                                    .font(.body)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("Duration")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(period.duration) d")
                                    .font(.body)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Cycle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let cycleLength = getCycleLength(for: period) {
                                    Text("\(cycleLength) d")
                                        .font(.body)
                                } else {
                                    Text("N/A")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private func getCycleLength(for period: Period) -> Int? {
        let sortedPeriods = periods.sorted { $0.startDate < $1.startDate }
        guard let index = sortedPeriods.firstIndex(where: { $0.id == period.id }),
              index > 0 else {
            return nil
        }
        
        let previousPeriod = sortedPeriods[index - 1]
        return Calendar.current.dateComponents([.day], from: previousPeriod.startDate, to: period.startDate).day
    }
    
    private var chartDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
    
    private var listDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
}

struct CycleHistoryChartView: View {
    // Your exact cycle lengths: [32, 29, 30, 25, 30, 30]
    let cycleLengths = [32, 29, 30, 25, 30, 30]
    let dates = ["Feb 15", "Mar 16", "Apr 15", "May 10", "Jun 9", "Jul 9"]
    
    var averageCycleLength: Double {
        Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let chartHeight = height - 60 // More space for date labels
            let chartWidth = width - 40
            
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.teal)
                
                VStack(spacing: 0) {
                    // Chart area
                    ZStack {
                        // Y-axis grid lines and labels (20-40 range)
                        ForEach([20, 24, 28, 32, 36, 40], id: \.self) { value in
                            let yPos = chartHeight - (CGFloat(value - 20) / 20.0 * chartHeight)
                            
                            // Grid line
                            Path { path in
                                path.move(to: CGPoint(x: 30, y: yPos))
                                path.addLine(to: CGPoint(x: chartWidth + 30, y: yPos))
                            }
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            
                            // Label
                            Text("\(value)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .position(x: 15, y: yPos)
                        }
                        
                        // Average line
                        let avgY = chartHeight - (CGFloat(averageCycleLength - 20) / 20.0 * chartHeight)
                        Path { path in
                            path.move(to: CGPoint(x: 30, y: avgY))
                            path.addLine(to: CGPoint(x: chartWidth + 30, y: avgY))
                        }
                        .stroke(Color.orange, lineWidth: 2)
                        
                        Text("\(Int(averageCycleLength)) d avg")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                            .position(x: chartWidth - 20, y: avgY - 15)
                        
                        // Data points
                        ForEach(0..<cycleLengths.count, id: \.self) { index in
                            let cycleLength = cycleLengths[index]
                            let x = 30 + (CGFloat(index) / CGFloat(cycleLengths.count - 1)) * chartWidth
                            let y = chartHeight - (CGFloat(cycleLength - 20) / 20.0 * chartHeight)
                            
                            // Vertical line from average to data point
                            Path { path in
                                path.move(to: CGPoint(x: x, y: avgY))
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            .stroke(Color.white, lineWidth: 2)
                            
                            // Data point circle
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                                .position(x: x, y: y)
                            
                            // Value label above point
                            Text("\(cycleLength)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                                .position(x: x, y: y - 15)
                        }
                    }
                    .padding(.top, 20)
                    
                    // X-axis date labels (moved outside chart area for better visibility)
                    HStack(spacing: 0) {
                        ForEach(0..<dates.count, id: \.self) { index in
                            Text(dates[index])
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 10)
                }
            }
        }
    }
}

struct CycleLineChart: View {
    let data: [Int]
    let averageValue: Double
    let minValue: Int
    let maxValue: Int
    
    var body: some View {
        ZStack {
            // Background
            Color.teal.opacity(0.1)
            
            // Grid lines and chart
            VStack(spacing: 0) {
                // Y-axis labels and grid
                HStack {
                    VStack(alignment: .leading) {
                        ForEach([10, 8, 6, 4, 2], id: \.self) { value in
                            HStack {
                                Text("\(value)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 20, alignment: .trailing)
                                
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 0.5)
                            }
                            .frame(height: 40)
                        }
                    }
                }
                
                // Chart area with data points
                GeometryReader { geometry in
                    let chartWidth = geometry.size.width - 30
                    let chartHeight = geometry.size.height - 40
                    
                    ZStack {
                        // Average line
                        Rectangle()
                            .fill(Color.orange)
                            .frame(height: 2)
                            .position(x: chartWidth / 2, y: chartHeight * (1 - (averageValue - 2) / (10 - 2)))
                        
                        Text("\(Int(averageValue)) d avg")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .position(x: chartWidth - 40, y: chartHeight * (1 - (averageValue - 2) / (10 - 2)))
                        
                        // Data points
                        ForEach(0..<data.count, id: \.self) { index in
                            let value = data[index]
                            let x = 30 + (Double(index) / Double(max(data.count - 1, 1))) * chartWidth
                            let y = chartHeight * (1 - (Double(value) - 2) / (10 - 2))
                            
                            // Vertical line
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: abs(y - chartHeight * (1 - (averageValue - 2) / (10 - 2))))
                                .position(x: x, y: (y + chartHeight * (1 - (averageValue - 2) / (10 - 2))) / 2)
                            
                            // Data point
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                    }
                }
            }
        }
        .background(Color.teal)
        .cornerRadius(12)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ContentView()
}