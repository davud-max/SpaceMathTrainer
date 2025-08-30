import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var gameManager = MathGameManager()
    @StateObject private var speechManager = SpeechManager()
    
    var body: some View {
        ZStack {
            // Серьезный многослойный космический фон
            CosmicBackgroundStack()
            
            // Основной интерфейс с полным использованием экрана
            FullScreenInterface(
                appState: appState,
                gameManager: gameManager,
                speechManager: speechManager
            )
            
            // Система частиц космической пыли
            CosmicParticleSystem()
                .allowsHitTesting(false)
        }
        .ignoresSafeArea(.all) // ПОЛНОЕ игнорирование Safe Area
        .onAppear {
            setupManagers()
        }
    }
    
    private func setupManagers() {
        print("🔧 Setting up managers...")
        
        // КРИТИЧЕСКИ ВАЖНО: Устанавливаем связи между менеджерами
        gameManager.speechManager = speechManager
        gameManager.appState = appState
        speechManager.gameManager = gameManager
        
        // ИСПРАВЛЕНО: Правильная установка связи AppState -> SpeechManager
        appState.setSpeechManager(speechManager)
        
        // ИСПРАВЛЕНО: Инициализируем SpeechManager с правильным языком
        let initialLanguage = appState.selectedLanguage
        print("🌍 Initial language: \(initialLanguage)")
        
        // Задержка для полной инициализации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.speechManager.setup(language: initialLanguage)
            print("✅ Managers setup completed with language: \(initialLanguage)")
        }
    }
}

// MARK: - ОБНОВЛЕННЫЙ Многослойный космический фон (ТОЛЬКО ЧЕРНЫЙ ФОН)
struct CosmicBackgroundStack: View {
    @State private var rotateStars = 0.0
    @State private var pulseNebula = false
    @State private var moveAsteroids = false
    
    var body: some View {
        ZStack {
            // ИЗМЕНЕНО: Полностью черный фон вместо градиента
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea()
            
            // Слой дальних звезд
            DistantStarsLayer()
            
            // Туманности
            NebulaLayer(pulse: pulseNebula)
            
            // Близкие звезды с мерцанием
            CloseStarsLayer()
                .rotationEffect(.degrees(rotateStars))
        }
        .onAppear {
            withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
                rotateStars = 360
            }
            
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                pulseNebula = true
            }
        }
    }
}

// MARK: - Слои космического фона (ОПТИМИЗИРОВАНЫ для полного экрана)
struct DistantStarsLayer: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<60, id: \.self) { index in // Уменьшено количество звезд
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...0.4)))
                    .frame(width: CGFloat.random(in: 0.5...1.5))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
            }
        }
    }
}

struct NebulaLayer: View {
    let pulse: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<2, id: \.self) { index in // Уменьшено количество туманностей
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                getNebulaColor(index).opacity(0.2), // Уменьшена непрозрачность
                                getNebulaColor(index).opacity(0.05),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 60 // Уменьшен размер
                        )
                    )
                    .frame(width: 120, height: 120) // Уменьшен размер
                    .position(
                        x: CGFloat.random(in: 50...geometry.size.width-50),
                        y: CGFloat.random(in: 50...geometry.size.height-50)
                    )
                    .scaleEffect(pulse ? 1.1 : 0.9) // Уменьшена анимация
                    .opacity(pulse ? 0.6 : 0.3) // Уменьшена непрозрачность
            }
        }
    }
    
    private func getNebulaColor(_ index: Int) -> Color {
        let colors: [Color] = [.blue, .purple, .indigo]
        return colors[index % colors.count]
    }
}

struct CloseStarsLayer: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<25, id: \.self) { index in // Уменьшено количество звезд
                AnimatedStar(
                    size: CGFloat.random(in: 1.5...3), // Уменьшен размер
                    position: CGPoint(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    ),
                    delay: Double.random(in: 0...5)
                )
            }
        }
    }
}

