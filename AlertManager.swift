//
//  AlertManager.swift
//  DrowsyDetectDemo
//
//  Created by Shivank Sinha on 3/11/26.
//

import Foundation
import AVFoundation
import AudioToolbox

class AlertManager {
    var player: AVAudioPlayer?
    
    func playSound() {
        if let url = Bundle.main.url(forResource: "alert", withExtension: "mp3") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.play()
        }
    }
    
    func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
