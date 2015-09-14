//
//  AddTrackTokenViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/09/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import DAKeyboardControl


class AddTrackTokenViewController: SMTranslatedViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var profileLabel: UILabel!
    @IBOutlet weak var passwordLabel: UITextField!
    @IBOutlet weak var passwordRepeatLabel: UITextField!
    private let signInHelper = SignInHelper()
    private var hasPreExistingTrackToken: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "track_token_title".localized
        
        updateUI()
        if UserHelper.isFacebook() {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            UserClient.instance.hasTrackToken { result in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                switch result {
                case .Success(let hasToken):
                    self.hasPreExistingTrackToken = hasToken
                    self.updateUI()
                default: break
                }
            }
            UserClient.instance.userData { result in
                switch result {
                case .Success(let name, var image):
                    self.profileLabel.text = name
                    self.imageView.image = image
                default: break
                }
            }
        }
        
        imageView.layer.cornerRadius = 5
        imageView.layer.masksToBounds = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        view.addKeyboardPanningWithActionHandler { [weak self] keyboardFrameInView, opening, closing in
            let keyboardIsVisibleWithHeight = CGRectGetHeight(self!.view.frame) - CGRectGetMinY(keyboardFrameInView)
            let insets = UIEdgeInsetsMake(0, 0, keyboardIsVisibleWithHeight, 0);
            self?.scrollView.contentInset = insets
            self?.scrollView.scrollIndicatorInsets = insets
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.removeKeyboardControl()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    @IBAction func didTapSendButton(sender: AnyObject) {
        send()
    }
    
    func updateUI() {
        let isLoggedIn = UserHelper.loggedIn()
        let isFacebook = UserHelper.isFacebook()
        
        passwordRepeatLabel.hidden = true
        if isFacebook {
            subtitleLabel.text = "track_token_subtitle_facebook".localized
            if !hasPreExistingTrackToken {
                passwordRepeatLabel.hidden = false
                descriptionLabel.text = "track_token_description_facebook_new".localized
            } else {
                descriptionLabel.text = "track_token_description_facebook_has_token".localized
            }
        } else {
            subtitleLabel.text = "track_token_subtitle_native".localized
            descriptionLabel.text = "track_token_description_native".localized
        }
        self.profileLabel.text = AppHelper.delegate()?.appSettings["username"] as? String
    }
    
    func send() {
        // Similar passwords (if needed)
        if !passwordRepeatLabel.hidden &&
            passwordLabel.text != passwordRepeatLabel.text {
            // Show error
            let alertView = UIAlertView(title: "Error".localized, message: "register_error_passwords".localized, delegate: nil, cancelButtonTitle: "OK".localized)
            alertView.show()
            return
        }
        // Password has some length
        let password = passwordLabel.text
        if password.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 0 {
            // Show error
            let alertView = UIAlertView(title: "Error".localized, message: "register_error_fields".localized, delegate: nil, cancelButtonTitle: "OK".localized)
            alertView.show()
            return
        }
        
        if UserHelper.isFacebook() && !hasPreExistingTrackToken {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            UserClient.instance.addTrackToken(password) { result in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                switch result {
                case .Success:
                    self.dismiss()
                case .Other(let result):
                    let alertView = UIAlertView(title: "Error".localized, message: "network_error_text".localized, delegate: nil, cancelButtonTitle: "OK".localized)
                    alertView.show()
                }
            }
        } else {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            signInHelper.loginWithEmail(UserHelper.email(), password: password, view: self.view) { success, errorTitle, errorDescription in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if success {
                    self.dismiss()
                    return
                }
                let alertView = UIAlertView(title: errorTitle.localized, message: errorDescription.localized, delegate: nil, cancelButtonTitle: "OK".localized)
                alertView.show()
            }
        }
    }
}

extension AddTrackTokenViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        switch textField {
        case passwordLabel:
            if passwordRepeatLabel.hidden {
                send()
            } else {
                passwordRepeatLabel.becomeFirstResponder()
            }
        case passwordRepeatLabel:
            send()
        default: break
        }
        return true
    }
}
