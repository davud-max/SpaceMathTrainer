import Foundation

// MARK: - Math Operation Types (ОБНОВЛЕНО: убрали .multiplication, изменили символ)
enum MathOperation: String, CaseIterable, Hashable {
    case addition = "+"
    case subtraction = "−"
    case multiplicationTable = "×" // ИЗМЕНЕНО: с ⊗ на ×
    case division = "÷"
    
    // НОВОЕ: Дополнительные свойства для удобства разработки
    var isMultiplicationBased: Bool {
        switch self {
        case .multiplicationTable:
            return true
        default:
            return false
        }
    }
    
    var requiresSpecialHandling: Bool {
        switch self {
        case .multiplicationTable:
            return true // Требует выбора множителя
        default:
            return false
        }
    }
    
    // Для совместимости с игровой логикой
    var baseOperation: MathOperation {
        switch self {
        case .multiplicationTable:
            return .multiplicationTable // Возвращаем саму операцию
        default:
            return self
        }
    }
    
    // Приоритет отображения в интерфейсе
    var displayPriority: Int {
        switch self {
        case .addition: return 1
        case .subtraction: return 2
        case .multiplicationTable: return 3 // Было 4, стало 3
        case .division: return 4 // Было 5, стало 4
        }
    }
}

// MARK: - Difficulty Levels
enum Difficulty: String, CaseIterable, Hashable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    // НОВОЕ: Дополнительные свойства для игровой логики
    var numberRange: ClosedRange<Int> {
        switch self {
        case .easy: return 1...10
        case .medium: return 1...50
        case .hard: return 1...100
        }
    }
    
    var multiplicationRange: ClosedRange<Int> {
        switch self {
        case .easy: return 1...9     // Однозначные числа
        case .medium: return 1...99  // Однозначные и двузначные (случайные)
        case .hard: return 10...99   // Двузначные на двузначные
        }
    }
    
    // Время по умолчанию для каждой сложности
    var defaultTimeLimit: Double {
        switch self {
        case .easy: return 20.0
        case .medium: return 15.0
        case .hard: return 10.0
        }
    }
    
    // Количество заданий по умолчанию
    var defaultTaskCount: Int {
        switch self {
        case .easy: return 10
        case .medium: return 15
        case .hard: return 20
        }
    }
    
    // Цвет для интерфейса
    var displayColor: String {
        switch self {
        case .easy: return "green"
        case .medium: return "yellow"
        case .hard: return "red"
        }
    }
}

// MARK: - НОВОЕ: Дополнительные типы для расширенной функциональности

// Тип результата ответа
enum AnswerResult: String, CaseIterable {
    case correct = "correct"
    case incorrect = "incorrect"
    case timeout = "timeout"
    case skipped = "skipped"
    
    var isPositive: Bool {
        return self == .correct
    }
    
    var feedbackType: String {
        switch self {
        case .correct: return "success"
        case .incorrect: return "error"
        case .timeout: return "warning"
        case .skipped: return "warning"
        }
    }
}

// Статистика игровой сессии
struct GameSession {
    let id: UUID = UUID()
    let startTime: Date = Date()
    var endTime: Date?
    
    let selectedOperations: Set<MathOperation>
    let difficulty: Difficulty
    let taskCount: Int
    let timeLimit: Double
    let selectedMultiplier: Int? // Для таблицы умножения
    
    var results: [TaskResult] = []
    
    var duration: TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }
    
    var correctAnswers: Int {
        return results.filter { $0.result == .correct }.count
    }
    
    var accuracy: Double {
        guard !results.isEmpty else { return 0.0 }
        return Double(correctAnswers) / Double(results.count) * 100.0
    }
    
    var averageResponseTime: Double {
        let responseTimes = results.compactMap { $0.responseTime }
        guard !responseTimes.isEmpty else { return 0.0 }
        return responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
}

// Результат отдельного задания
struct TaskResult {
    let id: UUID = UUID()
    let timestamp: Date = Date()
    
    let operation: MathOperation
    let operand1: Int
    let operand2: Int
    let correctAnswer: Int
    let userAnswer: Int?
    let result: AnswerResult
    let responseTime: Double?
    
