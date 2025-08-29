import SwiftUI
import UIKit
import AudioToolbox

// MARK: - Модальное окно выбора режима таблицы умножения
struct MultiplierSelectionModal: View {
    @ObservedObject var appState: AppState
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Полупрозрачный черный фон
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    closeModal()
                }
            
            VStack(spacing: 20) {
                // Заголовок
                VStack(spacing: 8) {
                    Text("🔢")
                        .font(.system(size: 40))
                    
                    Text(appState.localizedString("multiplicationTable"))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                // Кнопка "Случайный режим"
                MultiplierModeButton(
                    title: appState.selectedLanguage == "ru" ? "Случайные множители" : "Random Multipliers",
                    subtitle: appState.selectedLanguage == "ru" ? "2×? до 9×?" : "2×? to 9×?",
                    icon: "🎲",
                    isSelected: appState.selectedMultiplier == 0,
                    appState: appState
                ) {
                    appState.selectedMultiplier = 0
                    selectMultiplicationTable()
                }
                
                // Разделитель
                Rectangle()
                    .fill(Color.cyan.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                
                // Заголовок для конкретных таблиц
                Text(appState.selectedLanguage == "ru" ? "Конкретная таблица:" : "Specific table:")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                // Сетка кнопок для конкретных множителей (2-9)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(2...9, id: \.self) { multiplier in
                        MultiplierNumberButton(
                            number: multiplier,
                            isSelected: appState.selectedMultiplier == multiplier,
                            appState: appState
                        ) {
                            appState.selectedMultiplier = multiplier
                            selectMultiplicationTable()
                        }
                    }
                }
                
                // Кнопка закрытия
                Button(action: closeModal) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                        Text(appState.selectedLanguage == "ru" ? "Закрыть" : "Close")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.9),
                                Color.black.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: Color.cyan.opacity(0.3), radius: 15)
            .padding(.horizontal, 20)
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
    
    private func selectMultiplicationTable() {
        // Добавляем операцию таблицы умножения в выбранные
        appState.selectedOperations.insert(.multiplicationTable)
        
        // Тактильная обратная связь
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Звук подтверждения
        AudioServicesPlaySystemSound(1057) // Tink
        
        // Закрываем модал через небольшую задержку
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            closeModal()
        }
    }
    
    private func closeModal() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

// MARK: - Кнопка режима множителей
struct MultiplierModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    @ObservedObject var appState: AppState
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 32))
                
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.orange.opacity(0.3) : Color.white.opacity(0.1))
                    .stroke(isSelected ? Color.orange : Color.cyan.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.orange.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Кнопка конкретного числа
struct MultiplierNumberButton: View {
    let number: Int
    let isSelected: Bool
    @ObservedObject var appState: AppState
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Text("\(number)")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("×\(number)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .frame(width: 60, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.4) : Color.white.opacity(0.1))
                    .stroke(isSelected ? Color.blue : Color.cyan.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : .clear, radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
