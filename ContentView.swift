//
//  ContentView.swift
//  DrowsyDetectDemo
//
//  Created by Shivank Sinha on 3/11/26.
//

import SwiftUI
import AVFoundation

// MARK: - Content View
struct ContentView: View {
    
    @StateObject private var cameraVM = CameraViewModel()
    @State private var isMonitoring = false
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            if isMonitoring {
                // Camera monitoring screen
                DriverMonitoringView(cameraVM: cameraVM) {
                    cameraVM.stopCamera()
                    isMonitoring = false // Back to home
                }
                
            } else if showingSettings {
                // Settings page
                DriverSettingsView(cameraVM: cameraVM){
                    showingSettings = false // Back to home
                }
                
            } else {
                // Home screen
                HomeView {
                    cameraVM.setupCamera()
                    isMonitoring = true
                } settingsAction: {
                    showingSettings = true
                }
            }
        }
    }
}

// MARK: - Home Screen View
struct HomeView: View {
    
    var startMonitoring: () -> Void
    var settingsAction: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 60) {
                
                // Title & Icon
                VStack(spacing: 15) {
                    Text("Driver Drowsiness Detection")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(radius: 5)
                    
                    Image(systemName: "eye.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
                
                // Buttons
                VStack(spacing: 25) {
                    Button {
                        startMonitoring()
                    } label: {
                        Text("Start Eye Monitoring")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .frame(width: 250, height: 55)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 5)
                    }
                    
                    Button {
                        settingsAction()
                    } label: {
                        Text("Settings")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .frame(width: 250, height: 55)
                            .background(Color.gray.opacity(0.8))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 5)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
}

// MARK: - Monitoring View
struct DriverMonitoringView: View {
    
    @ObservedObject var cameraVM: CameraViewModel
    var onBack: () -> Void
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: cameraVM.session)
                .ignoresSafeArea()
            
            VStack {
                // Top Title + Back Button
                HStack(spacing: 5) {
                    Button(action: { onBack() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 50, weight: .bold))
                            .font(.title)
                            .padding(5)
                            .background(.ultraThinMaterial)
                            .cornerRadius(14)
                            .shadow(radius: 5)
                    }
                    
                    Text("Driver Monitor")
                        .font(.system(size: 30, weight: .bold))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(15)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .shadow(radius: 5)
                    Spacer()
                  

                }
                .padding(.top, 50)
                .padding(.horizontal)
                
                Spacer()
                
                // Driver Status Indicator
                HStack {
                    Circle()
                        .fill(cameraVM.showAlert ? Color.red : Color.green)
                        .frame(width: 14, height: 14)
                    
                    Text(cameraVM.showAlert ? "Status: ⚠️" : "Status: Awake")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.bottom, 40)
                
                // Alert Message
                if cameraVM.showAlert {
                    Text("⚠️ \(cameraVM.alertType) DETECTED")
                        .foregroundColor(cameraVM.alertType == "Phone Tilt" ? .orange : .red)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(radius: 6)
                        .padding(.bottom, 30)
                }
            }
        }
        .animation(.easeInOut, value: cameraVM.showAlert)
    }
}

// MARK: - Settings View
struct DriverSettingsView: View {
    
    @ObservedObject var cameraVM: CameraViewModel
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            
            // MARK: - Header
            HStack(spacing: 12) {
                Button(action: { onBack() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                
                Text("Settings")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
            }
            .padding(.top, 50)
            .padding(.horizontal)
            
            // MARK: - Toggles
            VStack(spacing: 20) {
                Toggle("Vibration Alert", isOn: $cameraVM.vibrationEnabled)
                    .padding()
                    .font(.headline)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                
                Toggle("Sound Alert", isOn: $cameraVM.soundEnabled)
                    .padding()
                    .font(.headline)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                
                Toggle("Detect sudden motion", isOn: $cameraVM.jerkDetectionEnabled)
                    .padding()
                    .font(.headline)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                Toggle("Play Audio on Bluetooth", isOn: $cameraVM.playOnCarAudio)
                    .padding()
                    .font(.headline)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                
                Toggle("Notify Parents/Gaurdians", isOn: $cameraVM.notifyParent)
                    .padding()
                    .font(.headline)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                
        
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

