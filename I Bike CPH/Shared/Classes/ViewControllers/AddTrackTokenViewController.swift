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
    fileprivate let signInHelper = SignInHelper()
    fileprivate var hasPreExistingTrackToken: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "track_token_title".localized
        
        updateUI()
        if UserHelper.isFacebook() {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            UserClient.instance.hasTrackToken { result in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                switch result {
                case .success(let hasToken):
                    self.hasPreExistingTrackToken = hasToken
                    self.updateUI()
                default: break
                }
            }
            UserClient.instance.userData { result in
                switch result {
                case .success(let name, let image):
                    self.profileLabel.text = name
                    self.imageView.image = image
                default: break
                }
            }
        }
        
        imageView.layer.cornerRadius = 5
        imageView.layer.masksToBounds = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        view.addKeyboardPanning { [weak self] keyboardFrameInView, opening, closing in
            let keyboardIsVisibleWithHeight = self!.view.frame.height - keyboardFrameInView.minY
            let insets = UIEdgeInsetsMake(0, 0, keyboardIsVisibleWithHeight, 0);
            self?.scrollView.contentInset = insets
            self?.scrollView.scrollIndicatorInsets = insets
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.removeKeyboardControl()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func didTapSendButton(_ sender: AnyObject) {
        send()
    }
    
    func updateUI() {
//        let isLoggedIn = UserHelper.loggedIn()
        let isFacebook = UserHelper.isFacebook()
        
        passwordRepeatLabel.isHidden = true
        if isFacebook {
            subtitleLabel.text = "track_token_subtitle_facebook".localized
            if !hasPreExistingTrackToken {
                passwordRepeatLabel.isHidden = false
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
        if !passwordRepeatLabel.isHidden &&
            passwordLabel.text != passwordRepeatLabel.text {
            // Show error
            let alertView = UIAlertView(title: "Error".localized, message: "register_error_passwords".localized, delegate: nil, cancelButtonTitle: "OK".localized)
            alertView.show()
            return
        }
        // Password has some length
        guard let password = passwordLabel.text, password.lengthOfBytes(using: String.Encoding.utf8) != 0 else {
            let alertView = UIAlertView(title: "Error".localized, message: "register_error_fields".localized, delegate: nil, cancelButtonTitle: "OK".localized)
            alertView.show()
            return
        }
        
        if UserHelper.isFacebook() && !hasPreExistingTrackToken {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            UserClient.instance.addTrackToken(password) { result in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                switch result {
                case .success:
                    self.dismiss()
                case .other(_):
                    let alertView = UIAlertView(title: "Error".localized, message: "network_error_text".localized, delegate: nil, cancelButtonTitle: "OK".localized)
                    alertView.show()
                }
            }
        } else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            signInHelper.login(withEmail: UserHelper.email(), password: password, view: self.view) { success, errorTitle, errorDescription in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if success {
                    self.dismiss()
                    return
                }
                let alertView = UIAlertView(title: errorTitle?.localized, message: errorDescription?.localized, delegate: nil, cancelButtonTitle: "OK".localized)
                alertView.show()
            }
        }
    }
}

extension AddTrackTokenViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        switch textField {
        case passwordLabel:
            if passwordRepeatLabel.isHidden {
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
