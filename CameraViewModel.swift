//
//  CameraViewModel.swift
//  DrowsyDetectDemo
//
//  Created by Shivank Sinha on 3/11/26.
//
import Foundation
import AVFoundation
import SwiftUI
import Combine
import Vision
import AudioToolbox
import CoreMotion

class CameraViewModel: NSObject, ObservableObject {

    @Published var alertType = "None"
    @Published var alertActive = false
    @Published var isRunning = false
    @Published var showAlert = false
    @Published var playOnCarAudio = false
    @Published var leftEyePoints:[CGPoint] = []
    @Published var rightEyePoints:[CGPoint] = []
    @Published var vibrationEnabled = true
    @Published var soundEnabled = true
    @Published var notifyParent = false
    @Published var jerkDetectionEnabled = true

    var headDownStartTime: Date?
    var headBackStartTime: Date?
    var headTurnStartTime: Date?
    var gazeStartTime: Date?
    var jerkStartTime: Date?
    var eyesClosedStartTime: Date?

    var frameCount = 0
    var vibrationTimer: Timer?
    var alertHoldTimer: Timer?

    var faceDetected = false
    var earFrames = 0
    var lastAlertTime = Date()

    let session = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    let motionManager = CMMotionManager()

    private var alertPlayer: AVAudioPlayer?

    override init(){
        super.init()
        setupAudio()
    }

    func setupAudio(){

        if let url = Bundle.main.url(
            forResource:"alert",
            withExtension:"mp3"){

            alertPlayer = try? AVAudioPlayer(contentsOf:url)
            alertPlayer?.prepareToPlay()
        }
    }

    // JERK DETECTION (unchanged)
    func startMotionDetection(){

        if motionManager.isDeviceMotionAvailable{

            motionManager.deviceMotionUpdateInterval = 0.1

            motionManager.startDeviceMotionUpdates(to:.main){

                motion,error in

                guard let motion = motion else {return}

                let accel = motion.userAcceleration

                let jerk =
                sqrt(accel.x*accel.x +
                     accel.y*accel.y +
                     accel.z*accel.z)

                print("Jerk:",jerk)

                if self.jerkDetectionEnabled &&
                   jerk > 1.7 {

                    if self.jerkStartTime == nil{
                        self.jerkStartTime = Date()
                    }

                    let elapsed =
                    Date().timeIntervalSince(
                        self.jerkStartTime!)

                    if elapsed > 0.35{

                        print("Sudden motion detected")

                        if !self.alertActive{

                            self.alertType =
                            "Sudden Motion"

                            self.triggerAlert()
                        }
                    }

                }else{

                    self.jerkStartTime = nil
                }
            }
        }
    }

    func stopCamera(){

        if session.isRunning{

            session.stopRunning()

            isRunning = false

            resetAlert()

            motionManager.stopDeviceMotionUpdates()
        }
    }

    func setupCamera(){

        session.beginConfiguration()

        session.sessionPreset = .high

        guard let camera =
        AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for:.video,
            position:.front)
        else{return}

        let input =
        try? AVCaptureDeviceInput(device:camera)

        if let input=input{

            if session.canAddInput(input){
                session.addInput(input)
            }
        }

        videoOutput.setSampleBufferDelegate(
            self,
            queue:DispatchQueue(label:"frames"))

        if session.canAddOutput(videoOutput){
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()

        DispatchQueue.global().async{

            self.session.startRunning()

            DispatchQueue.main.async{

                self.isRunning = true

                self.startMotionDetection()
            }
        }
    }