struct AnimatedStar: View {
    let size: CGFloat
    let position: CGPoint
    let delay: Double
    
    @State private var brightness: Double = 1.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Основная звезда
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
            
            // Сияние
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: size * 2, height: size * 2)
                .blur(radius: 2)
                
            // Лучи
            StarRays(size: size)
        }
        .opacity(brightness)
        .scaleEffect(scale)
        .position(position)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: Double.random(in: 2...4)).repeatForever(autoreverses: true)) {
                    brightness = Double.random(in: 0.3...1.0)
                    scale = CGFloat.random(in: 0.8...1.3)
                }
            }
        }
    }
}

struct StarRays: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Горизонтальный луч
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: size * 3, height: 0.5)
            
            // Вертикальный луч
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 0.5, height: size * 3)
            
            // Диагональные лучи
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(width: size * 2, height: 0.3)
                .rotationEffect(.degrees(45))
            
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(width: size * 2, height: 0.3)
                .rotationEffect(.degrees(-45))
        }
    }
}

// MARK: - Система частиц космической пыли (ОПТИМИЗИРОВАНА)
struct CosmicParticleSystem: View {
    @State private var particles: [CosmicParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles.indices, id: \.self) { index in
                if particles.indices.contains(index) {
                    ParticleView(particle: particles[index])
                }
            }
        }
        .onAppear {
            createParticles()
            startParticleAnimation()
        }
    }
    
    private func createParticles() {
        particles = (0..<15).map { _ in // Сильно уменьшено количество частиц
            CosmicParticle(
                x: CGFloat.random(in: -50...450),
                y: CGFloat.random(in: -50...900),
                size: CGFloat.random(in: 0.5...2), // Уменьшен размер
                opacity: Double.random(in: 0.1...0.5), // Уменьшена непрозрачность
                speedX: CGFloat.random(in: -0.3...0.3), // Уменьшена скорость
                speedY: CGFloat.random(in: -0.3...0.3)
            )
        }
    }
    
    private func startParticleAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in // Увеличен интервал
            updateParticles()
        }
    }
    
    private func updateParticles() {
        for index in particles.indices {
            particles[index].x += particles[index].speedX
            particles[index].y += particles[index].speedY
            
            // Переработка частиц за границами экрана
            if particles[index].x > 450 {
                particles[index].x = -25
            }
            if particles[index].x < -25 {
                particles[index].x = 450
            }
            if particles[index].y > 900 {
                particles[index].y = -25
            }
            if particles[index].y < -25 {
                particles[index].y = 900
            }
        }
    }
}

struct CosmicParticle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speedX: CGFloat
    var speedY: CGFloat
}

struct ParticleView: View {
    let particle: CosmicParticle
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(particle.opacity))
            .frame(width: particle.size, height: particle.size)
            .position(x: particle.x, y: particle.y)
    }
}

// MARK: - АБСОЛЮТНО полноэкранный интерфейс (БЕЗ ОТСТУПОВ ВООБЩЕ)
struct FullScreenInterface: View {
    @ObservedObject var appState: AppState
    @ObservedObject var gameManager: MathGameManager
    @ObservedObject var speechManager: SpeechManager
    
