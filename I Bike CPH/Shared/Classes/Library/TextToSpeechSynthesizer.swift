//
//  TextToSpeechSynthesizer.swift
//  Open Ascent
//
//  Created by Tobias DM on 25/08/14.
//  Copyright (c) 2014 Open Ascent. All rights reserved.
//

import UIKit

import AVFoundation

open class TextToSpeechSynthesizer: NSObject {
    
    fileprivate let audioSession: AVAudioSession = {
        var audioSession = AVAudioSession.sharedInstance()
        do {
            if #available(iOS 9.0, *) {
                try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            } else {
                // Fallback on earlier versions
                try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .duckOthers)
            }
        } catch {
            // TODO: Handle error
        }
        return audioSession
    }()
    
    fileprivate let acceptableLanguageCodes: [String] = ["en-GB", "en-AU", "en-IE", "en-US", "en-ZA", "da-DK"]
    fileprivate var voiceLanguageCode: String {
        let currentLanguageCode = AVSpeechSynthesisVoice.currentLanguageCode()
        if self.acceptableLanguageCodes.contains(currentLanguageCode) {
            return currentLanguageCode
        }
        return self.acceptableLanguageCodes.first!
    }
    
    fileprivate let speechSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    
    override init () {
        super.init()
        self.speechSynthesizer.delegate = self
    }
    
    deinit {
        self.setAudioSessionActive(false)
    }
}


extension TextToSpeechSynthesizer {
    
    var hasRemainingSpeech: Bool {
        return self.speechSynthesizer.isSpeaking || self.speechSynthesizer.isPaused
    }
    
    func enableSpeech(_ enable: Bool) {
        if enable {
            self.speechSynthesizer.continueSpeaking()
        } else {
            self.speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    fileprivate func setAudioSessionActive(_ beActive: Bool) {
        do {
            try audioSession.setActive(beActive)
        } catch let error as NSError {
            print("Setting AVAudiosession state failed: \(error.description)")
        }
    }
    

    public func speakString(_ string: String) {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: self.voiceLanguageCode)
        speechSynthesizer.speak(utterance)
    }
    
    public func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}

extension TextToSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        setAudioSessionActive(true)
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        setAudioSessionActive(false)
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        setAudioSessionActive(false)
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        setAudioSessionActive(true)
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // This will from time to time provoke errors from the audio session because its I/O has not stopped completely.
        // It does however seem necessary to call the following function to stop the audio session.
        setAudioSessionActive(false)
    }
}
