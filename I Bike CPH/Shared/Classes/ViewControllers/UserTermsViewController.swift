//
//  UserTermsViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 22/07/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import PSTAlertController

class UserTermsViewController: SMTranslatedViewController {
    
    @IBOutlet weak var humanReadableLabel: UILabel?
    @IBOutlet weak var readTermsButton: UIButton?
    @IBOutlet weak var acceptButton: UIButton?
    @IBOutlet weak var noButton: UIButton?
    
    var userTerms: UserTerms? {
        didSet {
            updateToUserTerms()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateToUserTerms()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    @IBAction func didTapReadTerms(sender: AnyObject) {
        if let url = userTerms?.url {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    @IBAction func didTapNo(sender: AnyObject) {
        let alertController = PSTAlertController(title: "", message: "accept_user_terms_or_log_out".localized, preferredStyle: .Alert)
        let cancelAction = PSTAlertAction(title: "back".localized) { action in
            alertController.dismissAnimated(true, completion: nil)
        }
        alertController.addAction(cancelAction)
        let loginAction = PSTAlertAction(title: "logout".localized) { action in
            UserHelper.logout()
            self.dismiss()
        }
        alertController.addAction(loginAction)
        alertController.showWithSender(self, controller: self, animated: true, completion: nil)
    }
    
    @IBAction func didTapAccept(sender: AnyObject) {
        if let version = userTerms?.version {
            UserTermsClient.instance.latestVerifiedVersion = version
            dismiss()
        }
    }
    
    func updateToUserTerms() {
        humanReadableLabel?.text = userTerms?.humanReadableText
        let enabled = userTerms != nil
        readTermsButton?.enabled = enabled
        acceptButton?.enabled = enabled
        noButton?.enabled = enabled
    }
}


class TintedBackgroundView: UIView {
    
    override func tintColorDidChange() {
        backgroundColor = tintColor
    }
}