    var body: some View {
        ZStack {
            // Фон интерфейса на весь экран
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .ignoresSafeArea(.all)
            
            if gameManager.isRunning {
                // ИГРОВОЙ РЕЖИМ - используем весь экран
                GameScreenView(
                    appState: appState,
                    gameManager: gameManager,
                    speechManager: speechManager
                )
            } else {
                // РЕЖИМ НАСТРОЕК - АБСОЛЮТНО весь экран
                VStack(spacing: 0) {
                    // Заголовок БЕЗ отступов сверху
                    CompactHeader(appState: appState)
                        .padding(.horizontal, 16)
                    
                    // Прокручиваемые настройки
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            CompactLanguageSettings(appState: appState)
                            
                            // ОБНОВЛЕНО: Новые операции с поддержкой модального окна
                            CompactOperationSettings(appState: appState)
                            
                            CompactDifficultySettings(appState: appState)
                            CompactParameterSettings(appState: appState)
                            
                            // Отступ для кнопок
                            Spacer().frame(height: 90)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Фиксированные кнопки внизу БЕЗ отступов
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.cyan.opacity(0.3))
                            .frame(height: 0.5)
                        
                        HStack(spacing: 12) {
                            // Кнопка запуска (теперь слева)
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                impactFeedback.impactOccurred()
                                
                                if appState.canLaunch {
                                    gameManager.startTraining()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text("🚀")
                                        .font(.system(size: 14))
                                    Text(appState.localizedString("launch_mission"))
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                    Text("🌌")
                                        .font(.system(size: 14))
                                }
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(appState.canLaunch ? Color.green.opacity(0.8) : Color.gray.opacity(0.5))
                                        .stroke(appState.canLaunch ? Color.green : Color.gray, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!appState.canLaunch)
                            
                            // Кнопка выход (теперь справа)
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                exit(0)
                            }) {
                                HStack(spacing: 6) {
                                    Text("❌")
                                        .font(.system(size: 14))
                                    Text(appState.localizedString("exit"))
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 80, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.7))
                                        .stroke(Color.red, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                    }
                }
            }
        }
    }
}

// MARK: - Компактные компоненты

// КОМПАКТНЫЙ ЗАГОЛОВОК (БЕЗ ОТСТУПОВ СВЕРХУ)
struct CompactHeader: View {
    @ObservedObject var appState: AppState
    @State private var rocketAnimation = false
    
    var body: some View {
        HStack(spacing: 8) {
            Text("✨")
                .font(.system(size: 18))
            
            VStack(spacing: 2) {
                Text(appState.localizedString("app_title_cosmic"))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
                
                Text(appState.localizedString("app_title_math"))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("🚀")
                .font(.system(size: 18))
                .scaleEffect(rocketAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: rocketAnimation)
                .onAppear { rocketAnimation = true }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8) // Увеличен отступ по вертикали для лучшего вида
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.cyan.opacity(0.6), lineWidth: 1)
        )
    }
}