    var question: String {
        return "\(operand1) \(operation.rawValue) \(operand2) = ?"
    }
    
    var isCorrect: Bool {
        return result == .correct
    }
}

// MARK: - Утилиты для работы с операциями

extension MathOperation {
    // ОБНОВЛЕНО: Генерация чисел БЕЗ НУЛЯ для случайных множителей
    func generateNumbers(difficulty: Difficulty, multiplier: Int? = nil) -> (Int, Int, Int) {
        switch self {
        case .addition:
            let range = difficulty.numberRange
            let num1 = Int.random(in: range)
            let num2 = Int.random(in: range)
            return (num1, num2, num1 + num2)
            
        case .subtraction:
            let range = difficulty.numberRange
            let num1 = Int.random(in: range)
            let num2 = Int.random(in: 1...num1)
            return (num1, num2, num1 - num2)
            
        case .multiplicationTable:
            let selectedMultiplier = multiplier ?? 2
            if selectedMultiplier == 0 {
                // ОБНОВЛЕНО: Случайные множители БЕЗ НУЛЯ (от 1 до 9)
                let num1 = Int.random(in: 1...9) // ИСКЛЮЧИЛИ НОЛЬ
                let num2 = Int.random(in: 1...9) // ИСКЛЮЧИЛИ НОЛЬ
                return (num1, num2, num1 * num2)
            } else {
                // Конкретная таблица
                let num2 = Int.random(in: 1...9) // ИСКЛЮЧИЛИ НОЛЬ
                return (selectedMultiplier, num2, selectedMultiplier * num2)
            }
            
        case .division:
            let range = difficulty.multiplicationRange
            let divisor = Int.random(in: 2...range.upperBound)
            let quotient = Int.random(in: range)
            let dividend = divisor * quotient
            return (dividend, divisor, quotient)
        }
    }
    
    // Проверка валидности операции для сложности
    func isValidForDifficulty(_ difficulty: Difficulty) -> Bool {
        // Все операции доступны для всех сложностей
        return true
    }
    
    // Получение примера вопроса
    func getExampleQuestion(difficulty: Difficulty, multiplier: Int? = nil) -> String {
        let (num1, num2, _) = generateNumbers(difficulty: difficulty, multiplier: multiplier)
        return "\(num1) \(rawValue) \(num2) = ?"
    }
    
    // НОВОЕ: Получение текста для произношения БЕЗ знака "=" и с правильными операциями
    func getSpokenQuestion(difficulty: Difficulty, multiplier: Int? = nil, language: String = "ru") -> String {
        let (num1, num2, _) = generateNumbers(difficulty: difficulty, multiplier: multiplier)
        
        let operationWord: String
        
        if language == "en" {
            switch self {
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
            switch self {
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
        
        return "\(num1) \(operationWord) \(num2)"
    }
}

extension Difficulty {
    // Рекомендуемые операции для сложности
    var recommendedOperations: Set<MathOperation> {
        switch self {
        case .easy:
            return [.addition, .subtraction, .multiplicationTable]
        case .medium:
            return [.addition, .subtraction, .multiplicationTable]
        case .hard:
            return Set(MathOperation.allCases)
        }
    }
    
    // Проверка совместимости с операцией
    func isCompatible(with operation: MathOperation) -> Bool {
        return recommendedOperations.contains(operation)
    }
}

// MARK: - Константы

struct MathTrainerConstants {
    static let minTaskCount = 5
    static let maxTaskCount = 50
    static let defaultTaskCount = 10
    
    static let minTimeLimit: Double = 5.0
    static let maxTimeLimit: Double = 60.0
    static let defaultTimeLimit: Double = 15.0
    
    static let multiplicationTableRange = 2...10
    static let defaultMultiplier = 2
    
    // Звуковые эффекты
    static let correctSoundID: UInt32 = 1057  // Tink
    static let incorrectSoundID: UInt32 = 1005 // Beep Beep
    static let timeoutSoundID: UInt32 = 1004   // Short beep
    static let startSoundID: UInt32 = 1104     // Begin Record
    static let endSoundID: UInt32 = 1113       // End Record
    
    // Тактильная обратная связь
    enum HapticStyle {
        case light, medium, heavy, success, error, warning
    }
}
