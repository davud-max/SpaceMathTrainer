import Foundation
import AVFoundation
import Speech

@MainActor
class MathGameManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isRunning = false
    @Published var currentQuestion = ""
    @Published var currentTaskIndex = 0
    @Published var correctAnswers = 0
    @Published var totalAnswers = 0
    @Published var statusMessage = ""
    @Published var statusType = ""
    @Published var gameResults: [TaskResult] = []
    
    // MARK: - Internal Properties
    private var tasks: [MathTask] = []
    private var currentTask: MathTask?
    private var correctAnswer: Int = 0
    private var questionStartTime: Date = Date()
    
    // MARK: - Dependencies
    weak var appState: AppState?
    weak var speechManager: SpeechManager?
    
    // MARK: - Audio Engine
    private var audioEngine = AVAudioEngine()
    private var speechSynthesizer = AVSpeechSynthesizer()
    
    // MARK: - Task Result Structure
    struct TaskResult {
        let question: String
        let userAnswer: String
        let correctAnswer: Int
        let isCorrect: Bool
        let responseTime: TimeInterval
        let timestamp: Date
    }
    
    // MARK: - Math Task Structure
    struct MathTask {
        let operation: MathOperation
        let operand1: Int
        let operand2: Int
        let correctAnswer: Int
        
        var questionText: String {
            return "\(operand1) \(operation.rawValue) \(operand2) = ?"
        }
        
        // НОВОЕ: Текст для произношения БЕЗ знака "=" и с правильными операциями
        var spokenText: String {
            return getSpokenText(language: "ru") // По умолчанию русский
        }
        
        // НОВОЕ: Метод для получения произношения на разных языках
        func getSpokenText(language: String) -> String {
            let operationWord: String
            
            if language == "en" {
                switch operation {
                case .addition:
                    operationWord = "plus"
                case .subtraction:
                    operationWord = "minus"
                case .multiplicationTable:
                    operationWord = "multiply by" // ИСПРАВЛЕНО: четкое произношение
                case .division:
                    operationWord = "divide by" // ИСПРАВЛЕНО: четкое произношение
                }
            } else {
                switch operation {
                case .addition:
                    operationWord = "плюс"
                case .subtraction:
                    operationWord = "минус"
                case .multiplicationTable:
                    operationWord = "умножить на"
                case .division:
                    operationWord = "разделить на"
                }
            }
            
            return "\(operand1) \(operationWord) \(operand2)"
        }
    }
    
    // MARK: - Game Control Methods
    func startTraining() {
        print("🚀 Starting training...")
        
        guard let appState = appState else {
            print("❌ AppState not available")
            return
        }
        
        // Генерируем задачи
        generateTasks()
        
        // Инициализируем игру
        isRunning = true
        currentTaskIndex = 0
        correctAnswers = 0
        totalAnswers = 0
        gameResults.removeAll()
        statusMessage = ""
        statusType = ""
        
        // УБРАНО: Тест звуков во время игры - это мешает
        // speechManager?.testReliableSounds()
        
        // НОВОЕ: Проверяем статус звуковой системы БЕЗ тестирования
        let soundsWorking = speechManager?.checkSoundStatus() ?? false
        if !soundsWorking {
            print("⚠️ Sound system may have issues - check audio setup")
        } else {
            print("🔊 Sound system ready - you WILL hear sounds during gameplay!")
        }
        
        // НОВОЕ: Автоматически включаем микрофон при старте тренировки
        speechManager?.startListening()
        print("🎤 Microphone activated automatically")
        
        // Запускаем первую задачу
        presentNextTask()
        
        print("✅ Training started with \(tasks.count) tasks")
    }
    
    func endTraining() {
        print("🏁 Ending training...")
        
        // КРИТИЧЕСКИ ВАЖНО: Сначала останавливаем все процессы
        isRunning = false
        
        // Останавливаем прослушивание
        speechManager?.stopListeningForAnswers()
        speechManager?.stopListening()
        
        // Останавливаем речь
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        // Очищаем состояние
        currentQuestion = ""
        statusMessage = ""
        statusType = ""
        currentTask = nil
        
        // Показываем результаты
        showFinalResults()
        
        print("✅ Training ended - all processes stopped")
    }
    
    // MARK: - Task Generation
    private func generateTasks() {
        guard let appState = appState else { return }
        
        tasks.removeAll()
        let taskCount = appState.tasksCount
        let selectedOperations = appState.selectedOperations
        let difficulty = appState.selectedDifficulty
        
        print("🎯 Generating \(taskCount) tasks for operations: \(selectedOperations)")
        
        for _ in 0..<taskCount {
            if let operation = selectedOperations.randomElement() {
                let task = generateTask(for: operation, difficulty: difficulty)
                tasks.append(task)
            }
        }
        
        // Перемешиваем задачи
        tasks.shuffle()
        
        print("✅ Generated \(tasks.count) tasks")
    }
    
    private func generateTask(for operation: MathOperation, difficulty: Difficulty) -> MathTask {
        switch operation {
        case .addition:
            return generateAdditionTask(difficulty: difficulty)
        case .subtraction:
            return generateSubtractionTask(difficulty: difficulty)
        case .multiplicationTable: // ИСПРАВЛЕНО: было .multiplication
            return generateMultiplicationTableTask(difficulty: difficulty)
        case .division:
            return generateDivisionTask(difficulty: difficulty)
        }
    }
    
    // MARK: - Operation-specific Task Generation
    private func generateAdditionTask(difficulty: Difficulty) -> MathTask {
        let (min, max) = getRangeForDifficulty(difficulty)
        let operand1 = Int.random(in: min...max)
        let operand2 = Int.random(in: min...max)
        let answer = operand1 + operand2
        
        return MathTask(
            operation: .addition,
            operand1: operand1,
            operand2: operand2,
            correctAnswer: answer
        )
    }
    
    private func generateSubtractionTask(difficulty: Difficulty) -> MathTask {
        let (min, max) = getRangeForDifficulty(difficulty)
        let operand1 = Int.random(in: min...max)
        let operand2 = Int.random(in: min...operand1) // Ensure positive result
        let answer = operand1 - operand2
        
        return MathTask(
            operation: .subtraction,
            operand1: operand1,
            operand2: operand2,
            correctAnswer: answer
        )
    }
    
    // ИСПРАВЛЕНО: Переименован метод и исправлен operation
    private func generateGeneralMultiplicationTask(difficulty: Difficulty) -> MathTask {
        let (min, max) = getMultiplicationRangeForDifficulty(difficulty)
        let operand1 = Int.random(in: min...max)
        let operand2 = Int.random(in: min...max)
        let answer = operand1 * operand2
        
        return MathTask(
            operation: .multiplicationTable, // ИСПРАВЛЕНО: было .multiplication
            operand1: operand1,
            operand2: operand2,
            correctAnswer: answer
        )
    }
    
    private func generateDivisionTask(difficulty: Difficulty) -> MathTask {
        let (min, max) = getMultiplicationRangeForDifficulty(difficulty)
        let divisor = Int.random(in: min...max)
        let quotient = Int.random(in: min...max)
        let dividend = divisor * quotient // Ensure exact division
        
        return MathTask(
            operation: .division,
            operand1: dividend,
            operand2: divisor,
            correctAnswer: quotient
        )
    }
    
    // MARK: - ОБНОВЛЕННАЯ генерация таблицы умножения с учетом сложности
    private func generateMultiplicationTableTask(difficulty: Difficulty) -> MathTask {
        guard let appState = appState else {
            // Fallback
            return MathTask(operation: .multiplicationTable, operand1: 2, operand2: 3, correctAnswer: 6)
        }
        
        let selectedMultiplier = appState.selectedMultiplier
        
        if selectedMultiplier == 0 {
            // Случайные множители в зависимости от сложности
            let (min, max) = getMultiplicationRangeForDifficulty(difficulty)
            
            let multiplier: Int
            let multiplicand: Int
            
            switch difficulty {
            case .easy:
                // Однозначные числа (1-9)
                multiplier = Int.random(in: min...max)
                multiplicand = Int.random(in: min...max)
                
            case .medium:
                // Один множитель однозначный (1-9), второй может быть двузначным (10-99)
                if Bool.random() {
                    // Первый однозначный, второй двузначный
                    multiplier = Int.random(in: 1...9)
                    multiplicand = Int.random(in: 10...99)
                } else {
                    // Первый двузначный, второй однозначный
                    multiplier = Int.random(in: 10...99)
                    multiplicand = Int.random(in: 1...9)
                }
                
            case .hard:
                // Двузначные на двузначные (10-99)
                multiplier = Int.random(in: min...max)
                multiplicand = Int.random(in: min...max)
            }
            
            let answer = multiplier * multiplicand
            
            return MathTask(
                operation: .multiplicationTable,
                operand1: multiplier,
                operand2: multiplicand,
                correctAnswer: answer
            )
        } else {
            // Конкретная таблица умножения (например, таблица на 3)
            // Второй операнд зависит от сложности
            let multiplicand: Int
            
            switch difficulty {
            case .easy:
                multiplicand = Int.random(in: 1...9)
            case .medium:
                multiplicand = Int.random(in: 1...12)
            case .hard:
                multiplicand = Int.random(in: 1...15)
            }
            
            let answer = selectedMultiplier * multiplicand
            
            return MathTask(
                operation: .multiplicationTable,
                operand1: selectedMultiplier,
                operand2: multiplicand,
                correctAnswer: answer
            )
        }
    }
    
    // MARK: - Difficulty Ranges
    private func getRangeForDifficulty(_ difficulty: Difficulty) -> (Int, Int) {
        switch difficulty {
        case .easy:
            return (1, 10)
        case .medium:
            return (1, 50)
        case .hard:
            return (1, 100)
        }
    }
    
    private func getMultiplicationRangeForDifficulty(_ difficulty: Difficulty) -> (Int, Int) {
        switch difficulty {
        case .easy:
            return (1, 9)      // Однозначные числа
        case .medium:
            return (1, 99)     // Однозначные и двузначные (случайные)
        case .hard:
            return (10, 99)    // Двузначные на двузначные
        }
    }
    
    // MARK: - Task Presentation
    private func presentNextTask() {
        // ИСПРАВЛЕНО: Проверяем что игра еще идет
        guard isRunning else {
            print("⚠️ Game is not running - not presenting next task")
            return
        }
        
        guard currentTaskIndex < tasks.count else {
            print("🏁 All tasks completed - ending training")
            endTraining()
            return
        }
        
        currentTask = tasks[currentTaskIndex]
        currentQuestion = currentTask?.questionText ?? ""
        questionStartTime = Date()
        
        print("📝 Presenting task \(currentTaskIndex + 1)/\(tasks.count): \(currentQuestion)")
        
        // Очищаем статус сообщение
        statusMessage = ""
        statusType = ""
        
        // НОВОЕ: Подготавливаем SpeechManager к новому вопросу
        speechManager?.prepareForNewQuestion()
        
        // Произносим вопрос (БЕЗ знака "=")
        speakQuestion()
    }
    
    func repeatQuestion() {
        print("🔄 Repeating question")
        guard let currentTask = currentTask, let appState = appState else { return }
        
        // ИСПРАВЛЕНО: Повторяем вопрос БЕЗ знака "=" с правильным языком
        let language = appState.selectedLanguage
        let questionToSpeak = currentTask.getSpokenText(language: language)
        speechManager?.speakQuestion(questionToSpeak)
    }
    
    func skipQuestion() {
        print("⏭️ Skipping question")
        
        if let task = currentTask {
            recordAnswer(userInput: "", isCorrect: false)
        }
        
        moveToNextTask()
    }
    
    private func moveToNextTask() {
        guard isRunning else {
            print("⚠️ Game ended - not moving to next task")
            return
        }
        
        currentTaskIndex += 1
        
        // ИСПРАВЛЕНО: Ускорили переход (с 1.0 до 0.5 секунды)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Убеждаемся что игра все еще идет
            guard self.isRunning else {
                print("⚠️ Game ended during transition - stopping")
                return
            }
            self.presentNextTask()
        }
    }
    
    // MARK: - Answer Processing
    func processAnswer(_ recognizedText: String) {
        print("🎯 Processing answer: '\(recognizedText)'")
        
        guard let task = currentTask else {
            print("❌ No current task")
            return
        }
        
        guard isRunning else {
            print("⚠️ Game not running - ignoring answer")
            return
        }
        
        // Извлекаем число из распознанного текста
        let extractedNumber = extractNumberFromText(recognizedText)
        let isCorrect = (extractedNumber == task.correctAnswer)
        
        recordAnswer(userInput: recognizedText, isCorrect: isCorrect)
        
        if isCorrect {
            correctAnswers += 1
            showSuccessMessage()
            speechManager?.playCorrectSound()
        } else {
            showErrorMessage(correctAnswer: task.correctAnswer)
            speechManager?.playIncorrectSound()
        }
        
        totalAnswers += 1
        
        // Переходим к следующей задаче
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.moveToNextTask()
        }
    }
    
    // ДОБАВЛЕНО: Новый метод для совместимости с SpeechManager
    func checkAnswer(_ number: Int) {
        print("🎯 Checking answer: \(number)")
        
        guard let task = currentTask else {
            print("❌ No current task")
            return
        }
        
        guard isRunning else {
            print("⚠️ Game not running - ignoring answer")
            return
        }
        
        let isCorrect = (number == task.correctAnswer)
        
        recordAnswer(userInput: String(number), isCorrect: isCorrect)
        
        if isCorrect {
            correctAnswers += 1
            showSuccessMessage()
            speechManager?.playCorrectSound()
        } else {
            showErrorMessage(correctAnswer: task.correctAnswer)
            speechManager?.playIncorrectSound()
        }
        
        totalAnswers += 1
        
        print("📈 Progress: \(totalAnswers)/\(tasks.count), Correct: \(correctAnswers)")
        
        // ИСПРАВЛЕНО: Проверяем достигли ли мы конца всех задач
        if totalAnswers >= tasks.count {
            print("🏁 All tasks completed - ending training")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.endTraining()
            }
        } else {
            // Переходим к следующей задаче
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.moveToNextTask()
            }
        }
    }
    
    private func extractNumberFromText(_ text: String) -> Int {
        // Простое извлечение числа из текста
        let numberStrings = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
        for numberString in numberStrings {
            if let number = Int(numberString), !numberString.isEmpty {
                return number
            }
        }
        
        // Если не найдено число, возвращаем -1
        return -1
    }
    
    private func recordAnswer(userInput: String, isCorrect: Bool) {
        guard let task = currentTask else { return }
        
        let responseTime = Date().timeIntervalSince(questionStartTime)
        let result = TaskResult(
            question: task.questionText,
            userAnswer: userInput,
            correctAnswer: task.correctAnswer,
            isCorrect: isCorrect,
            responseTime: responseTime,
            timestamp: Date()
        )
        
        gameResults.append(result)
        
        print("📊 Recorded result: \(isCorrect ? "✅" : "❌") Answer: \(userInput), Correct: \(task.correctAnswer)")
    }
    
    // MARK: - Feedback Messages
    private func showSuccessMessage() {
        guard let appState = appState else { return }
        
        let language = appState.selectedLanguage
        let messages = language == "en" ?
            ["Excellent!", "Correct!", "Great!", "Awesome!", "Perfect!"] :
            ["Отлично!", "Правильно!", "Молодец!", "Супер!", "Здорово!"]
        
        statusMessage = messages.randomElement() ?? (language == "en" ? "Correct!" : "Правильно!")
        statusType = "success"
    }
    
    private func showErrorMessage(correctAnswer: Int) {
        guard let appState = appState else { return }
        
        let language = appState.selectedLanguage
        statusMessage = language == "en" ?
            "Correct answer: \(correctAnswer)" :
            "Правильный ответ: \(correctAnswer)"
        statusType = "error"
    }
    
    private func showFinalResults() {
        guard let appState = appState else { return }
        
        let language = appState.selectedLanguage
        let percentage = totalAnswers > 0 ? (correctAnswers * 100) / totalAnswers : 0
        
        statusMessage = language == "en" ?
            "Result: \(correctAnswers)/\(totalAnswers) (\(percentage)%)" :
            "Результат: \(correctAnswers)/\(totalAnswers) (\(percentage)%)"
        statusType = totalAnswers > 0 && percentage >= 70 ? "success" : "warning"
        
        print("🏆 Final Results: \(correctAnswers)/\(totalAnswers) (\(percentage)%)")
    }
    
    // MARK: - Speech Output
    private func speakQuestion() {
        guard let appState = appState, let currentTask = currentTask else { return }
        
        guard isRunning else {
            print("⚠️ Game not running - not speaking question")
            return
        }
        
        // ИСПРАВЛЕНО: Передаем язык из appState
        let language = appState.selectedLanguage
        let questionToSpeak = currentTask.getSpokenText(language: language)
        print("🔊 Speaking question in \(language): \(questionToSpeak)")
        
        // Передаем управление SpeechManager для произношения и автоматического прослушивания
        speechManager?.speakQuestion(questionToSpeak)
    }
    
    private func speakText(_ text: String, language: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
        
        print("🔊 Speaking: \(text)")
    }
    
    // MARK: - Language Management
    func updateLanguage(_ language: String) {
        print("🌍 GameManager: Updating language to \(language)")
        speechManager?.setup(language: language)
    }
    
    // НОВЫЙ МЕТОД: Тест звуков отдельно от игры
    func testSounds() {
        print("🧪 Testing sounds independently...")
        speechManager?.testReliableSounds()
    }
    
    // MARK: - Cleanup
    deinit {
        speechSynthesizer.stopSpeaking(at: .immediate)
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
}
