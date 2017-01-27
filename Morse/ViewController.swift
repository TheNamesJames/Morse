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
    @IBOutlet weak var morseScroll: UIScrollView!
    @IBOutlet weak var morseLabel: UILabel!
    @IBOutlet weak var morseLabelWidth: NSLayoutConstraint!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var remainingLabel: UILabel!
    @IBOutlet weak var morseButton: UIButton!
    @IBOutlet var morseButtonRight: NSLayoutConstraint!
    @IBOutlet weak var scrollProgressBar: UIView!
    @IBOutlet var morseScrollProgress: NSLayoutConstraint!
    fileprivate var hideScrollProgressTimer: Timer?
    fileprivate var morseTransmitterInvalidatorBlock: MorseController.TimerInvalidatorBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        morseLabel.text = nil
        morseButtonRight.isActive = false
        
        morseScroll.addObserver(self, forKeyPath: "contentSize", options: [.initial, .new], context: nil)
    }
    
    deinit {
        morseScroll.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as? UIScrollView == morseScroll && keyPath == "contentSize" {
            updateMorseScroller()
        }
    }
    
    fileprivate func didScrollMorse() {
        updateMorseScroller()
    }
    
    private func updateMorseScroller() {
        defer {
            (morseScrollProgress.firstItem as? UIView)?.needsUpdateConstraints()
            view.layoutIfNeeded()
        }
        guard morseScroll.contentOffset.x / (morseScroll.contentSize.width - morseScroll.bounds.width) > 0.0001 else {
            morseScrollProgress = morseScrollProgress.withMultiplier(0.0001, automaticallyActivate: true)
            return
        }
        morseScrollProgress = morseScrollProgress.withMultiplier(morseScroll.contentOffset.x / (morseScroll.contentSize.width - morseScroll.bounds.width), automaticallyActivate: true)
    }
    
    @IBAction func transmitTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0.3
        }, completion: { _ in
            self.textField.isEnabled = false
            self.morseScroll.isUserInteractionEnabled = false
            self.morseButton.isEnabled = false
            
            self.morseTransmitterInvalidatorBlock = MorseController.transmit(self.textField.text ?? "", block: { [weak self] (morse) in
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
                        self?.textField.isEnabled = true
                        self?.morseScroll.isUserInteractionEnabled = true
                        self?.morseButton.isEnabled = true
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
}

extension ViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let replacedString = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string) as String
        let valid = MorseController.validate(replacedString).isValid
        
        if !valid {
            shakeTextField()
        }
        
        return valid
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        guard let text = sender.text, !text.isEmpty else {
            morseLabel.text = nil
            morseLabelWidth.constant = 0
            remainingLabel.text = String(120)
            sender.clearButtonMode = .never
            setMorseButtonHidden(true)
            return
        }
        
        morseLabel.text = MorseController.morseString(from: text)
        morseLabelWidth.constant = morseLabel.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: morseLabel.bounds.height)).width
        
        sender.clearButtonMode = .always
        
        remainingLabel.text = String(MorseController.inputLimit - (text.characters.count))
        setMorseButtonHidden(false)
    }
    
    private func shakeTextField() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.5
        animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, -2.5, 2.5, 0.0 ].map { $0 / 2}
        textField.layer.add(animation, forKey: "shake")
    }
    
    private func setMorseButtonHidden(_ hidden: Bool) {
        guard (morseButtonRight.isActive && hidden) || (!morseButtonRight.isActive && !hidden) else {
            return
        }
        
        morseButton.isUserInteractionEnabled = !hidden
        morseButtonRight.isActive = !hidden
        morseButton.setNeedsLayout()
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.beginFromCurrentState, hidden ? .curveEaseIn : .curveEaseOut], animations: {
            self.morseButton.alpha = hidden ? 0 : 1
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.beginFromCurrentState, !hidden ? .curveEaseIn : .curveEaseOut], animations: {
            self.morseButton.alpha = hidden ? 0 : 1
        }, completion: nil)
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        setMorseScrollHighlighted(true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            setMorseScrollHighlighted(false)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setMorseScrollHighlighted(false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScrollMorse()
    }
    
    private func setMorseScrollHighlighted(_ highlighted: Bool) {
        hideScrollProgressTimer?.invalidate()
        hideScrollProgressTimer = nil
        
        if highlighted {
            UIView.animate(withDuration: 0.3) {
                self.scrollProgressBar.alpha = 1
            }
        } else {
            hideScrollProgressTimer?.invalidate()
            hideScrollProgressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [ weak self] _ in
                UIView.animate(withDuration: 0.5) {
                    self?.scrollProgressBar.alpha = 0.1
                }
            }
        }
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return morseTransmitterInvalidatorBlock != nil
    }
}
