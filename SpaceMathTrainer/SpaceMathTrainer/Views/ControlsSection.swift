import Foundation
import SwiftUI

struct ControlsSection: View {
    @ObservedObject var appState: AppState
    @ObservedObject var speechManager: SpeechManager
    @ObservedObject var gameManager: MathGameManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Язык
            HStack {
                Text(appState.localizedString("language"))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Spacer()
                
                Picker("", selection: $appState.selectedLanguage) {
                    ForEach(appState.availableLanguages, id: \.self) { languageCode in
                        Text(getLanguageDisplayName(languageCode))
                            .font(.system(size: 12, design: .monospaced))
                            .tag(languageCode)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 120)
                .onChange(of: appState.selectedLanguage) { _, newLanguage in
                    print("🌍 Language picker changed to: \(newLanguage)")
                    appState.changeLanguage(to: newLanguage)
                }
            }
            
            Divider()
                .background(Color.cyan.opacity(0.3))
            
            // Операции
            HStack {
                Text(appState.localizedString("operations"))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(MathOperation.allCases, id: \.self) { operation in
                        Button(action: {
                            if appState.selectedOperations.contains(operation) {
                                if appState.selectedOperations.count > 1 {
                                    appState.selectedOperations.remove(operation)
                                }
                            } else {
                                appState.selectedOperations.insert(operation)
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text(operation.rawValue)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                Text(appState.getLocalizedOperationName(operation))
                                    .font(.system(size: 8, design: .monospaced))
                            }
                            .foregroundColor(.white)
                            .frame(width: 60, height: 40)
                            .background(
                                appState.selectedOperations.contains(operation) ?
                                Color.blue.opacity(0.7) : Color.gray.opacity(0.3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(
                                        appState.selectedOperations.contains(operation) ?
                                        Color.blue : Color.gray,
                                        lineWidth: 2
                                    )
                            )
                            .shadow(
                                color: appState.selectedOperations.contains(operation) ?
                                Color.blue.opacity(0.5) : Color.clear,
                                radius: 4
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Divider()
                .background(Color.cyan.opacity(0.3))
            
            // Сложность
            HStack {
                Text(appState.localizedString("difficulty"))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Spacer()
                
                Picker("", selection: $appState.selectedDifficulty) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        Text(appState.getLocalizedDifficultyName(difficulty))
                            .font(.system(size: 12, design: .monospaced))
                            .tag(difficulty)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            Divider()
                .background(Color.cyan.opacity(0.3))
            
            // Количество заданий
            HStack {
                Text(appState.localizedString("tasks_count"))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(appState.tasksCount)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Slider(value: Binding(
                        get: { Double(appState.tasksCount) },
                        set: { appState.tasksCount = Int($0) }
                    ), in: 5...50, step: 5)
                    .frame(width: 120)
                    .accentColor(.cyan)
                }
            }
            
            Divider()
                .background(Color.cyan.opacity(0.3))
            
            // Время на ответ
            HStack {
                Text(appState.localizedString("answer_time"))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(Int(appState.answerTimeLimit))")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Slider(value: $appState.answerTimeLimit, in: 10...60, step: 5)
                        .frame(width: 120)
                        .accentColor(.cyan)
                }
            }
        }
        .padding(12)
        .background(
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.02, green: 0.02, blue: 0.1, opacity: 0.3),
                                Color(red: 0.05, green: 0.05, blue: 0.15, opacity: 0.2),
                                Color(red: 0.03, green: 0.03, blue: 0.12, opacity: 0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Rectangle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.6),
                                Color.cyan.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .shadow(color: .blue.opacity(0.3), radius: 6)
        .onAppear {
            // Связываем AppState с SpeechManager
            appState.setSpeechManager(speechManager)
        }
    }
    
    // Вспомогательная функция для отображения названий языков
    private func getLanguageDisplayName(_ languageCode: String) -> String {
        switch languageCode {
        case "en": return "ENG"
        case "ru": return "РУС"
        default: return languageCode.uppercased()
        }
    }
}
