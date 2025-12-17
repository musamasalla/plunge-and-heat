//
//  SessionDetailView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - Session Detail View

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager = DataManager.shared
    
    let session: Session
    
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with type icon
                        headerSection
                        
                        // Main details
                        detailsSection
                        
                        // Photo if available
                        if let photoData = session.photoData,
                           let uiImage = UIImage(data: photoData) {
                            photoSection(uiImage: uiImage)
                        }
                        
                        // Notes if available
                        if let notes = session.notes, !notes.isEmpty {
                            notesSection(notes: notes)
                        }
                        
                        // Delete button
                        deleteButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(session.type.primaryColor)
                }
            }
            .alert("Delete Session?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteSession()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(session.type.gradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: session.type.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(session.type.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(session.dateFormatted)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                Text(session.timeOfDay)
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(spacing: 12) {
            // Duration
            DetailRow(
                icon: "clock.fill",
                label: "Duration",
                value: session.durationFormatted,
                color: session.type.primaryColor
            )
            
            Divider()
                .background(AppTheme.textTertiary.opacity(0.3))
            
            // Temperature
            if let temp = session.temperatureFormatted {
                DetailRow(
                    icon: "thermometer.medium",
                    label: "Temperature",
                    value: temp,
                    color: session.type == .coldPlunge ? .cyan : .orange
                )
                
                Divider()
                    .background(AppTheme.textTertiary.opacity(0.3))
            }
            
            // Heart Rate
            if let hr = session.heartRate {
                DetailRow(
                    icon: "heart.fill",
                    label: "Heart Rate",
                    value: "\(hr) BPM",
                    color: .red
                )
                
                Divider()
                    .background(AppTheme.textTertiary.opacity(0.3))
            }
            
            // Protocol
            if let protocolUsed = session.protocolUsed {
                DetailRow(
                    icon: "list.bullet.clipboard",
                    label: "Protocol",
                    value: protocolUsed,
                    color: .purple
                )
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusLarge)
    }
    
    // MARK: - Photo Section
    
    private func photoSection(uiImage: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo")
                .font(.headline)
                .foregroundColor(.white)
            
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
        }
    }
    
    // MARK: - Notes Section
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(AppTheme.textSecondary)
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(notes)
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusMedium)
        }
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button(action: {
            showingDeleteAlert = true
        }) {
            HStack {
                Image(systemName: "trash")
                Text("Delete Session")
            }
            .font(.headline)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
        }
    }
    
    // MARK: - Actions
    
    private func deleteSession() {
        dataManager.deleteSession(session)
        HapticFeedback.warning()
        dismiss()
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(label)
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    SessionDetailView(session: Session.sampleCold)
}
