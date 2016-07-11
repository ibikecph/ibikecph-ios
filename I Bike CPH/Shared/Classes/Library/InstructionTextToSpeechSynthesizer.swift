//
//  InstructionTextToSpeechSynthesizer.swift
//  I Bike CPH
//

class InstructionTextToSpeechSynthesizer: TextToSpeechSynthesizer {

    static let sharedInstance = InstructionTextToSpeechSynthesizer()
    
    var lastSpokenTurnInstruction: String = ""
    var previousDistanceToNextTurn: Int = Int.max
    var routeComposite: RouteComposite? {
        didSet {
            self.lastSpokenTurnInstruction = ""
            self.previousDistanceToNextTurn = Int.max
            self.speakDestination()
            self.updateBackgroundLocationsAllowance()
            self.updateSpeechAllowance()
        }
    }
    
    private func speakDestination() {
        if let destination = self.routeComposite?.to {
            let destinationName = (destination.name.containsString(destination.street)) ? destination.street + " " + destination.number : destination.name
            let stringToBeSpoken = String.init(format: "read_aloud_enabled".localized, destinationName)
            self.speakString(stringToBeSpoken)
        }
    }
    
    func speakTurnInstruction() {
        guard let routeComposite = self.routeComposite,
                  instructions = self.routeComposite?.currentRoute?.turnInstructions.copy() as? [SMTurnInstruction],
                  instruction = instructions.first else {
            return
        }
        
        var nextTurnInstruction = instruction.fullDescriptionString
        let metersToNextTurn = Int(instruction.lengthInMeters)
        let minimumDistanceBeforeTurn: Int = 75
        let distanceDelta: Int = 500
        
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
            } else if self.previousDistanceToNextTurn - metersToNextTurn >= distanceDelta {
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
        self.setupLocationObserver()
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
            self?.updateSpeechAllowance()
        })
    }
    private func setupLocationObserver() {
        observerTokens.append(NotificationCenter.observe("refreshPosition") { [weak self] notification in
            if let
                locations = notification.userInfo?["locations"] as? [CLLocation],
                location = locations.first
            {
                // Tell route about new user location
                self?.routeComposite?.currentRoute?.visitLocation(location)
                self?.speakTurnInstruction()
            }
        })
    }
    private func updateSpeechAllowance() {
        if self.routeComposite != nil && Settings.sharedInstance.readAloud.on {
            self.enableSpeech(true)
        } else {
            self.enableSpeech(false)
        }
    }
    private func updateBackgroundLocationsAllowance() {
        if self.routeComposite != nil && Settings.sharedInstance.readAloud.on {
            SMLocationManager.sharedInstance().allowsBackgroundLocationUpdates = true
        } else {
            SMLocationManager.sharedInstance().allowsBackgroundLocationUpdates = false
        }
    }
}