//
//  ViewController.swift
//  JioWatchPartyDemo
//
//  Created by Deenan on 30/08/22.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var joinButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onJoinButtonTapped(_ sender: UIButton) {
        if let channelName = channelNameTextField.text, channelName.count > 0 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "watchPartyRoom") as? WatchPartyViewController
            vc?.channelName = channelName.uppercased()
            self.present(vc!, animated: true)
        }
    }
    
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        channelNameTextField.endEditing(true)
        return true
    }
}

