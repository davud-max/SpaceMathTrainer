import SwiftUI
import AVFoundation
import Speech

@main
struct SpaceMathTrainerApp: App {
    
    init() {
        // КРИТИЧЕСКИ ВАЖНО: Настройка приложения для iPhone звуков и речи
        setupAppForiPhone()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // Темная тема для космического дизайна
                .statusBarHidden() // Скрываем статус бар для полного погружения
                .onAppear {
                    // Дополнительная настройка при появлении приложения
                    requestPermissions()
                }
        }
    }
    
    // MARK: - Настройка приложения для iPhone
    private func setupAppForiPhone() {
        print("🚀 SpaceMathTrainerApp: Initializing for iPhone...")
        
        // Настройка аудио сессии для поддержки звуков и речи
        configureAudioSession()
        
        // Подготовка генераторов тактильной обратной связи
        prepareHapticFeedback()
        
        print("✅ SpaceMathTrainerApp: iPhone setup completed")
    }
    
    // MARK: - Настройка аудио сессии
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // ВАЖНО: Настройка категории для воспроизведения звуков И записи речи
            try audioSession.setCategory(.playAndRecord,
                                       mode: .default,
                                       options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ Audio session configured successfully")
            
        } catch {
            print("❌ Failed to configure audio session: \(error)")
            
            // FALLBACK: Пробуем более простую настройку
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback)
                try audioSession.setActive(true)
                print("⚠️ Using fallback audio session configuration")
            } catch {
                print("❌ Even fallback audio session failed: \(error)")
            }
        }
    }
    
    // MARK: - Подготовка тактильной обратной связи
    private func prepareHapticFeedback() {
        // Подготавливаем генераторы для быстрого отклика
        let impactLight = UIImpactFeedbackGenerator(style: .light)
        let impactMedium = UIImpactFeedbackGenerator(style: .medium)
        let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
        let notificationFeedback = UINotificationFeedbackGenerator()
        
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationFeedback.prepare()
        
        print("✅ Haptic feedback generators prepared")
    }
    
    // MARK: - Запрос разрешений
    private func requestPermissions() {
        print("🔐 Requesting necessary permissions...")
        
        // Запрос разрешения на использование микрофона
        requestMicrophonePermission()
        
        // Запрос разрешения на распознавание речи
        requestSpeechRecognitionPermission()
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Microphone permission granted")
                } else {
                    print("❌ Microphone permission denied")
                    // Можно показать пользователю предупреждение
                }
            }
        }
    }
    
    private func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Speech recognition permission granted")
                case .denied:
                    print("❌ Speech recognition permission denied")
                case .restricted:
                    print("⚠️ Speech recognition restricted")
                case .notDetermined:
                    print("⏳ Speech recognition permission not determined")
                @unknown default:
                    print("❓ Unknown speech recognition permission status")
                }
            }
        }
    }
}
