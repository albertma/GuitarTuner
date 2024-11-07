//
//  Tuner.swift
//  GuitarTuner
//
//  Created by albertma on 2024/11/3.
//
import AVFoundation
import SwiftUI


enum TunerCode{
    case tunningStarted   // start to listening sound.
    case tunningStopped   // stop to listening sound
    case toTunning        // valid string sound arrival, need to tunning it
    case tunningDone      // one tone is tunned done.
    case tunningError
    var description: String {
          switch self {
          case .toTunning:
            return "Need to tunning"
          case .tunningDone:
            return "Tunning was Done"
          case .tunningError:
            return "Tunning got error"
          case .tunningStarted:
            return "Tuning was started"
          case .tunningStopped:
            return "Tunning was stopped"
          }
    }
}

struct TunningResult{
    let tunerCode:TunerCode
    let tone:Tone?
    let currentFrequence:Float
    var diffFreq:Double
    init(tunerCode: TunerCode, tone:Tone?, currentFrequence:Float) {
        self.tunerCode = tunerCode
        self.tone = tone
        self.currentFrequence = currentFrequence
        self.diffFreq = Double(currentFrequence) - Double(tone?.freq ?? 0.0)
    }
    var description: String {
        return "\(tunerCode) has tone: \(String(describing: tone?.description)), currentFrequence:\(self.currentFrequence), diffFreq:\(self.diffFreq)"
    }
}

struct Tone{
    let pitch:String
    let name:String
    let freq:Float
    let detail:String
    init(pitch: String, name: String, freq: Float, detail: String) {
        self.pitch = pitch
        self.name = name
        self.freq = freq
        self.detail = detail
    }
    var description: String{
        return "name:\(self.name), pitch:\(self.pitch), freq:\(self.freq), detail:\(self.detail)"
    }
}

struct TonesConfig{
    let name:String
    var tones :[Tone]?
    let threshold: Float
    let startFreq: Float
    let endFreq: Float
    init(name: String, startFreq:Float, endFreq:Float, tones: [Tone], threshold: Float) {
        self.name = name
        self.startFreq = startFreq
        self.endFreq = endFreq
        self.tones = tones
        self.threshold = threshold
    }
    
}


class Tuner:ObservableObject{
    @Published var result: TunningResult
    
    let toneEngine = ToneEngine()
    
    var config:TonesConfig?
    
    init() {
        self.result = TunningResult(tunerCode: TunerCode.tunningStopped, tone: nil, currentFrequence: 0.0)
        self.config = nil
    }
    
    func startTunning(config: TonesConfig) -> Bool{
        logger.logWithDetails("Start to capture the audio from microphone.")
        self.config = config
        let isStarted = toneEngine.startCapture(){ state, freq, volume  in
            if freq > config.startFreq
                && freq < config.endFreq
                && volume > 40{
                logger.logWithDetails("Got audio analysis state: \(state.rawValue) freq: \(freq), vol:\(volume)")
                DispatchQueue.main.async {
                    self.result = self.createTunningResult(by: state, freq: freq)
                }
            }else{
                logger.logWithDetails("Got invalid audio freq: \(freq), vol:\(volume)")
            }
        }
        return isStarted
    }
    
    func stopTunning(){
        toneEngine.stopCapture()
        self.result = TunningResult(tunerCode: TunerCode.tunningStopped, tone: nil, currentFrequence: 0.0)
    }
    
    private func createTunningResult(by state:EngineState, freq:Float) -> TunningResult{
       
        if(state == EngineState.AudioFrequencyDone){
            if(freq >= self.config!.startFreq && freq <= self.config!.endFreq){
                logger.logWithDetails("Frequence: \(freq) is between \(self.config!.startFreq) and \(self.config!.endFreq)")
                var minDiff:Float = 1000000.0
                var nearestTone:Tone?
                for tone in self.config!.tones!{
                    let diff = abs(freq - tone.freq)
                    if diff < minDiff{
                        minDiff = diff
                        nearestTone = tone
                    }
                }
                if(minDiff <= self.config!.threshold){
                    logger.logWithDetails("Frequence: \(freq) is near target frequence zone, well done.")
                    let result = TunningResult(tunerCode: TunerCode.tunningDone, tone:nearestTone!, currentFrequence: freq)
                    return result
                }else{
                    logger.logWithDetails("Frequence: \(freq) is far away from target frequence zone, need to tunning.")
                    let result = TunningResult(tunerCode: TunerCode.toTunning, tone:nearestTone!, currentFrequence: freq)
                    return result
                }
            }else{
                logger.logWithDetails("Frequence: \(freq) is invalid")
                let result = TunningResult(tunerCode: TunerCode.tunningStarted, tone:nil ,currentFrequence: freq)
                return result
            }
            
        }else if(state == EngineState.AudioFrequencyAnalyseError){
            logger.logWithDetails("Engine state : \(state.rawValue)", level: .error)
            let result = TunningResult(tunerCode: TunerCode.tunningError, tone:nil, currentFrequence: freq)
            return result
        }else if(state == EngineState.AudioCaptureNull){
            logger.logWithDetails("Engine state : \(state.rawValue)", level: .error)
            let result = TunningResult(tunerCode: TunerCode.tunningError, tone:nil, currentFrequence: freq)
            return result
        }else{
            let result = TunningResult(tunerCode: TunerCode.tunningError, tone:nil, currentFrequence: freq)
            return result
        }
    }
    
}
