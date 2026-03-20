//
//  MonitoringView.swift
//  DrowsyDetectDemo
//
//  Created by Shivank Sinha on 3/12/26.
//

import SwiftUI
import Foundation

struct MonitoringView: View {

    @ObservedObject var cameraVM: CameraViewModel
    var onBack: () -> Void // closure to handle back button action

    var body: some View {

        ZStack {

            // Camera
            CameraPreview(session: cameraVM.session)
                .ignoresSafeArea()

            VStack {

                // TOP TITLE + BACK BUTTON
                HStack(spacing: 12) {

                    // Back button
                    Button(action: {
                        cameraVM.stopCamera() // stop detection and alerts
                        onBack()              // notify parent to go back
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 38, weight: .bold)) // bigger chevron
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(14)
                            .shadow(radius: 5)
                    }

                    Text("Driver Monitor")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .shadow(radius: 5)

                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal)

                Spacer()

                // DRIVER STATUS INDICATOR
                HStack {

                    Circle()
                        .fill(cameraVM.showAlert ? Color.red : Color.green)
                        .frame(width: 14, height: 14)

                    Text(cameraVM.showAlert ? "Status: Drowsy" : "Status: Awake")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                }
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.bottom, 40)

                // ALERT MESSAGE
                if cameraVM.showAlert {

                    Text("⚠️ DROWSINESS ALERT!")
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