// КОМПАКТНЫЕ ЯЗЫКОВЫЕ НАСТРОЙКИ
struct CompactLanguageSettings: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("🌍")
                    .font(.system(size: 14))
                Text(appState.localizedString("language_title"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
            }
            
            HStack(spacing: 8) {
                ForEach(appState.availableLanguages, id: \.self) { lang in
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        appState.changeLanguage(to: lang)
                    }) {
                        Text(getLanguageDisplayName(lang))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 30)
                            .background(
                                appState.selectedLanguage == lang ?
                                Color.blue.opacity(0.6) : Color.black.opacity(0.4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        appState.selectedLanguage == lang ? Color.cyan : Color.blue,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func getLanguageDisplayName(_ code: String) -> String {
        switch code {
        case "en": return "ENG"
        case "ru": return "РУС"
        default: return code.uppercased()
        }
    }
}

// ОБНОВЛЕННЫЕ КОМПАКТНЫЕ ОПЕРАЦИИ с поддержкой модального окна
struct CompactOperationSettings: View {
    @ObservedObject var appState: AppState
    
    // ОБНОВЛЕНО: Показываем только нужные операции (убрали .multiplication)
    private var availableOperations: [MathOperation] {
        [.addition, .subtraction, .multiplicationTable, .division]
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("🧮")
                    .font(.system(size: 14))
                Text(appState.localizedString("operations_title"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
            }
            
            HStack(spacing: 12) { // УВЕЛИЧЕНО расстояние между кнопками
                // ИСПОЛЬЗУЕМ НОВЫЕ КНОПКИ ИЗ ButtonComponents.swift
                ForEach(availableOperations, id: \.self) { operation in
                    MathOperationButton(operation: operation, appState: appState) {
                        // ОБЫЧНЫЕ ОПЕРАЦИИ - стандартная логика
                        if operation != .multiplicationTable && operation != .division {
                            appState.toggleOperation(operation)
                        }
                        // ДЛЯ .multiplicationTable модальное окно откроется автоматически в MathOperationButton
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.purple.opacity(0.5), lineWidth: 1)
        )
    }
}

// КОМПАКТНАЯ СЛОЖНОСТЬ
struct CompactDifficultySettings: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("⚡")
                    .font(.system(size: 14))
                Text(appState.localizedString("difficulty_title"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 8) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    CompactDifficultyButton(difficulty: difficulty, appState: appState)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }
}

struct CompactDifficultyButton: View {
    let difficulty: Difficulty
    @ObservedObject var appState: AppState
    
    var body: some View {
        let isSelected = appState.selectedDifficulty == difficulty
        
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            appState.selectedDifficulty = difficulty
        }) {
            VStack(spacing: 1) {
                Text(getDifficultyIcon(difficulty))
                    .font(.system(size: 14))
                
                Text(appState.getLocalizedDifficultyName(difficulty))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 50, height: 30)
            .background(isSelected ? Color.blue.opacity(0.6) : Color.black.opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.cyan : Color.blue, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getDifficultyIcon(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy: return "🟢"
        case .medium: return "🟡"
        case .hard: return "🔴"
        }
    }
}

// КОМПАКТНЫЕ ПАРАМЕТРЫ (ИСПРАВЛЕНЫ: разнесены влево-вправо)
struct CompactParameterSettings: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("⚙️")
                    .font(.system(size: 14))
                Text(appState.localizedString("parameters_title"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.mint)
            }
            
            // РАЗНЕСЕННЫЕ ВЛЕВО-ВПРАВО параметры
            HStack(spacing: 0) {
                // Количество заданий (СЛЕВА)
                VStack(spacing: 4) {
                    Text("📊")
                        .font(.system(size: 14))
                    Text("\(appState.tasksCount)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    Text("количество заданий") // ИСПРАВЛЕНО: полная надпись
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) { // Увеличено расстояние между кнопками
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            if appState.tasksCount > 5 {
                                appState.tasksCount -= 5
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24) // Увеличены кнопки
                                .background(Circle().fill(Color.cyan.opacity(0.6)))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(appState.tasksCount <= 5)
                        
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            if appState.tasksCount < 50 {
                                appState.tasksCount += 5
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24) // Увеличены кнопки
                                .background(Circle().fill(Color.cyan.opacity(0.6)))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(appState.tasksCount >= 50)
                    }
                }
                
                Spacer() // РАЗДЕЛИТЕЛЬ между левой и правой частью
                
                // Время на ответ (СПРАВА)
                VStack(spacing: 4) {
                    Text("⏱️")
                        .font(.system(size: 14))
                    Text("\(Int(appState.answerTimeLimit))s")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                    Text("время на ответ") // ИСПРАВЛЕНО: полная надпись
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) { // Увеличено расстояние между кнопками
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            if appState.answerTimeLimit > 5 {
                                appState.answerTimeLimit -= 5
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24) // Увеличены кнопки
                                .background(Circle().fill(Color.orange.opacity(0.6)))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(appState.answerTimeLimit <= 5)
                        
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            if appState.answerTimeLimit < 30 {
                                appState.answerTimeLimit += 5
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24) // Увеличены кнопки
                                .background(Circle().fill(Color.orange.opacity(0.6)))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(appState.answerTimeLimit >= 30)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12) // Увеличен padding для лучших пропорций
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.mint.opacity(0.5), lineWidth: 1)
        )
    }
}

// КОМПАКТНЫЕ ИГРОВЫЕ КОМПОНЕНТЫ
struct CompactGameProgress: View {
    @ObservedObject var appState: AppState
    @ObservedObject var gameManager: MathGameManager
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 2) {
                Text("🚀 \(appState.localizedString("mission_active"))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Text(String(format: appState.localizedString("task_of"), "\(gameManager.currentTaskIndex + 1)", "\(appState.tasksCount)"))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            VStack(spacing: 2) {
                Text("📊 \(appState.localizedString("score"))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Text("\(gameManager.correctAnswers)/\(gameManager.totalAnswers)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.4))
                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
        )
    }
}

