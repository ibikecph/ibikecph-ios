//
//  TextToSpeechSynthesizer.swift
//  Open Ascent
//
//  Created by Tobias DM on 25/08/14.
//  Copyright (c) 2014 Open Ascent. All rights reserved.
//

import UIKit

import AVFoundation.AVAudioSession
import AVFoundation.AVSpeechSynthesis

public class TextToSpeechSynthesizer: NSObject {
    
    private let audioSession: AVAudioSession = {
        var audioSession = AVAudioSession.sharedInstance()
        do {
            if #available(iOS 9.0, *) {
                try audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: [.DuckOthers, .InterruptSpokenAudioAndMixWithOthers])
            } else {
                // Fallback on earlier versions
                try audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: .DuckOthers)
            }
        } catch {
            // TODO: Handle error
        }
        return audioSession
    }()
    
    private let speechSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    
    override init () {
        super.init()
        self.speechSynthesizer.delegate = self
    }
    
    deinit {
        self.setAudioSessionActive(false)
    }
}


extension TextToSpeechSynthesizer {
    
    func enabledSpeech(enable: Bool) {
        self.setAudioSessionActive(enable)
        if enable {
            self.speechSynthesizer.continueSpeaking()
        } else {
            self.speechSynthesizer.pauseSpeakingAtBoundary(.Immediate)
        }
    }

    private func setAudioSessionActive(beActive: Bool) {
        do {
            try audioSession.setActive(beActive)
        } catch let error as NSError {
            print("Setting AVAudiosession state failed: \(error.description)")
        }
    }
    

    public func speakString(string: String) {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        print("Will speak: \(string)")
        speechSynthesizer.speakUtterance(utterance)
    }
}

extension TextToSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    
    public func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didStartSpeechUtterance utterance: AVSpeechUtterance) {
        setAudioSessionActive(true)
    }

    public func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didFinishSpeechUtterance utterance: AVSpeechUtterance) {
        if (synthesizer.speaking) {
            return
        }
        setAudioSessionActive(false)
    }
    public func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didPauseSpeechUtterance utterance: AVSpeechUtterance) {
        setAudioSessionActive(false)
    }

    public func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didContinueSpeechUtterance utterance: AVSpeechUtterance) {
        setAudioSessionActive(true)
    }

    public func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didCancelSpeechUtterance utterance: AVSpeechUtterance) {
        setAudioSessionActive(false)
    }
}