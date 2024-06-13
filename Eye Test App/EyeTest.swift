import SwiftUI
import Speech

struct EyeTest: View {
    @State private var currentLetter = randomLetter()
    @State private var isRecording = false
    @State private var recognizedLetter = ""
    @State private var fontSizeVariable = 0
    @State private var correctCount = 0
    @State private var attemptCount = 0
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var lineChange = 0
    @State private var showConfirmation = false
    @State private var lastRecognizedLetter: String?
    @State private var failedFontSizes = Set<Int>()
    @State private var correctCountFont = [Int: Int]()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var audioEngine = AVAudioEngine()
    private let fontSizes: [CGFloat] = [100, 80, 60, 40, 20]

    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    Reticle()
                        .stroke(Color.red, lineWidth: 4)
                        .frame(width: 200, height: 200)
                    
                    Text(String(currentLetter))
                        .font(.system(size: fontSizes[fontSizeVariable]))
                        .padding()
                }
                
                Spacer()
                
                Button(action: {
                    if isRecording {
                        endTest()
                    } else {
                        beginTest()
                    }
                }) {
                    Text(isRecording ? "End Test" : "Begin Test")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            
            if showConfirmation, let lastRecognizedLetter = lastRecognizedLetter?.last {
                VStack {
                    Spacer()
                    
                    Text("Did you say \(lastRecognizedLetter)?")
                        .font(.headline)
                        .padding()
                    
                    HStack {
                        Button(action: {
                            useRecognizedLetter()
                        }) {
                            Text("Yes")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            discardRecognizedLetter()
                        }) {
                            Text("No")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear(perform: checkPermissions)
    }
    
    private func beginTest() {
        startRecording()
        isRecording = true
    }
    
    private func endTest() {
        stopRecording()
        isRecording = false
        print("Test ended")
    }
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup error: \(error.localizedDescription)")
            return
        }
        
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.recognizedLetter = result.bestTranscription.formattedString
                
                DispatchQueue.main.async {
                    self.showConfirmation = true
                    self.lastRecognizedLetter = self.recognizedLetter.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            if error != nil {
                self.recognitionTask?.cancel()
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    private func compareAndReset() {
        compareLastLetter()
        generateNewLetter()
        fontController()
        // Reset recognizedLetter
        DispatchQueue.main.async {
            self.recognizedLetter = ""
        }
    }
    
    private func compareLastLetter() {
        if let lastRecognizedLetter = lastRecognizedLetter?.last {
            let currentLetterString = String(currentLetter)
            
            if lastRecognizedLetter == currentLetterString.first {
                print("Font Size: \(fontSizes[fontSizeVariable]), Letter: \(currentLetter), Detected: \(lastRecognizedLetter), Result: Correct")
                correctCount += 1
                correctCountFont[fontSizeVariable, default: 0] += 1
            } else {
                print("Font Size: \(fontSizes[fontSizeVariable]), Letter: \(currentLetter), Detected: \(lastRecognizedLetter), Result: Incorrect")
                correctCount -= 1
            }
            print("Correct Count: \(correctCount), Total Correct Count for font size \(fontSizeVariable): \(correctCountFont[fontSizeVariable, default: 0])")
        } else {
            print("No valid letter detected in recognized text.")
        }
    }
    
    private func fontController() {
        attemptCount += 1

        if correctCount >= 4 {
            endTest()
            return
        }

        if correctCount == 2 {
            fontSizeVariable += 1
            resetAttempts()
        } else if correctCount == -2 || attemptCount == 5 {
            failedFontSizes.insert(fontSizeVariable)
            fontSizeVariable -= 1
            resetAttempts()
        }

        while failedFontSizes.contains(fontSizeVariable) {
            fontSizeVariable -= 1
        }

        if fontSizeVariable < 0 {
            fontSizeVariable = 0
        } else if fontSizeVariable >= fontSizes.count {
            fontSizeVariable = fontSizes.count - 1
        }
    }
    
    private func resetAttempts() {
        correctCount = 0
        attemptCount = 0
    }
    
    private func generateNewLetter() {
        currentLetter = EyeTest.randomLetter()
    }
    
    private func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized.")
            case .denied:
                print("Speech recognition authorization denied.")
            case .restricted:
                print("Speech recognition authorization restricted.")
            case .notDetermined:
                print("Speech recognition authorization not determined.")
            @unknown default:
                print("Unknown speech recognition authorization status.")
            }
        }
    }
    
    private static func randomLetter() -> Character {
        "SKHNOCDVRZ".randomElement()!
    }
    
    private func useRecognizedLetter() {
        showConfirmation = false
        compareAndReset()
    }
    
    private func discardRecognizedLetter() {
        showConfirmation = false
    }
}

struct Reticle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length: CGFloat = 20.0
        
        // Top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + length))
        
        // Top-right corner
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        
        // Bottom-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        
        // Bottom-right corner
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        
        return path
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EyeTest()
    }
}
