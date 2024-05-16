//
// ContentView.swift
// VoiceDictation
//
// Created by yamato on 2024/04/19.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel = ViewModel()
  
  var body: some View {
    VStack {
      TextEditor(text: $viewModel.transcribedText)
        .disabled(viewModel.state.isRecording ? true : false)
        .font(.title)
        .cornerRadius(10.0)
        .padding()
      
      Button(action: {
        if viewModel.state.isRecording {
          viewModel.stop()
        } else {
          do {
            try viewModel.record()
          } catch {
            print("failed to call viewModel.record()")
            print(error)
          }
        }
      }, label: {
        Image(systemName: viewModel.state.isRecording ? "stop.circle" : "record.circle")
          .resizable()
          .scaledToFit()
          .foregroundStyle(.red, .primary)
          .frame(width: 50, height: 50)
      })
      .buttonStyle(PlainButtonStyle())
      .clipShape(Circle())
      .padding()
    }
    .padding()
    .onAppear {
      viewModel.requestSpeechRecognizerAuthorization()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
