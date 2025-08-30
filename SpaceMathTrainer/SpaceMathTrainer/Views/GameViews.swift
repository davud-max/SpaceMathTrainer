import SwiftUI

// Это базовая структура GameViews.swift с исправлениями
// Замените ваш существующий файл на эту версию

struct GameViews: View {
    @ObservedObject var appState: AppState
    @State private var showMainMenu = false
    
    var body: some View {
        ZStack {
            // Ваш основной контент игры здесь
            
            // Исправленная версия ControlButton (строка 624)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ControlButton(
                        icon: "house",
                        text: appState.localizedString("exit"),
                        color: .red,
                        isDisabled: false,
                        action: { showMainMenu = true }
                    )
                }
                .padding()
            }
        }
    }
}

// УДАЛИТЕ дублирующее определение ControlButton (строка 653)
// Оно уже есть в ButtonComponents.swift

struct GameResultView: View {
    @ObservedObject var appState: AppState
    let score: Int
    let totalQuestions: Int
    let onRestart: () -> Void
    let onMainMenu: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("🎯 " + appState.localizedString("game_complete"))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            Text("\(score)/\(totalQuestions)")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                ControlButton(
                    icon: "arrow.clockwise",
                    text: appState.localizedString("restart"),
                    color: .green,
                    isDisabled: false,
                    action: onRestart
                )
                
                ControlButton(
                    icon: "house",
                    text: appState.localizedString("menu"),
                    color: .blue,
                    isDisabled: false,
                    action: onMainMenu
                )
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black.opacity(0.8))
                .stroke(Color.cyan, lineWidth: 3)
        )
    }
}

struct QuestionView: View {
    @ObservedObject var appState: AppState
    let question: String
    let options: [String]
    let onAnswer: (String) -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text(question)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        onAnswer(option)
                    }) {
                        Text(option)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.blue.opacity(0.3))
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(30)
    }
}
