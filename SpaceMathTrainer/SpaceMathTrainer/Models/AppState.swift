import SwiftUI
import UIKit
import AudioToolbox
import AVFoundation

class AppState: ObservableObject {
    @Published var selectedOperations: Set<MathOperation> = [.addition]
    @Published var selectedDifficulty: Difficulty = .easy
    @Published var tasksCount: Int = 10
    @Published var answerTimeLimit: Double = 15.0 {
        didSet {
            if answerTimeLimit > 30.0 {
                answerTimeLimit = 30.0
            }
        }
    }
    
    // ОБНОВЛЕНО: selectedMultiplier теперь поддерживает случайный режим
    // 0 = случайный режим (1-9), 2-9 = конкретная таблица
    @Published var selectedMultiplier: Int = 2
    
    // MARK: - Localization Support
    @Published var selectedLanguage: String = "ru"
    
    var availableLanguages: [String] {
        return ["ru", "en"]
    }
    
    // УЛУЧШЕННАЯ синхронизация с SpeechManager для iPhone
    func changeLanguage(to newLanguage: String) {
        print("🌍 AppState: Changing language from \(selectedLanguage) to \(newLanguage)")
        
        // Проверяем, действительно ли язык меняется
        guard selectedLanguage != newLanguage else {
            print("🌍 AppState: Language already is \(newLanguage), no change needed")
            return
        }
        
        // ДОПОЛНИТЕЛЬНАЯ тактильная обратная связь для смены языка на iPhone
        DispatchQueue.main.async {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            // Дополнительный звук для смены языка
            AudioServicesPlaySystemSound(1100) // Camera_Shutter звук для переключения
        }
        
        // Обновляем язык немедленно
        selectedLanguage = newLanguage
        
        // КРИТИЧЕСКИ ВАЖНО: Принудительно обновляем SpeechManager
        DispatchQueue.main.async {
            if let speechManager = self.getSpeechManager() as? SpeechManager {
                print("🔄 AppState: Immediately notifying SpeechManager about language change")
                speechManager.changeLanguage(to: newLanguage)
            } else {
                print("⚠️ AppState: SpeechManager not found!")
                
                // Попытка найти SpeechManager через небольшую задержку
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let speechManager = self.getSpeechManager() as? SpeechManager {
                        print("🔄 AppState: Found SpeechManager with delay, notifying about language change")
                        speechManager.changeLanguage(to: newLanguage)
                    }
                }
            }
        }
    }
    
    // НОВЫЙ МЕТОД: toggleLanguage для совместимости с ContentView
    func toggleLanguage() {
        let newLanguage = selectedLanguage == "ru" ? "en" : "ru"
        changeLanguage(to: newLanguage)
        print("🔄 AppState: Language toggled to \(selectedLanguage)")
    }
    
    // MARK: - Compatibility Properties
    var currentLanguage: String {
        get {
            // ИСПРАВЛЕНО: Возвращаем полный код локали для SpeechManager
            switch selectedLanguage {
            case "en": return "en-US"
            case "ru": return "ru-RU"
            default: return selectedLanguage
            }
        }
        set {
            // Конвертируем обратно в простой код
            if newValue.hasPrefix("en") {
                selectedLanguage = "en"
            } else if newValue.hasPrefix("ru") {
                selectedLanguage = "ru"
            } else {
                selectedLanguage = newValue
            }
        }
    }
    
    var currentDifficulty: Difficulty {
        get { selectedDifficulty }
        set { selectedDifficulty = newValue }
    }
    
    func localizedString(_ key: String) -> String {
        switch selectedLanguage {
        case "en":
            return getEnglishString(key)
        default:
            return getRussianString(key)
        }
    }
    
    private func getEnglishString(_ key: String) -> String {
        switch key {
        // Main menu
        case "practice": return "PRACTICE"
        case "statistics": return "STATISTICS"
        case "settings": return "SETTINGS"
        case "start_mission": return "START MISSION"
        case "launch_mission": return "LAUNCH MISSION"
        case "exit": return "EXIT"
        case "menu": return "MENU"
        case "restart": return "RESTART"
        case "game_complete": return "MISSION COMPLETE"
        
        // Language and interface
        case "language": return "LANGUAGE"
        case "language_title": return "LANGUAGE"
        case "app_title_cosmic": return "COSMIC"
        case "app_title_math": return "MATH TRAINER"
        case "app_title": return "MATH TRAINER" // НОВОЕ для ContentView
        
        // Operations
        case "operations": return "OPERATIONS"
        case "operations_title": return "OPERATIONS"
        case "addition": return "Addition"
        case "subtraction": return "Subtraction"
        case "multiplication": return "Multiplication"
        case "multiplicationTable": return "Multiplication Table" // НОВОЕ
        case "division": return "Division"
        
        // Операции как символы (для поддержки MathOperation.rawValue)
        case "+": return "Addition"
        case "−": return "Subtraction"
        case "×": return "Multiplication"
        case "table×": return "Multiplication Table"
        case "÷": return "Division"
        
        // НОВЫЕ ПЕРЕВОДЫ для модального окна
        case "randomMultipliers": return "Random multipliers"
        case "from2to9": return "from 2 to 9"
        case "chooseMultiplicand": return "Choose multiplicand:"
        case "close": return "Close"
        
        // Multiplier selection
        case "select_multiplier": return "Select Number"
        case "multiplication_table_for": return "Multiplication table for %@"
        case "example_questions": return "Example questions:"
        
        // Difficulty
        case "difficulty": return "DIFFICULTY"
        case "difficulty_title": return "DIFFICULTY"
        case "easy": return "Easy"
        case "medium": return "Medium"
        case "hard": return "Hard"
        
        // Parameters
        case "parameters_title": return "SETTINGS"
        case "tasks_count": return "Number of Problems"
        case "answer_time": return "Time per Problem"
        case "time_limit": return "Time Limit"
        case "seconds": return "sec"
        
        // Game interface
        case "mission_active": return "MISSION ACTIVE"
        case "score": return "SCORE"
        case "task_of": return "Problem %@ of %@"
        
        // Microphone and speech
        case "microphone_active": return "MICROPHONE ON"
        case "microphone_off": return "MICROPHONE OFF"
        case "listening": return "Listening for your answer..."
        case "say_answer": return "Say your answer aloud"
        case "recognized": return "Heard:"
        
        // Controls
        case "repeat": return "REPEAT"
        case "skip": return "SKIP"
        case "finish": return "FINISH"
        case "start_training": return "START TRAINING" // НОВОЕ
        case "stop_training": return "STOP" // НОВОЕ
        case "repeat_question": return "REPEAT" // НОВОЕ
        case "skip_question": return "SKIP" // НОВОЕ
        
        // Status messages
        case "correct": return "✅ Correct!"
        case "incorrect": return "❌ Wrong! Answer: %@"
        case "timeout": return "⏰ Time's up! Answer: %@"
        case "skipped": return "⏭️ Skipped! Answer: %@"
        case "training_complete": return "Training complete! Score: %@ out of %@ (%@%%)"
        
        // Speech operations (for voice synthesis)
        case "plus": return "plus"
        case "minus": return "minus"
        case "times": return "times"
        case "divided_by": return "divided by"
        
        default: return key.uppercased()
        }
    }
    
    private func getRussianString(_ key: String) -> String {
        switch key {
        // Main menu
        case "practice": return "ПРАКТИКА"
        case "statistics": return "СТАТИСТИКА"
        case "settings": return "НАСТРОЙКИ"
        case "start_mission": return "ЗАПУСТИТЬ МИССИЮ"
        case "launch_mission": return "ЗАПУСТИТЬ МИССИЮ"
        case "exit": return "ВЫХОД"
        case "menu": return "МЕНЮ"
        case "restart": return "ПОВТОРИТЬ"
        case "game_complete": return "МИССИЯ ЗАВЕРШЕНА"
        
        // Language and interface
        case "language": return "ЯЗЫК"
        case "language_title": return "ЯЗЫК"
        case "app_title_cosmic": return "КОСМИЧЕСКИЙ"
        case "app_title_math": return "МАТЕМАТИЧЕСКИЙ ТРЕНАЖЁР"
        case "app_title": return "Математический тренажёр" // НОВОЕ для ContentView
        
        // Operations
        case "operations": return "ОПЕРАЦИИ"
        case "operations_title": return "ОПЕРАЦИИ"
        case "addition": return "Сложение"
        case "subtraction": return "Вычитание"
        case "multiplication": return "Умножение"
        case "multiplicationTable": return "Таблица умножения" // НОВОЕ
        case "division": return "Деление"
        
        // Операции как символы (для поддержки MathOperation.rawValue)
        case "+": return "Сложение"
        case "−": return "Вычитание"
        case "×": return "Умножение"
        case "table×": return "Таблица умножения"
        case "÷": return "Деление"
        
        // НОВЫЕ ПЕРЕВОДЫ для модального окна
        case "randomMultipliers": return "Случайные множители"
        case "from2to9": return "от 2 до 9"
        case "chooseMultiplicand": return "Выбор множимого:"
        case "close": return "Закрыть"
        
        // Multiplier selection
        case "select_multiplier": return "Выбрать число"
        case "multiplication_table_for": return "Таблица умножения на %@"
        case "example_questions": return "Примеры вопросов:"
        
        // Difficulty
        case "difficulty": return "СЛОЖНОСТЬ"
        case "difficulty_title": return "СЛОЖНОСТЬ"
        case "easy": return "Лёгкий"
        case "medium": return "Средний"
        case "hard": return "Сложный"
        
        // Parameters
        case "parameters_title": return "ПАРАМЕТРЫ"
        case "tasks_count": return "Количество заданий"
        case "answer_time": return "Время на ответ"
        case "time_limit": return "Время на ответ"
        case "seconds": return "сек"
        
        // Game interface
        case "mission_active": return "МИССИЯ АКТИВНА"
        case "score": return "СЧЁТ"
        case "task_of": return "Задание %@ из %@"
        
        // Microphone and speech
        case "microphone_active": return "МИКРОФОН ВКЛЮЧЁН"
        case "microphone_off": return "МИКРОФОН ВЫКЛЮЧЕН"
        case "listening": return "Слушаю ваш ответ..."
        case "say_answer": return "Скажите ответ в микрофон"
        case "recognized": return "Распознано:"
        
        // Controls
        case "repeat": return "ПОВТОРИТЬ"
        case "skip": return "ПРОПУСТИТЬ"
        case "finish": return "ЗАВЕРШИТЬ"
        case "start_training": return "Начать тренировку" // НОВОЕ
        case "stop_training": return "Остановить" // НОВОЕ
        case "repeat_question": return "Повторить" // НОВОЕ
        case "skip_question": return "Пропустить" // НОВОЕ
        
        // Status messages
        case "correct": return "✅ Правильно!"
        case "incorrect": return "❌ Неправильно! Ответ: %@"
        case "timeout": return "⏰ Время вышло! Ответ: %@"
        case "skipped": return "⏭️ Пропущено! Ответ: %@"
        case "training_complete": return "Тренировка завершена! Результат: %@ из %@ (%@%%)"
        
        // Speech operations (for voice synthesis)
        case "plus": return "плюс"
        case "minus": return "минус"
        case "times": return "умножить на"
        case "divided_by": return "разделить на"
        
        default: return key.uppercased()
        }
    }
    
    // MARK: - Speech Manager Support (УЛУЧШЕНО для iPhone)
    private weak var speechManager: AnyObject?
    
    func setSpeechManager(_ manager: Any?) {
        print("🔗 AppState: Setting SpeechManager reference")
        self.speechManager = manager as AnyObject
        
        // НЕМЕДЛЕННО синхронизируем язык при установке связи
        if let speechManager = manager as? SpeechManager {
            print("🔄 AppState: Immediately syncing language with newly set SpeechManager")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                speechManager.setup(language: self.selectedLanguage)
            }
        }
    }
    
    func getSpeechManager() -> Any? {
        return speechManager
    }
    
    // MARK: - Validation
    var canLaunch: Bool {
        !selectedOperations.isEmpty
    }
    
    // MARK: - Operation Management с тактильной обратной связью для iPhone
    func toggleOperation(_ operation: MathOperation) {
        // Добавляем тактильную обратную связь для переключения операций
        DispatchQueue.main.async {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            // Звук для переключения операций
            AudioServicesPlaySystemSound(1102) // Tweet звук для переключения
        }
        
        if selectedOperations.contains(operation) {
            if selectedOperations.count > 1 {
                selectedOperations.remove(operation)
            }
        } else {
            selectedOperations.insert(operation)
        }
    }
    
    func canDeselectOperation(_ operation: MathOperation) -> Bool {
        return selectedOperations.count > 1 || !selectedOperations.contains(operation)
    }
    
    // MARK: - Helper Methods
    func getLocalizedOperationName(_ operation: MathOperation) -> String {
        switch operation {
        case .addition: return localizedString("addition")
        case .subtraction: return localizedString("subtraction")
        case .multiplicationTable: return localizedString("multiplicationTable") // ОБНОВЛЕНО
        case .division: return localizedString("division")
        }
    }
    
    func getLocalizedDifficultyName(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy: return localizedString("easy")
        case .medium: return localizedString("medium")
        case .hard: return localizedString("hard")
        }
    }
    
    // MARK: - Speech Operation Names
    func getLocalizedOperationSpeech(_ operation: MathOperation) -> String {
        // ОБНОВЛЕНО: добавлена поддержка случайного режима для таблицы умножения
        if operation == .multiplicationTable {
            // И для случайного, и для конкретного режима используем "умножить на"
            return selectedLanguage == "ru" ? "умножить на" : "times"
        }
        
        switch operation {
        case .addition: return localizedString("plus")
        case .subtraction: return localizedString("minus")
        case .multiplicationTable: return localizedString("times") // НОВОЕ: тоже "умножить на"
        case .division: return localizedString("divided_by")
        }
    }
    
    // MARK: - УЛУЧШЕННЫЙ МЕТОД: Тестирование голоса с обратной связью для iPhone
    func testCurrentVoice() {
        guard let speechManager = getSpeechManager() as? SpeechManager else {
            print("⚠️ AppState: No SpeechManager available for voice test")
            return
        }
        
        // Добавляем тактильную обратную связь для тестирования голоса
        DispatchQueue.main.async {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            // Звук для тестирования голоса
            AudioServicesPlaySystemSound(1101) // Calendar_Alert звук для теста
        }
        
        let testText = selectedLanguage == "en" ? "Hello, this is a voice test" : "Привет, это тест голоса"
        print("🎤 AppState: Testing voice with text: '\(testText)'")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            speechManager.speak(testText)
        }
    }
    
    // MARK: - НОВЫЕ МЕТОДЫ: Управление звуками и обратной связью для iPhone
    
    // Воспроизведение звука успешного действия
    func playSuccessSound() {
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1016) // Success sound
            
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        }
    }
    
    // Воспроизведение звука предупреждения
    func playWarningSound() {
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1057) // Tink sound
            
            let warningFeedback = UINotificationFeedbackGenerator()
            warningFeedback.notificationOccurred(.warning)
        }
    }
    
    // Воспроизведение звука ошибки
    func playErrorSound() {
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1073) // Sosumi sound
            
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
    }
    
    // Простая вибрация
    func playVibration() {
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    // MARK: - ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ для удобства разработки
    
    // Проверка доступности микрофона
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    // Инициализация аудио сессии для лучшей совместимости с iPhone
    func initializeAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("✅ AppState: Audio session initialized successfully")
        } catch {
            print("❌ AppState: Failed to initialize audio session: \(error)")
        }
    }
    
    // Сброс настроек к значениям по умолчанию
    func resetToDefaults() {
        selectedOperations = [.addition]
        selectedDifficulty = .easy
        tasksCount = 10
        answerTimeLimit = 15.0
        selectedLanguage = "ru"
        selectedMultiplier = 2 // НОВОЕ
        
        // Звук сброса настроек
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1110) // Begin_Record звук для сброса
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
        
        print("🔄 AppState: Settings reset to defaults")
    }
    
    // MARK: - НОВЫЕ МЕТОДЫ: Поддержка случайного режима таблицы умножения
    
    // Проверка, включен ли случайный режим
    var isRandomMultiplierMode: Bool {
        return selectedMultiplier == 0
    }
    
    // Получение описания текущего режима множителя
    func getMultiplierModeDescription() -> String {
        if isRandomMultiplierMode {
            return selectedLanguage == "ru" ? "Случайные множители (1-9)" : "Random multipliers (1-9)"
        } else {
            return selectedLanguage == "ru" ? "Таблица умножения на \(selectedMultiplier)" : "Multiplication table ×\(selectedMultiplier)"
        }
    }
    
    // Получение случайного множителя для случайного режима (БЕЗ НУЛЯ)
    func getRandomMultiplier() -> Int {
        return Int.random(in: 1...9) // ИСКЛЮЧИЛИ НОЛЬ
    }
}
