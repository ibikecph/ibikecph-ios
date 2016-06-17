//
//  InstructionTextToSpeechSynthesizer.swift
//  I Bike CPH
//

class InstructionTextToSpeechSynthesizer: TextToSpeechSynthesizer {

    var lastSpokenTurnInstruction: String = ""
    var previousDistanceToNextTurn: Int = Int.max
    var previousTurnInstructionTime: NSDate = NSDate()
    var turnInstructionSpoken: Bool = false
    
    func speakInstruction(instruction: SMTurnInstruction) {
        if !Settings.sharedInstance.readAloud.on {
            // Reading aloud is not enabled
            return
        }
        
        var nextTurnInstruction = instruction.fullDescriptionString
        let metersToNextTurn = Int(instruction.lengthInMeters)
        let secondsToNextTurn = Int(instruction.timeInSeconds)
        let minimumDistanceBeforeTurn: Int = 75
        let timeDelta: NSTimeInterval = 120
        let now = NSDate()
        
        if (self.lastSpokenTurnInstruction != nextTurnInstruction) {
            // The turn instruction has changed
            self.previousDistanceToNextTurn = Int.max
            self.previousTurnInstructionTime = NSDate()
            if metersToNextTurn < minimumDistanceBeforeTurn {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                self.previousTurnInstructionTime = now
                self.speakString(nextTurnInstruction)
            } else {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                self.previousTurnInstructionTime = now
                nextTurnInstruction = "In \(instruction.lengthWithUnit), " + nextTurnInstruction
                self.speakString(nextTurnInstruction)
            }
        } else {
            // The turn instruction is the same as before
            if metersToNextTurn < minimumDistanceBeforeTurn && self.previousDistanceToNextTurn >= minimumDistanceBeforeTurn {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                self.previousTurnInstructionTime = now
                self.speakString(nextTurnInstruction)
            } else if now.timeIntervalSinceDate(self.previousTurnInstructionTime) > timeDelta {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                self.previousTurnInstructionTime = now
                let minutesLeft = (secondsToNextTurn / 60) + 1
                var encouragement = (minutesLeft == 1) ? "read_aloud_encouragement_singular".localized : "read_aloud_encouragement".localized
                encouragement = String(format: encouragement, String(minutesLeft))
                self.speakString(encouragement)
            }
        }
    }
    
    override init () {
        super.init()
        self.setupSettingsObserver()
    }
    
    deinit {
        self.unobserve()
    }
    
    private var observerTokens = [AnyObject]()
    private func unobserve() {
        for observerToken in self.observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    private func setupSettingsObserver() {
        self.observerTokens.append(NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.enableSpeech(Settings.sharedInstance.readAloud.on)
        })
    }
}