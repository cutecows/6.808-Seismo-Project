//
//  ViewController.swift
//  audiovideo
//
//  Created by Soumya Ram on 4/21/20.
//  Copyright © 2020 Soumya Ram. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

//TODO:
//1) automate play beeps
//1.5) test
//2) delete large variable (audio array)
//3) check if accelerometer needs to be negated
//4) take timestamp at first acc sample instead of for each one --> calculate times


extension String {

       func stringByAppendingPathComponent(path: String) -> String {

       let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }
}

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate{
let motion = CMMotionManager()
var audioPlayer : AVAudioPlayer!
var audioRecorder : AVAudioRecorder!
var motionManager = CMMotionManager()
var timer: Timer!
var Beeptimer: Timer!
var accelerationList:[Double] = []
var accTimestamp:[Double] = []
var runCount = 0


@IBOutlet var recordButton: UIButton!
    //@IBOutlet var playButton: UIButton!
//@IBOutlet var stopButton: UIButton!
    
override func viewDidLoad() {
    super.viewDidLoad()

    self.recordButton.isEnabled = true
    
    //let interval = 0.1
   // self.motion.deviceMotionUpdateInterval = interval
    //self.motion.startDeviceMotionUpdates()
    //self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: handleTick)

    


}

override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
}

    func handleTick(timer: Timer) -> Void {
        guard let acceleration = self.motion.deviceMotion?.userAcceleration else {
            return
        }
        
        self.accelerationList.append(acceleration.z)
        self.accTimestamp.append(self.audioRecorder.currentTime)
    }
    

    
    func playButton(timer: Timer) {
        //let dispatchQueue = DispatchQueue.global(qos:     .userInteractive)

           //dispatchQueue.async(execute: {
            
            //this button exists for quick debugging --> once the sound works the sound can easily be played automatically
            //problem: sound plays in simulator but not on iphone. iphone does not throw an error.
            AudioServicesPlayAlertSound(SystemSoundID(1322))
            //things tried:
            //AudioServicesPlaySystemSoundWithCompletion(1322, {AudioServicesDisposeSystemSoundID(1322)})
            //AudioServicesPlayAlertSound(SystemSoundID(1322))
            //AudioServicesPlaySystemSound(SystemSoundID(1016))
            self.runCount+=1
            if self.runCount==3 {
                self.Beeptimer.invalidate()
                //do {
                //    sleep(1)
                //}
                self.stopButton()
                
            }
          // });
    }
    


    func stopButton() {
        if let player = self.audioPlayer{
               player.stop()
           }

           if let record = self.audioRecorder{

               record.stop()

               let session = AVAudioSession.sharedInstance()
               do{
                   try session.setActive(false)
               }
               catch{
                   print("\(error)")
               }
           }
        self.timer.invalidate()
        let audioArray = self.loadAudioSignal(audioURL: NSURL(string: self.audioFilePath())!)
        let audioSignal = audioArray.signal
        let audioRate = 1/audioArray.rate
        var max_index_audio = self.findPeaksFloat(audioSignal)
        max_index_audio.sort()
        var max_index_times:[Double] = []
        for i in max_index_audio {
            max_index_times.append(Double(i)*audioRate)
        }
            
        
        var max_index_acc = self.findPeaksDouble(self.accelerationList)
        max_index_acc.sort()
        var acc_times:[Double] = []

        for i in max_index_acc {
            acc_times.append(self.accTimestamp[i])
        }
        print("CHECK IF POSITIVE OR NEGATIVE")
        print(self.accelerationList)
        print("ACCELERATION PEAK TIMES BELOW")
        print(acc_times)
        print("AUDIO PEAK TIMES BELOW")
        print(max_index_times)
        
    }
    func findPeaksFloat(_ array: Array<Float>) -> Array<Int> {
        var max = Float(-1000000.0)
        var maxPos = -1
        var secMax = Float(-1000000.0)
        var secMaxPos = -1
        var thirdMax = Float(-1000000.0)
        var thirdMaxPos = -1
        var index = 0
        var index_list:[Int] = []
        for value in array {
            if value > max {
                max = value
                maxPos = index
            } else if value > secMax {
                secMax = value
                secMaxPos = index
            } else if value > thirdMax {
                thirdMax = value
                thirdMaxPos = index
            }
            
            index+=1
        }
        index_list.append(maxPos)
        index_list.append(secMaxPos)
        index_list.append(thirdMaxPos)
        
        return index_list
    }
    func findPeaksDouble(_ array: Array<Double>) -> Array<Int> {
        var max = -1000000.0
        var maxPos = -1
        var secMax = -1000000.0
        var secMaxPos = -1
        var thirdMax = -1000000.0
        var thirdMaxPos = -1
        var index = 0
        var index_list:[Int] = []
        for value in array {
            if value > max {
                max = value
                maxPos = index
            } else if value > secMax {
                secMax = value
                secMaxPos = index
            } else if value > thirdMax {
                thirdMax = value
                thirdMaxPos = index
            }
            
            index+=1
        }
        index_list.append(maxPos)
        index_list.append(secMaxPos)
        index_list.append(thirdMaxPos)
        
        return index_list
    }


    @IBAction func recordButtonHere(_ sender:UIButton) {
        let session = AVAudioSession.sharedInstance()

               do{
                   try session.setCategory(AVAudioSession.Category.playAndRecord)
                   try session.setActive(true)
                   session.requestRecordPermission({ (allowed : Bool) -> Void in

                       if allowed {
                           self.startRecording()
                       }
                       else{
                           print("We don't have request permission for recording.")
                       }
                   })
               }
               catch{
                   print("\(error)")
               }
    }
    
   func recordButtonHereOld(_ sender: UIButton) {
        let session = AVAudioSession.sharedInstance()

        do{
            try session.setCategory(AVAudioSession.Category.playAndRecord)
            try session.setActive(true)
            session.requestRecordPermission({ (allowed : Bool) -> Void in

                if allowed {
                    self.startRecording()
                }
                else{
                    print("We don't have request permission for recording.")
                }
            })
        }
        catch{
            print("\(error)")
        }
    }

    func startRecording(){

        //self.playButton.isEnabled = true
        self.recordButton.isEnabled = true


        do{

            let fileURL = NSURL(string: self.audioFilePath())!
            self.audioRecorder = try AVAudioRecorder(url: fileURL as URL, settings: self.audioRecorderSettings() as! [String : AnyObject])

            if let recorder = self.audioRecorder{
                recorder.delegate = self

                if recorder.record() && recorder.prepareToRecord(){
                    print("Audio recording started successfully")
                    let interval = 0.1
                    self.motion.deviceMotionUpdateInterval = interval
                    self.motion.startDeviceMotionUpdates()
                    self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: handleTick)
                    self.Beeptimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: playButton)
                    
                }
            }
        }
        catch{
            print("\(error)")
        }
    }
    
    func loadAudioSignal(audioURL: NSURL) -> (signal: [Float], rate: Double, frameCount: Int)
    {
        let file = try! AVAudioFile(forReading: audioURL as URL)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
        let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: UInt32(file.length))
        try! file.read(into: buf!) // You probably want better error handling
        let floatArray = Array(UnsafeBufferPointer(start: buf!.floatChannelData![0], count:Int(buf!.frameLength)))
        return (signal: floatArray, rate: file.fileFormat.sampleRate, frameCount: Int(file.length))
     }

    
func audioFilePath() -> String{

    let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    let filePath = path.stringByAppendingPathComponent(path: "test.caf") as String
    print("FILE PATH BELOW")
    print(filePath)
    return filePath
}

func audioRecorderSettings() -> NSDictionary{

    let settings = [AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC)), AVSampleRateKey : NSNumber(value: Float(16000.0)), AVNumberOfChannelsKey : NSNumber(value: 1), AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue))]

    return settings as NSDictionary
}

//MARK: AVAudioPlayerDelegate methods

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {

    if flag == true{
        print("Player stops playing successfully")
    }
    else{
        print("Player interrupted")
    }

    self.recordButton.isEnabled = true
    //self.playButton.isEnabled = true
    //self.stopButton.isEnabled = true
}

//MARK: AVAudioRecorderDelegate methods

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {

    if flag == true{
        print("Recording stops successfully")
    }
    else{
        print("Stopping recording failed")
    }

    //self.playButton.isEnabled = true
    self.recordButton.isEnabled = true
    //self.stopButton.isEnabled = true
}
}


