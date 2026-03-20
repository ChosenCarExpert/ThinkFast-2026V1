//
//  MotionDetector.swift
//  DrowsyDetectDemo
//
//  Created by Shivank Sinha on 3/11/26.
//

import Foundation
import CoreMotion

class MotionDetector {
    let motion = CMMotionManager()
    
    func startMotion() {
        motion.deviceMotionUpdateInterval = 0.2
        motion.startDeviceMotionUpdates(to: .main) { data, error in
            guard let data = data else { return }
            if abs(data.attitude.roll) > 0.5 {
                print("Phone tilted! Could indicate drowsiness.")
            }
        }
    }
}
