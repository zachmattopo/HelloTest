//
//  SignUpController.swift
//  HelloTest
//
//  Created by Hafiz Nordin on 18/02/2019.
//  Copyright © 2019 Hafiz Nordin. All rights reserved.
//

import UIKit
import Alamofire

class SignUpController: UITableViewController, UITextFieldDelegate {
    var originalBarTintColor: UIColor?
    
    // MARK: - Properties
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var teeAndCeeSwitch: UISwitch!
    
    // MARK: - Actions
    @IBAction func doneButtonTapped(_ sender: Any) {
        //Dismiss keyboard
        emailTextfield.resignFirstResponder()
        
        //Show loader
        self.loadingAnimation(message: "Signing up...")
        
        submitForm { isSuccess in
            //Dismiss loader animation
            self.dismiss(animated: true, completion: {
                if isSuccess {
                    //Show price list screen
                    let priceListController = self.storyboard?.instantiateViewController(withIdentifier: "PriceListController") as! PriceListController
                    priceListController.emailAddress = self.emailTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.navigationController?.pushViewController(priceListController, animated: true)
                } else {
                    //Show error
                    let alert = UIAlertController(title: "Sign Up Error", message: "Unable to submit form. Please try again.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    alert.preferredAction = alert.actions[0]
                    self.present(alert, animated: true, completion: nil)
                }
            })
        }
    }
    
    @IBAction func unwindFromPriceList(segue: UIStoryboardSegue) {
        //Reset sign up form
        emailTextfield.text = ""
        teeAndCeeSwitch.isOn = false
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Hide extra cells at the bottom of static table view
        tableView.tableFooterView = UIView()
        
        //TODO: Get plist hasSignedUp here, if yes then skip sign up screen
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Save original navbar color to restore later, set navbar to white
        originalBarTintColor = navigationController?.navigationBar.barTintColor
        navigationController?.navigationBar.barTintColor = .white
        
        //Hide the shadow below the navigation bar
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        
        //Enable/disable "Done" button based on the email validity
        if emailTextfield.text != nil && validateEmail(emailTextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)) {
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //Restore original bar tint color
        navigationController?.navigationBar.barTintColor = originalBarTintColor
        
        //Restore default state for navigation bar
        navigationController?.navigationBar.setValue(false, forKey: "hidesShadow")
    }
    
    /// Validate entered email address.
    ///
    /// - Parameter enteredEmail: Entered email.
    /// - Returns: True if email is valid, false otherwise.
    func validateEmail(_ address: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: address)
    }
    
    /// Generate a random string based on the specified length.
    ///
    /// - Parameter length: Number of chars in string.
    /// - Returns: Random string.
    func generateRandomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...length-1).map{ _ in letters.randomElement()! })
    }
    
    /// Show loading animation while processing content.
    ///
    /// - Parameter message: Specific message to go alongside the loader.
    func loadingAnimation(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .gray
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    /// Submit form to server via POST.
    ///
    /// - Parameter callback: Callback once the request is completed (True/False).
    func submitForm(callback: @escaping (_ isSuccess: Bool) -> Void) {
        guard emailTextfield.text != nil && validateEmail(emailTextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }
        
        let postUrl = "https://staging.hellogold.com/api/v3/users/register.json"
        
        let params: [String: String] = [
            "email": emailTextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines),
            "uuid": UUID().uuidString,
            "data": generateRandomString(length: 32), //256 bits
            "tnc": teeAndCeeSwitch.isOn ? "true" : "false"
        ]
        
        Alamofire.request(postUrl, method: .post, parameters: params, encoding: JSONEncoding.default).validate().responseData { response in
            if response.result.isSuccess {
                callback(true)
            } else {
                //Unable to process request. Maybe not connected to internet.
                callback(false)
            }
        }
    }
    
    // MARK: - Text field delegates
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let currentText = textField.text else { return true }
        
        //Check current text field texts
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        //Enable/disable "Done" button based on the email validity
        if validateEmail(updatedText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Table view delegates
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 2 {
            return 0.0001
        }
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}