    func detectEyes(pixelBuffer:CVPixelBuffer){

        let request =
        VNDetectFaceLandmarksRequest{

            request,error in

            guard let results =
            request.results as?
            [VNFaceObservation]
            else{

                print("No face detected")

                self.faceDetected = false

                return
            }

            self.faceDetected = true

            print("Faces detected:",results.count)

            for face in results{

                let x = face.boundingBox.midX
                let y = face.boundingBox.midY

                print("Head X:",x)
                print("Head Y:",y)

                guard let leftEye =
                face.landmarks?.leftEye,

                let rightEye =
                face.landmarks?.rightEye
                else{continue}

                let left =
                leftEye.normalizedPoints.map{
                    CGPoint(x:$0.x,y:1-$0.y)
                }

                let right =
                rightEye.normalizedPoints.map{
                    CGPoint(x:$0.x,y:1-$0.y)
                }

                print("Left eye points:",left)
                print("Right eye points:",right)

                self.leftEyePoints = left
                self.rightEyePoints = right

                func EAR(_ pts:[CGPoint])->CGFloat{

                    let A =
                    hypot(pts[1].x-pts[5].x,
                          pts[1].y-pts[5].y)

                    let B =
                    hypot(pts[2].x-pts[4].x,
                          pts[2].y-pts[4].y)

                    let C =
                    hypot(pts[0].x-pts[3].x,
                          pts[0].y-pts[3].y)

                    return (A+B)/(2*C)
                }

                let avgEAR =
                (EAR(left)+EAR(right))/2

                print("Average EAR:",avgEAR)

                // HEAD FORWARD

                if y < 0.30{

                    if self.headDownStartTime == nil{
                        self.headDownStartTime = Date()
                    }

                    let elapsed =
                    Date().timeIntervalSince(
                        self.headDownStartTime!)

                    print("Head down time:",elapsed)

                    if elapsed > 2{

                        self.alertType="Drowsiness"

                        self.triggerAlert()
                    }

                }else{
                    self.headDownStartTime = nil
                }

                // HEAD BACK

                if y > 0.75{

                    if self.headBackStartTime == nil{
                        self.headBackStartTime = Date()
                    }

                    let elapsed =
                    Date().timeIntervalSince(
                        self.headBackStartTime!)

                    print("Head back time:",elapsed)

                    if elapsed > 2{

                        self.alertType="Driver Unresponsive"

                        self.triggerAlert()
                    }

                }else{
                    self.headBackStartTime = nil
                }

                // HEAD TURN

                if x < 0.20 || x > 0.80{

                    if self.headTurnStartTime == nil{
                        self.headTurnStartTime = Date()
                    }

                    let elapsed =
                    Date().timeIntervalSince(
                        self.headTurnStartTime!)

                    print("Head turn time:",elapsed)

                    if elapsed > 2{

                        self.alertType="Driver Distracted"

                        self.triggerAlert()
                    }

                }else{
                    self.headTurnStartTime = nil
                }

                // EYES CLOSED

                if avgEAR < 0.15{

                    self.earFrames += 1

                    if self.earFrames < 10{
                        return
                    }

                    if self.eyesClosedStartTime == nil{
                        self.eyesClosedStartTime = Date()
                    }

                    let elapsed =
                    Date().timeIntervalSince(
                        self.eyesClosedStartTime!)

                    print("Eyes closed time:",elapsed)

                    if elapsed > 2{

                        self.alertType="Drowsiness"

                        self.triggerAlert()
                    }

                }else{

                    self.earFrames = 0

                    self.eyesClosedStartTime = nil
                }

                // EYE GAZE

                let eyeY =
                (left[1].y +
                 left[4].y +
                 right[1].y +
                 right[4].y)/4

                print("Eye gaze:",eyeY)

                if eyeY < 0.25 ||
                   eyeY > 0.75{

                    if self.gazeStartTime == nil{
                        self.gazeStartTime = Date()
                    }

                    let elapsed =
                    Date().timeIntervalSince(
                        self.gazeStartTime!)

                    print("Gaze time:",elapsed)

                    if elapsed > 2{

                        self.alertType="Driver Distracted"

                        self.triggerAlert()
                    }

                }else{
                    self.gazeStartTime = nil
                }
            }
        }

        let handler =
        VNImageRequestHandler(
            cvPixelBuffer:pixelBuffer,
            orientation:.leftMirrored)

        try? handler.perform([request])
    }

    func triggerAlert(){

        let cooldown =
        Date().timeIntervalSince(lastAlertTime)

        if cooldown < 2{
            return
        }

        lastAlertTime = Date()

        alertActive = true
        showAlert = true

        print("ALERT:",alertType)

        alertHoldTimer?.invalidate()

        alertHoldTimer =
        Timer.scheduledTimer(
            withTimeInterval:5,
            repeats:false){

            _ in

            self.resetAlert()
        }

        if vibrationEnabled{

            vibrationTimer =
            Timer.scheduledTimer(
                withTimeInterval:0.6,
                repeats:true){

                _ in

                AudioServicesPlaySystemSound(
                    kSystemSoundID_Vibrate)
            }

            DispatchQueue.main.asyncAfter(
                deadline:.now()+5){

                self.vibrationTimer?.invalidate()
            }
        }

        if soundEnabled{
            alertPlayer?.play()
        }
    }

    func resetAlert(){

        alertHoldTimer?.invalidate()

        alertActive = false

        showAlert = false

        vibrationTimer?.invalidate()

        alertType = "None"
    }

    func routeAudioToCar(){
        print("placeholder")
    }

    func sendParentAlert(){
        print("placeholder")
    }
}

extension CameraViewModel:
AVCaptureVideoDataOutputSampleBufferDelegate{

    func captureOutput(
        _ output:AVCaptureOutput,
        didOutput sampleBuffer:CMSampleBuffer,
        from connection:AVCaptureConnection){

        frameCount += 1

        print("Frame:",frameCount)

        guard let buffer =
        CMSampleBufferGetImageBuffer(sampleBuffer)
        else{return}

        detectEyes(pixelBuffer:buffer)
    }
}
