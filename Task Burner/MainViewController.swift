//
//  MainViewController.swift
//  Task Burner
//
//  Created by Felix Vandelanotte on 16/06/2017.
//  Copyright © 2017 Felix Vandelanotte. All rights reserved.
//

import UIKit
import Firebase

class MainViewController: UIViewController {

    static let kUserLoggedInSegueIdentifier = "userLoggedIn"
    
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    /* Have a reference to the last signed in user to compare
     changes
     */
    weak var currentUser: FIRUser?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let auth = FIRAuth.auth() {
            
            /* Add a state change listener to firebase
             to get a notification if the user signed in.
             */
            auth.addStateDidChangeListener({ (auth, user) in
                if user != nil && user != self.currentUser {
                    self.currentUser = user
                    self.performSegue(withIdentifier: MainViewController.kUserLoggedInSegueIdentifier,
                                      sender: self)
                }
            })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let auth = FIRAuth.auth() {
            /* Following the balance principle in iOS,
             Stop listening to user state changes while not on screen.
             */
            auth.removeStateDidChangeListener(self)
        }
    }
    
    @IBAction func login() {
        if let email = self.emailField.text,
            let password = self.passwordField.text,
            let auth = FIRAuth.auth() {
            
            /* If both email and password fields are not empty,
             call firebase signin
             */
            auth.signIn(withEmail: email,
                        password: password)
        }
    }
    
    @IBAction func register() {
        if let email = self.emailField.text,
            let password = self.passwordField.text,
            let auth = FIRAuth.auth() {
            /* Note: creating a user automatically signs in.
             */
            auth.createUser(withEmail: email,
                            password: password)
        }
    }
    
    @IBAction func signOut(segue: UIStoryboardSegue) {
        /* When Sign out is pressed, and the task list controller closes,
         call Firebase sign out.
         */
        if let auth = FIRAuth.auth() {
            do {
                try auth.signOut()
            } catch {
                print(error)
            }
        }
    }
    


    




}
