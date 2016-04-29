//
//  Speak.swift
//  Open Ascent
//
//  Created by Tobias DM on 25/08/14.
//  Copyright (c) 2014 Open Ascent. All rights reserved.
//

import UIKit

import AVFoundation.AVAudioSession
import AVFoundation.AVSpeechSynthesis


public class Speak: NSObject {
    
    private let audioSession: AVAudioSession = {
        var audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: .DuckOthers)
        } catch {
            // TODO: Handle error
        }
        return audioSession
    }()
    private let synth: AVSpeechSynthesizer
    
    public var language: String = "en-US"

    override init () {
        synth = AVSpeechSynthesizer()
        
        super.init()
        
        synth.delegate = self
    }
}


extension Speak { // AVAudioSession

    private func setAudioSessionActive(beActive: Bool) {
        do {
            try audioSession.setActive(beActive)
            print("Setting AVAudiosession active: ", beActive)
        } catch let error as NSError {
            print("Setting AVAudiosession state failed: \(error.description)")
        }
    }

    public func speak(string: String) {
        let utterance = AVSpeechUtterance(string: string)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate / 2
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        synth.speakUtterance(utterance)
    }
}


extension Speak: AVSpeechSynthesizerDelegate {
    
    public func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didStartSpeechUtterance utterance: AVSpeechUtterance!) {
//        setAudioSessionActive(true)
    }

    public func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didFinishSpeechUtterance utterance: AVSpeechUtterance!) {
        if (synthesizer.speaking) {
            return
        }
        setAudioSessionActive(false)
    }
    public func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didPauseSpeechUtterance utterance: AVSpeechUtterance!) {
        setAudioSessionActive(false)
    }

    public func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didContinueSpeechUtterance utterance: AVSpeechUtterance!) {
//        setAudioSessionActive(true)
    }

    public func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didCancelSpeechUtterance utterance: AVSpeechUtterance!) {
        setAudioSessionActive(false)
    }
}