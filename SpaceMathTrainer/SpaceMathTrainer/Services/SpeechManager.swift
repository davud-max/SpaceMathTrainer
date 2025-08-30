import Foundation
import SwiftUI
import Speech
import AVFoundation
import AudioToolbox

@MainActor
class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    
    @Published var isListening = false
    @Published var lastRecognizedText = ""
    @Published var microphoneActive = false
    @Published var listeningForAnswers = false
    @Published var currentLanguage = "ru-RU"
    
    weak var gameManager: MathGameManager?
    
    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioSession = AVAudioSession.sharedInstance()
    
    private var currentVoice: AVSpeechSynthesisVoice?
    private let synthesizer = AVSpeechSynthesizer()
    
    private var currentQuestionId: String?
    private var answerTimeout: Timer?
    private var delayedProcessingTimer: Timer?
    private var lastPartialResult: String = ""
    
    // Флаги для безопасного управления AudioEngine
    private var audioEngineSetupCompleted = false
    private var audioEngineStarted = false
    
    // Защита от множественных вызовов
    private var listeningInProgress = false
    private var speechInProgress = false
    private var recognitionInProgress = false
    
    // =====================================================
    // ПОЛНОЦЕННАЯ СИСТЕМА ЗВУКОВ С AVAPLAYER
    // =====================================================
    
    private var correctSoundPlayer: AVAudioPlayer?
    private var incorrectSoundPlayer: AVAudioPlayer?
    private var timeoutSoundPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
        synthesizer.delegate = self
        
        requestSpeechAuthorization()
        setupAudioEngine()
        setupAdvancedSounds() // Новая система звуков
        
        // Найти голос Milena для русского языка
        let voices = AVSpeechSynthesisVoice.speechVoices()
        if let milenaVoice = voices.first(where: { $0.name.contains("Milena") && $0.language == "ru-RU" }) {
            currentVoice = milenaVoice
            print("✅ Found Milena voice: \(milenaVoice.name)")
        } else if let russianVoice = AVSpeechSynthesisVoice(language: "ru-RU") {
            currentVoice = russianVoice
            print("✅ Using default Russian voice: \(russianVoice.name)")
        }
        
        print("✅ SpeechManager initialized with ADVANCED sound system")
    }
    
    // =====================================================
    // ПРОДВИНУТАЯ СИСТЕМА ЗВУКОВ (РАБОТАЕТ В ЛЮБЫХ УСЛОВИЯХ)
    // =====================================================
    
    private func setupAdvancedSounds() {
        print("🔧 Setting up ADVANCED sound system with AVAudioPlayer...")
        
        // Создаем звуки с разными частотами для лучшей различимости
        correctSoundPlayer = createBeepPlayer(frequency: 880, duration: 0.4)     // Высокий приятный тон
        incorrectSoundPlayer = createBeepPlayer(frequency: 220, duration: 0.6)   // Низкий тон
        timeoutSoundPlayer = createBeepPlayer(frequency: 440, duration: 0.3)     // Средний тон
        
        // Подготавливаем плееры для быстрого воспроизведения
        correctSoundPlayer?.prepareToPlay()
        incorrectSoundPlayer?.prepareToPlay()
        timeoutSoundPlayer?.prepareToPlay()
        
        print("✅ ADVANCED sound system created with AVAudioPlayer")
    }
    
    private func createBeepPlayer(frequency: Double, duration: Double) -> AVAudioPlayer? {
        let sampleRate = 44100.0
        let samples = Int(sampleRate * duration)
        
        var audioData = [Float]()
        
        for i in 0..<samples {
            let time = Double(i) / sampleRate
            
            // Создаем синусоиду с плавным затуханием
            let fadeOutStart = samples - Int(sampleRate * 0.1) // Последние 0.1 секунды
            let fadeOut = i > fadeOutStart ? Double(samples - i) / Double(samples - fadeOutStart) : 1.0
            
            let amplitude = sin(2.0 * Double.pi * frequency * time) * fadeOut * 0.3 // 30% громкости
            audioData.append(Float(amplitude))
        }
        
        // Создаем AVAudioPCMBuffer
        guard let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                            sampleRate: sampleRate,
                                            channels: 1,
                                            interleaved: false) else {
            print("❌ Failed to create audio format")
            return nil
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(samples)) else {
            print("❌ Failed to create audio buffer")
            return nil
        }
        
        buffer.frameLength = AVAudioFrameCount(samples)
        
        guard let channelData = buffer.floatChannelData?[0] else {
            print("❌ Failed to get channel data")
            return nil
        }
        
        // Копируем данные в буфер
        for i in 0..<samples {
            channelData[i] = audioData[i]
        }
        
        // Конвертируем буфер в Data для AVAudioPlayer
        do {
            let audioFile = try createTempAudioFile(from: buffer, format: audioFormat)
            let player = try AVAudioPlayer(contentsOf: audioFile)
            player.volume = 1.0
            return player
        } catch {
            print("❌ Failed to create audio player: \(error)")
            return nil
        }
    }
    
    private func createTempAudioFile(from buffer: AVAudioPCMBuffer, format: AVAudioFormat) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let audioFile = tempDir.appendingPathComponent("beep_\(UUID().uuidString).wav")
        
        let file = try AVAudioFile(forWriting: audioFile, settings: format.settings)
        try file.write(from: buffer)
        
        return audioFile
    }

    func playCorrectSound() {
        print("🔊 Playing ADVANCED correct sound with AVAudioPlayer")
        
        Task {
            await playAdvancedSound(player: correctSoundPlayer, soundName: "correct")
            
            // Добавляем тактильную обратную связь
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
        }
    }

    func playIncorrectSound() {
        print("🔊 Playing ADVANCED incorrect sound with AVAudioPlayer")
        
        Task {
            await playAdvancedSound(player: incorrectSoundPlayer, soundName: "incorrect")
            
            // Добавляем тактильную обратную связь
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
        }
    }

    func playTimeoutSound() {
        print("🔊 Playing ADVANCED timeout sound with AVAudioPlayer")
        
        Task {
            await playAdvancedSound(player: timeoutSoundPlayer, soundName: "timeout")
            
            // Серия вибраций для таймаута
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            try? await Task.sleep(nanoseconds: 200_000_000)
            impactFeedback.impactOccurred()
        }
    }
    
    private func playAdvancedSound(player: AVAudioPlayer?, soundName: String) async {
        guard let player = player else {
            print("❌ No AVAudioPlayer for \(soundName) sound")
            
            // Fallback к системным звукам
            switch soundName {
            case "correct":
                AudioServicesPlaySystemSound(1016)
            case "incorrect":
                AudioServicesPlaySystemSound(1002)
            case "timeout":
                AudioServicesPlaySystemSound(1005)
            default:
                break
            }
            return
        }
        
        print("🎵 Playing \(soundName) sound with AVAudioPlayer (volume: \(player.volume))")
        
        do {
            // НЕ меняем категорию аудиосессии - используем существующую
            player.stop() // Останавливаем предыдущий если есть
            player.currentTime = 0 // Сбрасываем позицию
            
            if player.play() {
                print("✅ \(soundName.capitalized) sound started playing")
                
                // Ждем завершения звука
                while player.isPlaying {
                    try await Task.sleep(nanoseconds: 50_000_000) // 0.05 секунды
                }
                
                print("✅ \(soundName.capitalized) sound finished")
            } else {
                print("❌ Failed to start \(soundName) sound")
                
                // Fallback к системным звукам
                switch soundName {
                case "correct":
                    AudioServicesPlaySystemSound(1016)
                case "incorrect":
                    AudioServicesPlaySystemSound(1002)
                case "timeout":
                    AudioServicesPlaySystemSound(1005)
                default:
                    break
                }
            }
            
        } catch {
            print("❌ Error during \(soundName) sound playback: \(error)")
        }
    }
    
    func testReliableSounds() {
        print("🔊 ==========================================")
        print("🔊 TESTING ADVANCED SOUND SYSTEM")
        print("🔊 ==========================================")
        
        Task {
            print("🔊 Testing correct sound...")
            playCorrectSound()
            
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 секунды
            
            print("🔊 Testing incorrect sound...")
            playIncorrectSound()
            
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 секунды
            
            print("🔊 Testing timeout sound...")
            playTimeoutSound()
            
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 секунды
            
            // Дополнительно тестируем системные звуки
            print("🔊 Testing fallback system sounds...")
            AudioServicesPlaySystemSound(1016)
            
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            AudioServicesPlaySystemSound(1002)
            
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            AudioServicesPlaySystemSound(1005)
            
            print("🔊 ==========================================")
            print("🔊 ADVANCED SOUND TEST COMPLETED!")
            print("🔊 Если всё еще нет звуков:")
            print("🔊 1. 📱 Переключатель беззвучного режима ВЫКЛЮЧЕН")
            print("🔊 2. 🔊 Громкость медиа 75%+ (проверено: достаточно)")
            print("🔊 3. 🎧 Обязательно подключите наушники!")
            print("🔊 4. 📢 Настройки > Звуки > Звуки кнопок ВКЛ")
            print("🔊 5. 🔄 Перезапустите iPhone если ничего не помогает")
            print("🔊 ==========================================")
        }
    }
    
    func checkSoundStatus() -> Bool {
        print("🔍 ADVANCED Sound status check:")
        
        // Проверяем доступность AVAudioPlayer'ов
        let correctPlayerReady = correctSoundPlayer?.prepareToPlay() ?? false
        let incorrectPlayerReady = incorrectSoundPlayer?.prepareToPlay() ?? false
        let timeoutPlayerReady = timeoutSoundPlayer?.prepareToPlay() ?? false
        
        print("🎵 Correct AVAudioPlayer ready: \(correctPlayerReady)")
        print("🎵 Incorrect AVAudioPlayer ready: \(incorrectPlayerReady)")
        print("🎵 Timeout AVAudioPlayer ready: \(timeoutPlayerReady)")
        
        // Получаем информацию о текущем аудио маршруте
        let currentRoute = audioSession.currentRoute
        print("📱 Current audio route:")
        for output in currentRoute.outputs {
            print("   - \(output.portName) (\(output.portType.rawValue))")
        }
        
        // Проверяем доступность звуков
        let outputAvailable = !currentRoute.outputs.isEmpty
        print("🔊 Audio output available: \(outputAvailable)")
        
        // Проверяем категорию аудиосессии
        print("🎵 Audio session category: \(audioSession.category.rawValue)")
        print("🎵 Audio session mode: \(audioSession.mode.rawValue)")
        print("🔊 Audio session volume: \(audioSession.outputVolume)")
        
        // КРИТИЧЕСКАЯ ПРОВЕРКА ГРОМКОСТИ
        let volume = audioSession.outputVolume
        if volume < 0.5 {
            print("🚨 ПРОБЛЕМА: Громкость медиа слишком низкая (\(Int(volume * 100))%)")
            print("🔧 РЕШЕНИЕ: Увеличьте громкость кнопками ⬆️ до 75%+")
        } else {
            print("✅ Громкость медиа достаточная (\(Int(volume * 100))%)")
        }
        
        print("⚠️ ВАЖНЫЕ НАСТРОЙКИ для iPhone:")
        print("1. 📱 Переключатель беззвучного режима = ВЫКЛЮЧЕН")
        print("2. 🔊 Громкость МЕДИА (кнопки ⬆️⬇️) = 75%+")
        print("3. 📢 Настройки > Звуки > Звуки кнопок = ВКЛ")
        print("4. 🎧 Если не слышно - ОБЯЗАТЕЛЬНО попробуйте наушники!")
        
        let playersReady = correctPlayerReady || incorrectPlayerReady || timeoutPlayerReady
        return outputAvailable && volume >= 0.3 && playersReady
    }
    
    // =====================================================
    // АУДИО ENGINE - БЕЗ ИЗМЕНЕНИЙ
    // =====================================================
    
    private func setupAudioEngine() {
        do {
            // ВАЖНО: Устанавливаем категорию ОДИН РАЗ и НЕ МЕНЯЕМ
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [
                .defaultToSpeaker,
                .allowBluetooth,
                .mixWithOthers
            ])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let inputNode = audioEngine.inputNode
            let outputNode = audioEngine.outputNode
            
            print("✅ AudioEngine setup completed (ADVANCED)")
            print("📝 InputNode: \(inputNode)")
            print("📝 OutputNode: \(outputNode)")
            
            audioEngineSetupCompleted = true
            
        } catch {
            print("❌ Failed to setup AudioEngine: \(error)")
            audioEngineSetupCompleted = false
        }
    }
    
    private func safelyStartAudioEngine() {
        guard audioEngineSetupCompleted else {
            print("❌ AudioEngine not properly setup")
            return
        }
        
        if audioEngine.isRunning {
            print("▶️ AudioEngine already running")
            audioEngineStarted = true
            return
        }
        
        do {
            try audioEngine.start()
            audioEngineStarted = true
            print("▶️ AudioEngine started safely")
        } catch {
            print("❌ Failed to start AudioEngine: \(error)")
            audioEngineStarted = false
        }
    }
    
    private func safelyStopAudioEngine() {
        guard audioEngine.isRunning else {
            print("🛑 AudioEngine already stopped")
            return
        }
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        audioEngine.stop()
        audioEngineStarted = false
        print("🛑 AudioEngine stopped safely")
    }
    
    private func cleanupRecognition() {
        print("🧹 Cleaning up recognition resources")
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        answerTimeout?.invalidate()
        answerTimeout = nil
        
        delayedProcessingTimer?.invalidate()
        delayedProcessingTimer = nil
        lastPartialResult = ""
        
        if audioEngine.isRunning {
            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
        }
        
        recognitionInProgress = false
        listeningInProgress = false
        isListening = false
        listeningForAnswers = false
        
        print("✅ Recognition cleanup completed")
    }
    
    // =====================================================
    // МЕТОДЫ ДЛЯ СОВМЕСТИМОСТИ
    // =====================================================
    
    func changeLanguage(to newLanguage: String) {
        toggleLanguage()
        print("🌍 SpeechManager: Language changed to \(newLanguage)")
    }
    
    func setup(gameManager: MathGameManager) {
        self.gameManager = gameManager
        print("🔧 SpeechManager: Setup completed with gameManager")
    }
    
    func setup(language: String) {
        print("🔧 SpeechManager: Setup with language: \(language)")
        if language == "en" {
            currentLanguage = "en-US"
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            if let englishVoice = AVSpeechSynthesisVoice(language: "en-US") {
                currentVoice = englishVoice
            }
        } else {
            currentLanguage = "ru-RU"
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
            let voices = AVSpeechSynthesisVoice.speechVoices()
            if let milenaVoice = voices.first(where: { $0.name.contains("Milena") && $0.language == "ru-RU" }) {
                currentVoice = milenaVoice
            } else if let russianVoice = AVSpeechSynthesisVoice(language: "ru-RU") {
                currentVoice = russianVoice
            }
        }
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 1.0
        utterance.voice = currentVoice
        synthesizer.speak(utterance)
        print("🗣️ SpeechManager: Speaking: \(text)")
    }
    
    func prepareForNewQuestion() {
        print("🆕 ===== PREPARING FOR NEW QUESTION =====")
        
        cleanupRecognition()
        
        currentQuestionId = UUID().uuidString
        print("✅ Prepared for new question with ID: \(currentQuestionId ?? "unknown")")
        
        answerTimeout = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: false) { _ in
            print("⏰ Question timeout reached")
            self.handleTimeout()
        }
        print("⏰ Question timer started for 25.0 seconds")
    }
    
    func speakQuestion(_ questionText: String) {
        print("🗣️ Speaking question: \(questionText) in language: \(currentLanguage)")
        
        guard !speechInProgress else {
            print("⚠️ Speech already in progress, skipping")
            return
        }
        
        speechInProgress = true
        
        if let voice = currentVoice {
            print("✅ Using voice: \(voice.name) (\(voice.language))")
        }
        
        let utterance = AVSpeechUtterance(string: questionText)
        utterance.rate = 0.5
        utterance.volume = 1.0
        utterance.voice = currentVoice
        
        synthesizer.speak(utterance)
        print("🗣️ ▶️ Speech started - will auto-start listening when finished")
    }
    
    func startListeningForAnswers() {
        print("👂 ===== ⚡ ADVANCED AUTO-LISTENING =====")
        
        guard !listeningInProgress else {
            print("⚠️ Listening already in progress, skipping")
            return
        }
        
        guard !recognitionInProgress else {
            print("⚠️ Recognition already in progress, skipping")
            return
        }
        
        guard let currentQuestionId = currentQuestionId else {
            print("❌ No current question ID")
            return
        }
        
        guard audioEngineSetupCompleted else {
            print("❌ AudioEngine not properly setup")
            return
        }
        
        print("⚡ ⚡ STARTING ADVANCED AUTO-LISTENING for question: \(currentQuestionId)")
        
        listeningInProgress = true
        recognitionInProgress = true
        isListening = true
        listeningForAnswers = true
        
        do {
            recognitionTask?.cancel()
            recognitionTask = nil
            recognitionRequest?.endAudio()
            recognitionRequest = nil
            
            safelyStartAudioEngine()
            
            guard audioEngineStarted else {
                print("❌ Failed to start AudioEngine")
                cleanupRecognition()
                return
            }
            
            let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest.shouldReportPartialResults = true
            
            print("⚡ ⚡ Creating ADVANCED recognition task...")
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                
                if let error = error {
                    print("❌ Recognition error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.cleanupRecognition()
                    }
                    return
                }
                
                if let result = result {
                    let recognizedText = result.bestTranscription.formattedString.lowercased()
                    
                    print("🎯 ⚡ Recognition: '\(result.bestTranscription.formattedString)' (final: \(result.isFinal))")
                    
                    DispatchQueue.main.async {
                        self.lastRecognizedText = result.bestTranscription.formattedString
                    }
                    
                    if currentQuestionId == self.currentQuestionId {
                        if result.isFinal {
                            print("📝 Final result - processing immediately: '\(recognizedText)'")
                            self.processRecognizedText(recognizedText)
                        } else {
                            self.scheduleDelayedProcessing(recognizedText, questionId: currentQuestionId)
                        }
                    } else {
                        print("🗑️ Ignoring result from previous question")
                    }
                }
            }
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.removeTap(onBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            self.recognitionRequest = recognitionRequest
            print("✅ ⚡ ADVANCED Recognition setup completed - ready for answers!")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
                if self.listeningForAnswers && self.currentQuestionId == currentQuestionId {
                    print("⏰ Answer timeout reached")
                    self.handleTimeout()
                }
            }
            
        } catch {
            print("❌ Failed to start listening: \(error)")
            cleanupRecognition()
        }
    }
    
    func stopListeningForAnswers() {
        print("🔇 ===== STOPPING LISTENING FOR ANSWERS =====")
        
        listeningForAnswers = false
        
        answerTimeout?.invalidate()
        answerTimeout = nil
        
        delayedProcessingTimer?.invalidate()
        delayedProcessingTimer = nil
        
        recognitionInProgress = false
        
        print("✅ Answer listening stopped")
    }
    
    private func scheduleDelayedProcessing(_ text: String, questionId: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ Empty text in delayed processing - skipping")
            return
        }
        
        guard recognitionInProgress else {
            print("⚠️ Recognition blocked - skipping delayed processing")
            return
        }
        
        delayedProcessingTimer?.invalidate()
        lastPartialResult = text
        
        delayedProcessingTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
            if questionId == self.currentQuestionId && self.recognitionInProgress {
                print("⏰ Processing delayed result after pause: '\(text)'")
                self.processRecognizedText(text)
            } else {
                print("⚠️ Skipping delayed processing - question changed or recognition blocked")
            }
        }
        
        print("⏱️ Scheduled FAST delayed processing for: '\(text)'")
    }
    
    private func processRecognizedText(_ text: String) {
        print("⚡ Processing recognized text: '\(text)'")
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ Empty text - ignoring")
            return
        }
        
        Task { @MainActor in
            guard let gameManager = gameManager, gameManager.isRunning else {
                print("⚠️ Game not running - ignoring recognition result")
                return
            }
            
            if let number = extractNumber(from: text) {
                print("⚡ Found number: \(number)")
                print("📞 Calling gameManager.checkAnswer(\(number))")
                
                recognitionInProgress = false
                
                delayedProcessingTimer?.invalidate()
                delayedProcessingTimer = nil
                
                stopListeningForAnswers()
                
                gameManager.checkAnswer(number)
            }
        }
    }
    
    private func extractNumber(from text: String) -> Int? {
        print("🔍 Extracting from: '\(text)'")
        
        let complexNumbers: [String: Int] = [
            "двадцать один": 21, "двадцать два": 22, "двадцать три": 23, "двадцать четыре": 24, "двадцать пять": 25,
            "двадцать шесть": 26, "двадцать семь": 27, "двадцать восемь": 28, "двадцать девять": 29,
            "тридцать один": 31, "тридцать два": 32, "тридцать три": 33, "тридцать четыре": 34, "тридцать пять": 35,
            "тридцать шесть": 36, "тридцать семь": 37, "тридцать восемь": 38, "тридцать девять": 39,
            "сорок один": 41, "сорок два": 42, "сорок три": 43, "сорок четыре": 44, "сорок пять": 45,
            "сорок шесть": 46, "сорок семь": 47, "сорок восемь": 48, "сорок девять": 49,
            "пятьдесят один": 51, "пятьдесят два": 52, "пятьдесят три": 53, "пятьдесят четыре": 54, "пятьдесят пять": 55,
            "пятьдесят шесть": 56, "пятьдесят семь": 57, "пятьдесят восемь": 58, "пятьдесят девять": 59,
            "шестьдесят один": 61, "шестьдесят два": 62, "шестьдесят три": 63, "шестьдесят четыре": 64, "шестьдесят пять": 65,
            "шестьдесят шесть": 66, "шестьдесят семь": 67, "шестьдесят восемь": 68, "шестьдесят девять": 69,
            "семьдесят один": 71, "семьдесят два": 72, "семьдесят три": 73, "семьдесят четыре": 74, "семьдесят пять": 75,
            "семьдесят шесть": 76, "семьдесят семь": 77, "семьдесят восемь": 78, "семьдесят девять": 79,
            "восемьдесят один": 81, "восемьдесят два": 82, "восемьдесят три": 83, "восемьдесят четыре": 84, "восемьдесят пять": 85,
            "восемьдесят шесть": 86, "восемьдесят семь": 87, "восемьдесят восемь": 88, "восемьдесят девять": 89,
            "девяносто один": 91, "девяносто два": 92, "девяносто три": 93, "девяносто четыре": 94, "девяносто пять": 95,
            "девяносто шесть": 96, "девяносто семь": 97, "девяносто восемь": 98, "девяносто девять": 99,
            
            "twenty one": 21, "twenty two": 22, "twenty three": 23, "twenty four": 24, "twenty five": 25,
            "twenty six": 26, "twenty seven": 27, "twenty eight": 28, "twenty nine": 29,
            "thirty one": 31, "thirty two": 32, "thirty three": 33, "thirty four": 34, "thirty five": 35,
            "thirty six": 36, "thirty seven": 37, "thirty eight": 38, "thirty nine": 39,
            "forty one": 41, "forty two": 42, "forty three": 43, "forty four": 44, "forty five": 45,
            "forty six": 46, "forty seven": 47, "forty eight": 48, "forty nine": 49,
            "fifty one": 51, "fifty two": 52, "fifty three": 53, "fifty four": 54, "fifty five": 55,
            "fifty six": 56, "fifty seven": 57, "fifty eight": 58, "fifty nine": 59,
            "sixty one": 61, "sixty two": 62, "sixty three": 63, "sixty four": 64, "sixty five": 65,
            "sixty six": 66, "sixty seven": 67, "sixty eight": 68, "sixty nine": 69,
            "seventy one": 71, "seventy two": 72, "seventy three": 73, "seventy four": 74, "seventy five": 75,
            "seventy six": 76, "seventy seven": 77, "seventy eight": 78, "seventy nine": 79,
            "eighty one": 81, "eighty two": 82, "eighty three": 83, "eighty four": 84, "eighty five": 85,
            "eighty six": 86, "eighty seven": 87, "eighty eight": 88, "eighty nine": 89,
            "ninety one": 91, "ninety two": 92, "ninety three": 93, "ninety four": 94, "ninety five": 95,
            "ninety six": 96, "ninety seven": 97, "ninety eight": 98, "ninety nine": 99
        ]
        
        for (phrase, number) in complexNumbers {
            if text.contains(phrase) {
                print("🎯 Found complex number match: \(number)")
                return number
            }
        }
        
        let numberWords: [String: Int] = [
            "ноль": 0, "один": 1, "одна": 1, "два": 2, "две": 2, "три": 3, "четыре": 4, "пять": 5,
            "шесть": 6, "семь": 7, "восемь": 8, "девять": 9, "десять": 10,
            "одиннадцать": 11, "двенадцать": 12, "тринадцать": 13, "четырнадцать": 14, "пятнадцать": 15,
            "шестнадцать": 16, "семнадцать": 17, "восемнадцать": 18, "девятнадцать": 19,
            "двадцать": 20, "тридцать": 30, "сорок": 40, "пятьдесят": 50, "шестьдесят": 60,
            "семьдесят": 70, "восемьдесят": 80, "девяносто": 90, "сто": 100,
            
            "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
            "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19,
            "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60,
            "seventy": 70, "eighty": 80, "ninety": 90, "hundred": 100, "one hundred": 100
        ]
        
        for (word, number) in numberWords {
            if text.contains(word) {
                print("🎯 Found simple word match: \(number)")
                return number
            }
        }
        
        if let regex = try? NSRegularExpression(pattern: "\\d+") {
            let range = NSRange(location: 0, length: text.utf16.count)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let range = Range(match.range, in: text) {
                    let numberString = String(text[range])
                    if let number = Int(numberString) {
                        print("🎯 Found regex match: \(number)")
                        return number
                    }
                }
            }
        }
        
        print("❌ No number found in: '\(text)'")
        return nil
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("✅ Speech recognition authorized")
                case .denied:
                    print("❌ Speech recognition authorization denied")
                case .restricted:
                    print("❌ Speech recognition restricted")
                case .notDetermined:
                    print("❌ Speech recognition not determined")
                @unknown default:
                    break
                }
            }
        }
    }
    
    func startListening() {
        print("🎤 ===== ACTIVATING MICROPHONE =====")
        
        guard !microphoneActive else {
            print("✅ Microphone already active")
            return
        }
        
        microphoneActive = true
        
        if !audioEngineSetupCompleted {
            setupAudioEngine()
        }
        
        if audioEngineSetupCompleted {
            print("✅ Audio engine ready - microphone is now ACTIVE")
        } else {
            print("❌ Failed to setup audio engine")
            microphoneActive = false
        }
    }
    
    private func handleTimeout() {
        print("⏰ ===== TIMEOUT REACHED =====")
        
        Task { @MainActor in
            guard let gameManager = gameManager, gameManager.isRunning else {
                print("⚠️ Game not running - skipping timeout handling")
                return
            }
            
            playTimeoutSound()
            cleanupRecognition()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard gameManager.isRunning else {
                    print("⚠️ Game ended during timeout - not processing timeout")
                    return
                }
                
                print("⏰ Processing timeout as skipped question")
                gameManager.skipQuestion()
            }
        }
    }
    
    func stopListening() {
        print("🔇 ===== STOPPING LISTENING =====")
        
        microphoneActive = false
        cleanupRecognition()
        
        if audioEngine.isRunning {
            audioEngine.stop()
            print("🔇 AudioEngine stopped")
        }
        
        synthesizer.stopSpeaking(at: .immediate)
        
        print("✅ All audio processes stopped")
    }
    
    func toggleLanguage() {
        if currentLanguage == "ru-RU" {
            currentLanguage = "en-US"
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            if let englishVoice = AVSpeechSynthesisVoice(language: "en-US") {
                currentVoice = englishVoice
            }
        } else {
            currentLanguage = "ru-RU"
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
            let voices = AVSpeechSynthesisVoice.speechVoices()
            if let milenaVoice = voices.first(where: { $0.name.contains("Milena") && $0.language == "ru-RU" }) {
                currentVoice = milenaVoice
            } else if let russianVoice = AVSpeechSynthesisVoice(language: "ru-RU") {
                currentVoice = russianVoice
            }
        }
        
        print("🌍 Language toggled to: \(currentLanguage)")
        print("🗣️ Voice changed to: \(currentVoice?.name ?? "default")")
        print("👂 Speech recognizer updated for: \(currentLanguage)")
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("🗣️ ⏹️ ⚡ Speech FINISHED - starting listening...")
        speechInProgress = false
        
        DispatchQueue.main.async {
            guard let gameManager = self.gameManager, gameManager.isRunning else {
                print("⚠️ Game not running - NOT starting listening after speech")
                return
            }
            
            if self.currentQuestionId != nil && !self.listeningInProgress {
                print("👂 ⚡ AUTO-STARTING listening after speech!")
                self.startListeningForAnswers()
            } else {
                print("⚠️ Cannot start listening - no question or already listening")
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("🗣️ ▶️ Speech started")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("🗣️ ❌ Speech cancelled")
        speechInProgress = false
    }
    
    // MARK: - Cleanup
    deinit {
        synthesizer.stopSpeaking(at: .immediate)
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        print("🗑️ SpeechManager deinitalized - all audio stopped")
    }
}
