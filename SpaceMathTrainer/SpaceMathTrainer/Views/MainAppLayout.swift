import SwiftUI

struct MainAppLayout: View {
    @StateObject private var appState = AppState()
    @State private var currentView: AppView = .menu
    
    enum AppView {
        case menu
        case game
        case settings
        case statistics
    }
    
    var body: some View {
        ZStack {
            // Космический фон
            Color.black
            
            // Звезды на фоне
            StarsBackground()
            
            switch currentView {
            case .menu:
                MenuView(appState: appState, currentView: $currentView)
            case .game:
                GameView(appState: appState, currentView: $currentView)
            case .settings:
                SettingsView(appState: appState, currentView: $currentView)
            case .statistics:
                StatisticsView(appState: appState, currentView: $currentView)
            }
        }
    }
}

// УДАЛИТЕ все дублирующие определения компонентов (строки 37, 72, 114)
// Они уже есть в ButtonComponents.swift:
// - LanguageSelectionView
// - LanguageButton
// - DifficultyButton

struct MenuView: View {
    @ObservedObject var appState: AppState
    @Binding var currentView: MainAppLayout.AppView
    
    var body: some View {
        VStack(spacing: 40) {
            // Заголовок
            VStack(spacing: 10) {
                Text("🚀 SPACE")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Text("MATH TRAINER")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Меню кнопок
            VStack(spacing: 30) {
                MenuButton(
                    title: appState.localizedString("practice"),
                    icon: "gamecontroller",
                    color: .green
                ) {
                    currentView = .game
                }
                
                MenuButton(
                    title: appState.localizedString("statistics"),
                    icon: "chart.bar",
                    color: .blue
                ) {
                    currentView = .statistics
                }
                
                MenuButton(
                    title: appState.localizedString("settings"),
                    icon: "gear",
                    color: .orange
                ) {
                    currentView = .settings
                }
            }
            
            Spacer()
            
            // Языковая секция
            LanguageSelectionView(appState: appState)
        }
        .padding(30)
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40)
                
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(color.opacity(0.2))
                    .stroke(color, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @Binding var currentView: MainAppLayout.AppView
    
    var body: some View {
        VStack(spacing: 30) {
            // Заголовок
            HStack {
                Button(action: {
                    currentView = .menu
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(appState.localizedString("settings"))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Spacer()
                
                Color.clear
                    .frame(width: 30)
            }
            
            ScrollView {
                VStack(spacing: 25) {
                    // Выбор языка
                    LanguageSelectionView(appState: appState)
                    
                    // Операции
                    OperationSelectionView(appState: appState)
                    
                    // Сложность
                    DifficultySelectionView(appState: appState)
                    
                    // Настройки времени и количества
                    ParametersView(appState: appState)
                }
            }
            
            // Кнопка запуска (ИСПРАВЛЕНО: убран speechManager параметр)
            Button(action: {
                if appState.canLaunch {
                    currentView = .game
                }
            }) {
                Text(appState.localizedString("start_mission"))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(appState.canLaunch ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                            .stroke(appState.canLaunch ? Color.green : Color.gray, lineWidth: 2)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!appState.canLaunch)
        }
        .padding(30)
    }
}

struct OperationSelectionView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 15) {
            Text(appState.localizedString("operations"))
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(MathOperation.allCases, id: \.self) { operation in
                    MathOperationButton(
                        operation: operation,
                        appState: appState
                    ) {
                        appState.toggleOperation(operation)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
                .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
        )
    }
}

struct DifficultySelectionView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 15) {
            Text(appState.localizedString("difficulty"))
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            HStack(spacing: 15) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyButton(
                        difficulty: difficulty,
                        appState: appState
                    ) {
                        appState.selectedDifficulty = difficulty
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
                .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
        )
    }
}

struct ParametersView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            // Количество заданий
            VStack(spacing: 10) {
                Text(appState.localizedString("tasks_count"))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Stepper(value: $appState.tasksCount, in: 5...50, step: 5) {
                    Text("\(appState.tasksCount)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
            }
            
            // Время на ответ
            VStack(spacing: 10) {
                Text(appState.localizedString("answer_time"))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                HStack {
                    Text("\(Int(appState.answerTimeLimit))")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    Text(appState.localizedString("seconds"))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Slider(value: $appState.answerTimeLimit, in: 5...30, step: 1)
                        .accentColor(.cyan)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
                .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
        )
    }
}

struct GameView: View {
    @ObservedObject var appState: AppState
    @Binding var currentView: MainAppLayout.AppView
    
    var body: some View {
        VStack {
            Text("🎮 GAME VIEW")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            Spacer()
            
            ControlButton(
                icon: "house",
                text: appState.localizedString("exit"),
                color: .red,
                isDisabled: false,
                action: {
                    currentView = .menu
                }
            )
        }
        .padding(30)
    }
}

struct StatisticsView: View {
    @ObservedObject var appState: AppState
    @Binding var currentView: MainAppLayout.AppView
    
    var body: some View {
        VStack {
            Text("📊 STATISTICS")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            Spacer()
            
            ControlButton(
                icon: "house",
                text: appState.localizedString("exit"),
                color: .red,
                isDisabled: false,
                action: {
                    currentView = .menu
                }
            )
        }
        .padding(30)
    }
}

struct StarsBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<50, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...0.9)))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
            }
        }
        .ignoresSafeArea()
    }
}
