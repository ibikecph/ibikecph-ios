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
        var nextTurnInstruction = instruction.fullDescriptionString
        let metersToNextTurn = Int(instruction.lengthInMeters)
        let secondsToNextTurn = Int(instruction.timeInSeconds)
        let minimumDistanceBeforeTurn: Int = 50
        let timeDelta: NSTimeInterval = 120
        let now = NSDate()
        
        if (self.lastSpokenTurnInstruction != nextTurnInstruction) {
            // The next turn instruction has changed
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
            // The next turn instruction is the same as before
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
}