// ИСПРАВЛЕНА СТРУКТУРА CompactMicrophoneStatus
struct CompactMicrophoneStatus: View {
    @ObservedObject var speechManager: SpeechManager
    @ObservedObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(speechManager.microphoneActive ? .green.opacity(0.4) : .red.opacity(0.4))
                    .frame(width: 24, height: 24)
                
                Text("🎤")
                    .font(.system(size: 12))
            }
            
            Text(speechManager.microphoneActive ?
                 appState.localizedString("microphone_active") :
                 appState.localizedString("microphone_off"))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            if speechManager.listeningForAnswers {
                Text("👂 \(appState.localizedString("listening"))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.yellow)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.4))
                .stroke(speechManager.microphoneActive ? Color.green.opacity(0.6) : Color.red.opacity(0.6), lineWidth: 1)
        )
    }
}

// MARK: - Игровой экран (АБСОЛЮТНО ПОЛНЫЙ ЭКРАН)
struct GameScreenView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var gameManager: MathGameManager
    @ObservedObject var speechManager: SpeechManager
    
    var body: some View {
        VStack(spacing: 5) {
            // Верхняя панель БЕЗ отступов сверху
            VStack(spacing: 8) {
                CompactGameProgress(appState: appState, gameManager: gameManager)
                CompactMicrophoneStatus(speechManager: speechManager, appState: appState)
            }
            .padding(.horizontal, 16)
            
            // Основной вопрос (центр экрана)
            Spacer()
            
            if !gameManager.currentQuestion.isEmpty {
                VStack(spacing: 12) {
                    Text(gameManager.currentQuestion)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .cyan.opacity(0.6), radius: 8)
                    
                    Text(appState.localizedString("say_answer"))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Распознанный текст
            if !speechManager.lastRecognizedText.isEmpty {
                VStack(spacing: 6) {
                    Text(appState.localizedString("recognized"))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\"\(speechManager.lastRecognizedText)\"")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.cyan)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 15)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.4))
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
            
            // Статус сообщение
            if !gameManager.statusMessage.isEmpty {
                Text(gameManager.statusMessage)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(getStatusColor(gameManager.statusType))
                            .stroke(getStatusBorderColor(gameManager.statusType), lineWidth: 2)
                    )
                    .shadow(color: getStatusBorderColor(gameManager.statusType).opacity(0.6), radius: 8)
                    .padding(.horizontal, 16)
            }
            
            // Кнопки управления внизу БЕЗ отступов снизу
            HStack(spacing: 12) {
                Button(action: { gameManager.repeatQuestion() }) {
                    VStack(spacing: 3) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(appState.localizedString("repeat"))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 35)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.5))
                            .stroke(Color.blue, lineWidth: 1.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { gameManager.skipQuestion() }) {
                    VStack(spacing: 3) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(appState.localizedString("skip"))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 35)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.5))
                            .stroke(Color.orange, lineWidth: 1.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { gameManager.endTraining() }) {
                    VStack(spacing: 3) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(appState.localizedString("finish"))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 35)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.5))
                            .stroke(Color.red, lineWidth: 1.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 2) // Минимальный отступ снизу
        }
    }
    
    private func getStatusColor(_ type: String) -> Color {
        switch type {
        case "success": return .green.opacity(0.5)
        case "error": return .red.opacity(0.5)
        case "warning": return .orange.opacity(0.5)
        default: return .blue.opacity(0.5)
        }
    }
    
    private func getStatusBorderColor(_ type: String) -> Color {
        switch type {
        case "success": return .green
        case "error": return .red
        case "warning": return .orange
        default: return .blue
        }
    }
}

#Preview {
    ContentView()
}
