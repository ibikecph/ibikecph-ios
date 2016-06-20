//
//  InstructionTextToSpeechSynthesizer.swift
//  I Bike CPH
//

class InstructionTextToSpeechSynthesizer: TextToSpeechSynthesizer {

    var lastSpokenTurnInstruction: String = ""
    var previousDistanceToNextTurn: Int = Int.max
    var previousTurnInstructionTime: NSDate = NSDate()
    var turnInstructionSpoken: Bool = false
    
    func speakDestination(item: SearchListItem) {
        let destinationName = (item.name.containsString(item.street)) ? item.street + " " + item.number : item.name
        let stringToBeSpoken = String.init(format: "read_aloud_enabled".localized, destinationName)
        self.speakString(stringToBeSpoken)
    }
    
    func speakTurnInstruction(instruction: SMTurnInstruction, routeComposite: RouteComposite) {
        var nextTurnInstruction = instruction.fullDescriptionString
        let metersToNextTurn = Int(instruction.lengthInMeters)
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
                nextTurnInstruction = "read_aloud_in".localized + " \(instruction.localizedRoundedDistanceToNextTurnWithUnit), " + nextTurnInstruction
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
    
    private let calendar = NSCalendar.currentCalendar()
    private let unitFlags: NSCalendarUnit = [.Hour, .Minute]
    private func hoursAndMinutes(seconds: NSTimeInterval) -> (hour: Int, minutes: Int) {
        let rounded = round(seconds/60)*60 // Round to minutes
        let components = calendar.components(unitFlags, fromDate: NSDate(), toDate: NSDate(timeIntervalSinceNow: rounded), options: NSCalendarOptions(rawValue: 0))
        let hours = components.hour
        let minutes = components.minute
        return (hours, minutes)
    }
    
    override func speakString(string: String) {
        if !Settings.sharedInstance.readAloud.on {
            // Reading aloud is not enabled
            return
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