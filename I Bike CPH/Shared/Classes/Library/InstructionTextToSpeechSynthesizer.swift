//
//  InstructionTextToSpeechSynthesizer.swift
//  I Bike CPH
//

import AVFoundation

class InstructionTextToSpeechSynthesizer: TextToSpeechSynthesizer {

    static let sharedInstance = InstructionTextToSpeechSynthesizer()
    
    var hasReachedDestination: Bool = false
    fileprivate var lastSpokenTurnInstruction: String = ""
    fileprivate var previousDistanceToNextTurn: Int = Int.max
    fileprivate var hasSpokenDestination: Bool = false
    var routeComposite: RouteComposite? {
        didSet {
            self.hasReachedDestination = false
            self.hasSpokenDestination = false
            self.lastSpokenTurnInstruction = ""
            self.previousDistanceToNextTurn = Int.max
            self.updateBackgroundLocationsAllowance()
            self.updateSpeechAllowance()
            
            // Speak destination and first instruction
            self.speakDestination()
            self.speakTurnInstruction()
        }
    }
    
    func speakDestination() {
        if let destination = self.routeComposite?.to {
            let destinationName = (destination.name.contains(destination.street)) ? destination.street + " " + destination.number : destination.name
            let stringToBeSpoken = String.init(format: "read_aloud_enabled".localized, destinationName)
            self.speakString(self.replaceSubstrings(stringToBeSpoken))
        }
    }
    
    func speakRecalculatingRoute() {
        let stringToBeSpoken = "read_aloud_recalculating_route".localized
        self.speakString(stringToBeSpoken)
    }
    
    func speakTurnInstruction() {
        guard let routeComposite = self.routeComposite,
                  let instructions = self.routeComposite?.currentRoute?.turnInstructions.copy() as? [SMTurnInstruction],
                  let instruction = instructions.first else {
            return
        }
        
        var nextTurnInstruction = self.replaceSubstrings(instruction.fullDescriptionString)
        let metersToNextTurn = Int(instruction.lengthInMeters)
        let minimumDistanceBeforeTurn: Int = 75
        let distanceDelta: Int = 500
        let onPublicTransport = instruction.routeType != .bike && instruction.routeType != .walk
        
        if (self.lastSpokenTurnInstruction != nextTurnInstruction) {
            // The turn instruction has changed
            self.previousDistanceToNextTurn = Int.max
            if metersToNextTurn < minimumDistanceBeforeTurn {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                self.speakString(nextTurnInstruction)
            } else {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                
                nextTurnInstruction = String(format:"read_aloud_upcoming_instruction".localized + ", \(nextTurnInstruction)",instruction.roundedDistanceToNextTurn, "unit_metres".localized)
                self.speakString(nextTurnInstruction)
            }
        } else {
            // The turn instruction is the same as before
            if metersToNextTurn < minimumDistanceBeforeTurn && self.previousDistanceToNextTurn >= minimumDistanceBeforeTurn {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                self.speakString(nextTurnInstruction)
            } else if self.previousDistanceToNextTurn - metersToNextTurn >= distanceDelta && !onPublicTransport {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                
                let (hours, minutes) = self.hoursAndMinutes(routeComposite.durationLeft)
                var encouragement: String
                let hoursString = (hours == 1) ? "unit_h_long_singular".localized : "unit_h_long".localized
                let minutesString = (minutes == 1) ? "unit_m_long_singular".localized : "unit_m_long".localized
                if hours > 0 {
                    encouragement = "read_aloud_encouragement_time_h_m".localized
                    encouragement = String(format: encouragement, String(hours), hoursString, String(minutes), minutesString)
                } else {
                    encouragement = "read_aloud_encouragement_time_m".localized
                    encouragement = String(format: encouragement, String(minutes), minutesString)
                }
                self.speakString(encouragement)
            }
        }
    }
    
    fileprivate let calendar = Calendar.current
    fileprivate let unitFlags: NSCalendar.Unit = [.hour, .minute]
    fileprivate func hoursAndMinutes(_ seconds: TimeInterval) -> (hour: Int, minutes: Int) {
        let rounded = round(seconds/60)*60 // Round to minutes
        let components = (calendar as NSCalendar).components(unitFlags, from: Date(), to: Date(timeIntervalSinceNow: rounded), options: NSCalendar.Options(rawValue: 0))
        let hours = components.hour
        let minutes = components.minute
        return (hours!, minutes!)
    }
    
    fileprivate func replaceSubstrings(_ string: String) -> String {
        let mutatedString = string.replacingOccurrences(of: " st.", with: " station")
        return mutatedString
    }
    
    override func speakString(_ string: String) {
        if !Settings.sharedInstance.readAloud.on {
            // Reading aloud is not enabled
            return
        }
        if self.hasReachedDestination {
            // Do not speak anymore after destination has been reached
            return
        }
        if self.hasRemainingSpeech && self.hasSpokenDestination {
            self.stopSpeaking()
        }
        super.speakString(string)
    }
    
    override init () {
        super.init()
        self.setupSettingsObserver()
    }
    
    deinit {
        self.unobserve()
    }
    
    fileprivate var observerTokens = [AnyObject]()
    fileprivate func unobserve() {
        for observerToken in self.observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    fileprivate func setupSettingsObserver() {
        self.observerTokens.append(NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.updateSpeechAllowance()
        })
    }
    
    fileprivate func updateSpeechAllowance() {
        if self.routeComposite != nil && Settings.sharedInstance.readAloud.on {
            self.enableSpeech(true)
        } else {
            self.enableSpeech(false)
        }
    }
    
    fileprivate func updateBackgroundLocationsAllowance() {
        if self.routeComposite != nil && Settings.sharedInstance.readAloud.on {
            SMLocationManager.sharedInstance().allowsBackgroundLocationUpdates = true
        } else {
            SMLocationManager.sharedInstance().allowsBackgroundLocationUpdates = false
        }
    }
    
    override func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        super.speechSynthesizer(synthesizer, didFinish: utterance)
        self.hasSpokenDestination = true
    }
}
