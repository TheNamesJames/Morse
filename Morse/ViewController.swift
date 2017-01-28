//
//  ViewController.swift
//  Morse
//
//  Created by James Wilkinson on 19/01/2017.
//  Copyright © 2017 James Wilkinson. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    fileprivate var morseTransmitterInvalidatorBlock: MorseController.TimerInvalidatorBlock?
    @IBOutlet weak var plainTextView: UITextView!
    @IBOutlet weak var morseLabel: UILabel!
    @IBOutlet weak var morseScroll: UIScrollView!
    @IBOutlet weak var morseScrollPreferredHeight: NSLayoutConstraint!
    @IBOutlet weak var transmitLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var bottomSpace: NSLayoutConstraint!
    @IBOutlet weak var morseLabelPreferredHeight: NSLayoutConstraint!
    fileprivate var hasActualText = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let handleKeyboardFrameChange: (Notification) -> Void = { [weak self] (notification) in
            guard let userInfo = notification.userInfo, let endY = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
            }
            
            self?.bottomSpace.constant = UIScreen.main.bounds.height - endY.minY
            
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
            let options = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue
            UIView.animate(withDuration: duration ?? 0.1, delay: 0.0, options: UIViewAnimationOptions(rawValue: options ?? 0), animations: {
                self?.view.layoutIfNeeded()
            },  completion: nil)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: .main, using: handleKeyboardFrameChange)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: .main, using: handleKeyboardFrameChange)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: .main) { [weak self] _ in
            self?.plainTextView.becomeFirstResponder()
        }
        
        morseScroll.addObserver(self, forKeyPath: "contentSize", options: [.new], context: nil)
    }
    
    deinit {
        morseScroll.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let object = object as? UIScrollView, object === morseScroll && keyPath == "contentSize" {
            morseScrollPreferredHeight.constant = morseScroll.contentSize.height
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        plainTextView.becomeFirstResponder()
    }
    
    @IBAction func transmitTapped(_ sender: UIView) {
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0.3
        }, completion: { _ in
            self.plainTextView.isUserInteractionEnabled = false
            self.plainTextView.textColor = UIColor.white.withAlphaComponent(0.6)
            self.morseLabel.isUserInteractionEnabled = false
            self.transmitLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            
            self.morseTransmitterInvalidatorBlock = MorseController.transmit(self.plainTextView.text ?? "", block: { [weak self] (morse) in
                UIView.animate(withDuration: 0.1) {
                    self?.view.alpha = morse ? 1 : 0.3
                    self?.toggleTorch(morse)
                }
                }, reset: { [weak self] in
                    self?.toggleTorch(false)
                    
                    UIView.animate(withDuration: 1, animations: {
                        self?.view.alpha = 1
                    }, completion: { _ in
                        self?.morseTransmitterInvalidatorBlock = nil
                        self?.plainTextView.isUserInteractionEnabled = true
                        self?.plainTextView.textColor = UIColor.white
                        self?.morseLabel.isUserInteractionEnabled = true
                        self?.transmitLabel.textColor = UIColor.white
                    })
            })
        })
    }
    
    private func toggleTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo), device.hasTorch else { return }
        
        do {
            defer {
                device.unlockForConfiguration()
            }
            try device.lockForConfiguration()
            
            device.torchMode = on ? .on : .off
        } catch {}
    }
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        morseTransmitterInvalidatorBlock?()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension ViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let replacedString = ((textView.text ?? "") as NSString).replacingCharacters(in: range, with: text) as String
        let valid = MorseController.validate(replacedString).isValid
        
        if !valid {
        }
        
        return valid
                shakeTextView()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if !hasActualText {
            textView.text = nil
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text, !text.isEmpty else {
//            textView.text = "Enter message..."
//            textView.textColor = UIColor.white.withAlphaComponent(0.6)
            morseLabel.text = nil
            morseLabelPreferredHeight.constant = 0
            timeLabel.text = nil
            transmitLabel.text = "TRANSMIT"
            transmitLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            return
        }
        
        let morse = MorseController.morse(from: text)!
        morseLabel.attributedText = morseCodeAttributedText(MorseController.morseString(from: morse), large: false)
        morseLabelPreferredHeight.constant = morseLabel.sizeThatFits(CGSize(width: morseLabel.bounds.width, height: .greatestFiniteMagnitude)).height //+ morseLabel.textContainerInset.top + morseLabel.textContainerInset.bottom
        
        // FIXME: calc actual time (in MorseController) w/ delays between dots/dashes
        timeLabel.text = String(morse.flatMap { $0 }.map { $0.time }.reduce(0) { $0.0 + $0.1 })
        transmitLabel.text = "TRANSMIT"
        transmitLabel.textColor = UIColor.white
    }
    
    private func morseCodeAttributedText(_ string: String, large: Bool) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = large ? 48 : 36
        paragraphStyle.minimumLineHeight = large ? 48 : 36
//        paragraphStyle.lineSpacing = large ? 48 : 36
        return NSAttributedString(string: string, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 36), NSParagraphStyleAttributeName: paragraphStyle])
    }
    
    private func shakeTextView() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.5
        animation.values = [-5, 5, -5, 5, -2.5, 2.5, -1.25, 1.25, 0]
        plainTextView.layer.add(animation, forKey: "shake")
    }
}
