//
//  VoiceSearchFeedbackViewModel.swift
//  DuckDuckGo
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import UIKit

protocol VoiceSearchFeedbackViewModelDelegate: AnyObject {
    func voiceSearchFeedbackViewModelDidFinish(_ model: VoiceSearchFeedbackViewModel, query: String?)
}

class VoiceSearchFeedbackViewModel: ObservableObject {
   
    enum AnimationType {
        case speech(volume: Double)
        case pulse(scale: Double)
    }
    
    private struct AnimationScale {
        static let max: Double = 1.3
        static let pulse: Double = 0.7
    }
    
    @Published private(set) var speechFeedback = " "
    @Published private(set) var animationType: AnimationType = .pulse(scale: 1)
    weak var delegate: VoiceSearchFeedbackViewModelDelegate?
    private let speechRecognizer: SpeechRecognizerProtocol
    private var isSilent = true
    private var recognizedWords: String? {
        didSet {
            if let words = recognizedWords {
                speechFeedback = "\"\(words)\""
            } else {
                speechFeedback = " "
            }
        }
    }

    internal init(speechRecognizer: SpeechRecognizerProtocol) {
        self.speechRecognizer = speechRecognizer
    }
    
    @available(iOS 15, *)
    func startSpeechRecognizer() {
        speechRecognizer.startRecording { [weak self] text, error, speechDidFinished in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.recognizedWords = text
                
                if speechDidFinished || error != nil {
                    self.finish()
                }
            }
            
        } volumeCallback: { [weak self] volume in
            DispatchQueue.main.async {
                self?.setupAnimationWithVolume(volume)
            }
        }
    }
    
    private func setupAnimationWithVolume(_ volume: Float) {
        let isCurrentlySilent = volume <= 0

        if !isCurrentlySilent {
            let scaleValue = min(Double(volume) + 1, AnimationScale.max)
            self.startSpeechAnimation(scaleValue)
        }
        
        if !self.isSilent && isCurrentlySilent {
            self.startSilenceAnimation()
        }
        
        self.isSilent = isCurrentlySilent
    }
    
    func stopSpeechRecognizer() {
        speechRecognizer.stopRecording()
    }
    
    func startSilenceAnimation() {
        self.animationType = .pulse(scale: AnimationScale.pulse)
    }
    
    func startSpeechAnimation(_ scale: Double) {
        self.animationType = .speech(volume: scale)
    }
    
    func cancel() {
        delegate?.voiceSearchFeedbackViewModelDidFinish(self, query: nil)
    }
    
    func finish() {
        self.delegate?.voiceSearchFeedbackViewModelDidFinish(self, query: recognizedWords)
    }
}