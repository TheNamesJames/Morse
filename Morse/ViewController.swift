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
    fileprivate var morseTransmitterInvalidatorBlock: MorseTransmitter.TimerInvalidatorBlock?
    @IBOutlet weak var plainTextView: UITextView!
    @IBOutlet weak var morseLabel: UILabel!
    @IBOutlet weak var morseScroll: UIScrollView!
    @IBOutlet weak var morseScrollPreferredHeight: NSLayoutConstraint!
    private var showingTransmitKeyLine = false
    @IBOutlet weak var morseScrollKeyline: UIView!
    private var showingMorseScrollKeyLine = false
    @IBOutlet weak var transmitKeyline: UIView!
    @IBOutlet weak var transmitLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var flashImageView: UIImageView!
    @IBOutlet weak var bottomSpace: NSLayoutConstraint!
    @IBOutlet weak var morseLabelPreferredHeight: NSLayoutConstraint!
    @IBOutlet weak var textViewPreferredHeight: NSLayoutConstraint!
    @IBOutlet var marginConstraints: [NSLayoutConstraint]!
    fileprivate var useFlash: Bool! {
        didSet {
            guard canUseTorch() else {
                flashImageView.image = #imageLiteral(resourceName: "Flash Off").withRenderingMode(.alwaysTemplate)
                flashImageView.tintColor = UIColor.white.withAlphaComponent(0.3)
                useFlash = false
                return
            }
            
            flashImageView.image = (useFlash! ? #imageLiteral(resourceName: "Flash On") : #imageLiteral(resourceName: "Flash Off")).withRenderingMode(.alwaysTemplate)
            flashImageView.tintColor = UIColor.white.withAlphaComponent(0.6)
        }
    }
    fileprivate var state: State = .empty {
        didSet {
            switch state {
            case .text, .empty:
                transmitLabel.text = "TRANSMIT"
                transmitLabel.textColor = UIColor.white.withAlphaComponent(state == .text ? 1 : 0.6)
            case .transmitting:
                transmitLabel.textColor = UIColor.white
                transmitLabel.text = "TRANSMITTING. CANCEL"
            }
        }
    }
    
    enum State {
        case empty
        case text
        case transmitting
    }
    
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
        morseScroll.addObserver(self, forKeyPath: "contentOffset", options: [.new], context: nil)
        plainTextView.addObserver(self, forKeyPath: "contentSize", options: [.new], context: nil)
        plainTextView.addObserver(self, forKeyPath: "contentOffset", options: [.new], context: nil)
        plainTextView.addObserver(self, forKeyPath: "selectedTextRange", options: [.new], context: nil)
        
        textViewDidChange(plainTextView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.bounds.width == 320 && marginConstraints[0].constant != 12 {
            marginConstraints.forEach {
                $0.constant = 12
            }
        }
    }
    
    deinit {
        morseScroll.removeObserver(self, forKeyPath: "contentSize")
        morseScroll.removeObserver(self, forKeyPath: "contentOffset")
        plainTextView.removeObserver(self, forKeyPath: "contentSize")
        plainTextView.removeObserver(self, forKeyPath: "contentOffset")
        plainTextView.removeObserver(self, forKeyPath: "selectedTextRange")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let object = object as? UIScrollView, object === morseScroll && (keyPath == "contentSize" || keyPath == "contentOffset") {
            morseScrollPreferredHeight.constant = morseScroll.contentSize.height
            let showFader = morseScroll.contentSize.height > morseScroll.bounds.height && morseScroll.contentOffset.y < morseScroll.contentSize.height - morseScroll.bounds.height
            if showFader != showingMorseScrollKeyLine {
                showingMorseScrollKeyLine = showFader
                UIView.animate(withDuration: 0.1, delay: 0.0, options: .beginFromCurrentState, animations: { 
                    self.morseScrollKeyline.alpha = showFader ? 1 : 0
                }, completion: nil)
            }
        } else if let object = object as? UITextView, object === plainTextView && keyPath == "selectedTextRange" {
            if state == .empty {
                plainTextView.removeObserver(self, forKeyPath: "selectedTextRange")
                object.selectedTextRange = object.textRange(from: object.beginningOfDocument, to: object.beginningOfDocument)
                plainTextView.addObserver(self, forKeyPath: "selectedTextRange", options: [.new], context: nil)
            }
        } else if let object = object as? UITextView, object === plainTextView && (keyPath == "contentSize" || keyPath == "contentOffset") {
            let showFader = plainTextView.contentSize.height > plainTextView.bounds.height && plainTextView.contentOffset.y < plainTextView.contentSize.height - plainTextView.bounds.height
            if showFader != showingTransmitKeyLine {
                showingTransmitKeyLine = showFader
                UIView.animate(withDuration: 0.1, delay: 0.0, options: .beginFromCurrentState, animations: {
                    self.transmitKeyline.alpha = showFader ? 1 : 0
                }, completion: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        plainTextView.becomeFirstResponder()
        useFlash = true
    }
    
    @IBAction func transmitTapped(_ sender: UIView) {
        switch state {
        case .empty:
            break
        case .text:
            transmit()
        case .transmitting:
            if morseTransmitterInvalidatorBlock?.isTransmitting() == true {
                morseTransmitterInvalidatorBlock?.cancel()
            }
        }
    }
    
    private func transmit() {
        state = .transmitting
        
        UIView.animate(withDuration: 0.5, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.alpha = 0.7
        }, completion: { _ in
            self.plainTextView.isUserInteractionEnabled = false
            self.plainTextView.textColor = UIColor.white.withAlphaComponent(0.6)
            
            self.morseTransmitterInvalidatorBlock = MorseTransmitter.transmit(self.plainTextView.attributedText?.string ?? "", block: { [weak self] (morse, remainingDuration) in
                self?.timeLabel.text = self?.stringForTransmitDuration(remainingDuration)
                if self?.useFlash == true {
                    self?.toggleTorch(morse)
                } else {
                    UIView.animate(withDuration: 0.1) {
                        self?.view.alpha = morse ? 1 : 0.5
                    }
                }
                }, reset: { [weak self] in
                    self?.state = .text
                    self?.toggleTorch(false)
                    
                    UIView.animate(withDuration: 1, animations: {
                        self?.view.alpha = 1
                        self?.setNeedsStatusBarAppearanceUpdate()
                    }, completion: { _ in
                        self?.morseTransmitterInvalidatorBlock = nil
                        self?.plainTextView.isUserInteractionEnabled = true
                        self?.textViewDidChange(self!.plainTextView)
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
    
    fileprivate func canUseTorch() -> Bool {
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else { return false }
        
        return device.hasTorch
    }
    
    @IBAction func flashTapped(_ sender: UIView) {
        useFlash = !useFlash
    }
}

extension ViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard !CharacterSet.newlines.contains(text.unicodeScalars.first ?? UnicodeScalar(UInt8())) else {
            return false // If first character is newline, ignore (prevents auto capitalisation)
        }
        
        let replacedString = ((textView.attributedText?.string ?? "") as NSString).replacingCharacters(in: range, with: text) as String
        
        switch state {
        case .empty:
            guard !text.isEmpty else {
                return false
            }
            guard MorseController.validate(replacedString).isValid else {
                shakeTextView()
                return false
            }
            textView.attributedText = plainTextAttributedText(text)
            state = .text
            textViewDidChange(textView)
            return false
        case .transmitting:
            return false
        case .text:
            guard MorseController.validate(replacedString).isValid else {
                shakeTextView()
                return false
            }
            return true
        }
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard state == .text, let text = textView.attributedText, !text.string.isEmpty else {
            state = .empty
            
            textView.attributedText = plainTextAttributedText("Enter message...")
            textView.textColor = UIColor.white.withAlphaComponent(0.6)
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            textViewPreferredHeight.constant = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)).height + textView.textContainerInset.top
            
            morseLabel.text = nil
            morseLabelPreferredHeight.constant = 0
            
            timeLabel.text = nil
            return
        }
        
        state = .text
        
        textView.attributedText = plainTextAttributedText(text.string)
        textView.textColor = .white
        textViewPreferredHeight.constant = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)).height + textView.textContainerInset.top
        
        let morse = MorseController.morse(from: text.string)!
        morseLabel.attributedText = morseCodeAttributedText(MorseController.morseString(from: morse))
        morseLabelPreferredHeight.constant = morseLabel.sizeThatFits(CGSize(width: morseLabel.bounds.width, height: .greatestFiniteMagnitude)).height
        
        timeLabel.text = stringForTransmitDuration(MorseTransmitter.transmitDuration(for: morse))
    }
    
    private func morseCodeAttributedText(_ string: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 36
        paragraphStyle.minimumLineHeight = 36
        return NSAttributedString(string: string, attributes: [NSFontAttributeName: UIFont.customFont(.playfairDisplay, size: 36), NSParagraphStyleAttributeName: paragraphStyle])
    }
    
    private func plainTextAttributedText(_ string: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 36
        paragraphStyle.minimumLineHeight = 36
        return NSAttributedString(string: string, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 24, weight: UIFontWeightLight), NSParagraphStyleAttributeName: paragraphStyle])
    }
    
    fileprivate func stringForTransmitDuration(_ duration: Double) -> String {
        guard duration < 300 else {
            return "💤"
        }
        
        return DateComponentsFormatter.localizedString(from: duration, unitsStyle: .abbreviated) ?? "😳"
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return state == .transmitting ? .default : .lightContent
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    private func shakeTextView() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.5
        animation.values = [-5, 5, -5, 5, -2.5, 2.5, -1.25, 1.25, 0]
        plainTextView.layer.add(animation, forKey: "shake")
    }
}
