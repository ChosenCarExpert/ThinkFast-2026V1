//
//  SettingsView.swift
//  DrowsyDetectDemo
//
//  Created by Shivank Sinha on 3/12/26.
//

import SwiftUI

struct SettingsView: View {
    
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
                
                Toggle("Play Audio on Car Bluetooth", isOn: $cameraVM.playOnCarAudio)
                    .padding()
                    .font(.headline)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                
                Toggle("Notify Parent", isOn: $cameraVM.notifyParent)
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
