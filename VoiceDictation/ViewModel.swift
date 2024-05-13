//
// ViewModel.swift
// VoiceDictation
//
// Created by yamato on 2024/04/19.
//

import Speech
import AVFoundation

var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
var recognitionTask: SFSpeechRecognitionTask?
var audioEngine: AVAudioEngine = AVAudioEngine()

enum AppState: Equatable {
  case notRecording
  case recording
  
  var isRecording: Bool {
    switch self {
    case .notRecording:
      return false
    case .recording:
      return true
    }
  }
  
  var titleString: String {
    switch self {
    case .notRecording:
      return "Voice Memo"
    case .recording:
      return "Recording/Recognizing"
    }
  }
}

@MainActor
class ViewModel: ObservableObject {
  @Published var state: AppState = .notRecording
  @Published var transcribedText: String = "Tap the button below to begin"
  
  func requestSpeechRecognizerAuthorization() {
    if (SFSpeechRecognizer.authorizationStatus() == .authorized) { return }
    
    SFSpeechRecognizer.requestAuthorization { status in
      DispatchQueue.main.async {
        switch status {
        case .authorized:
          print("Speech Recognition access authorized.")
        case .denied:
          print("Speech Recognition access denied.")
        case .restricted:
          print("Speech Recognition access restricted on this device.")
        case .notDetermined:
          print("User has not yet decided on Speech Recognition access.")
        @unknown default:
          print("Unknown authorization status")
        }
      }
    }
  }
  
  func requestMicrophoneAccess() {
    if AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) == .authorized { return }
    
    AVCaptureDevice.requestAccess(for: AVMediaType.audio) { granted in
      DispatchQueue.main.async {
        if granted {
          print("Microphone access granted.")
        } else {
          print("Microphone access denied.")
        }
      }
    }
  }
  
  func record() throws {
    print("Start recording")
    
    requestMicrophoneAccess()
    
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    guard let recognitionRequest = recognitionRequest else {
      fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
    }
    recognitionRequest.shouldReportPartialResults = true
    recognitionRequest.requiresOnDeviceRecognition = false
    
    let inputNode = audioEngine.inputNode
    
    transcribedText = ""
    
    recognitionTask?.cancel()
    recognitionTask = nil
    
    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
      guard let self = self else { return }
      
      if let result = result {
        DispatchQueue.main.async {
          self.transcribedText = result.bestTranscription.formattedString
        }
      }
      
      if let error = error {
        print ("Recognition task error:" + String(describing: error))
        self.stop()
      }
    }
    
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
      recognitionRequest.append(buffer)
    }
    
    audioEngine.prepare()
    do {
      try audioEngine.start()
    } catch {
      print("failed to call audioEngine?.start()")
      print(error)
    }
    state = .recording
  }
  
  func stop() {
    print("Stop Recording")
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    
    recognitionTask?.finish()
    
    recognitionTask = nil
    recognitionRequest = nil
    
    state = .notRecording
  }
}
