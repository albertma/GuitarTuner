//
//  UkuleleToner.swift
//  GuitarTuner
//
//  Created by albertma on 2024/11/3.
//
func UkuleleTunerConfig() -> TonesConfig{
    //setup Ukulele
    var tones:[Tone] = []
    tones.append(Tone(pitch: "G4", name: "SOL", freq:392.0, detail: "Sol of C"))
    tones.append(Tone(pitch: "C4", name: "DO", freq: 261, detail: "Do of C"))
    tones.append(Tone(pitch: "E4", name: "MI", freq: 329.63, detail: "MI of C"))
    tones.append(Tone(pitch: "A4", name: "LA", freq: 440, detail: "La of C"))
    let ukuleleTonesConfig = TonesConfig(name:"Ukulele", startFreq: 200, endFreq: 500, tones:tones, threshold: 5.0)
    return ukuleleTonesConfig
}

