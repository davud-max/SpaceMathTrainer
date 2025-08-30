import SwiftUI
import UIKit
import AudioToolbox

// MARK: - Language Selection Button (компактная для iPhone)
struct LanguageButton: View {
    let language: String
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject var appState: AppState
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 4) {
                Text(flagForLanguage(language))
                    .font(.system(size: 12))
                
                Text(nameForLanguage(language))
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 24)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.blue, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func flagForLanguage(_ language: String) -> String {
        switch language {
        case "en": return "🇺🇸"
        case "ru": return "🇷🇺"
        default: return "🌍"
        }
    }
    
    private func nameForLanguage(_ language: String) -> String {
        switch language {
        case "en": return "ENG"
        case "ru": return "РУС"
        default: return language.uppercased()
        }
    }
}

// MARK: - Language Selection View (компактная для iPhone)
struct LanguageSelectionView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("🌍")
                    .font(.system(size: 14))
                Text(appState.localizedString("language"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
            }
            
            HStack(spacing: 8) {
                ForEach(appState.availableLanguages, id: \.self) { language in
                    LanguageButton(
                        language: language,
                        isSelected: appState.selectedLanguage == language,
                        action: {
                            appState.changeLanguage(to: language)
                        },
                        appState: appState
                    )
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - ОБНОВЛЕННАЯ Math Operation Button (УВЕЛИЧИЛИ РАЗМЕР)
struct MathOperationButton: View {
    let operation: MathOperation
    @ObservedObject var appState: AppState
    let action: () -> Void
    @State private var showMultiplierModal = false
    
    var body: some View {
        let isSelected = appState.selectedOperations.contains(operation)
        
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // При выборе умножения или деления - деактивируем остальные операции
            if operation == .multiplicationTable {
                showMultiplierModal = true
            } else if operation == .division {
                // Деактивируем все остальные операции при выборе деления
                appState.selectedOperations.removeAll()
                appState.selectedOperations.insert(.division)
            } else {
                // Для остальных операций - обычная логика
                // Но если умножение или деление уже выбрано, сначала убираем их
                if appState.selectedOperations.contains(.multiplicationTable) ||
                   appState.selectedOperations.contains(.division) {
                    appState.selectedOperations.removeAll()
                }
                action()
            }
        }) {
            // УВЕЛИЧЕН размер кнопки и символа
            Text(getOperationDisplaySymbol(operation))
                .font(.system(size: 20, weight: .bold, design: .monospaced)) // Увеличен размер
                .foregroundColor(.white)
                .frame(width: 60, height: 40) // Увеличен размер кнопки
                .background(isSelected ? Color.blue.opacity(0.6) : Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8) // Увеличен радиус
                        .stroke(isSelected ? Color.cyan : Color.blue, lineWidth: 1.5) // Увеличена толщина
                )
                .shadow(color: isSelected ? .cyan.opacity(0.4) : .clear, radius: 3) // Увеличена тень
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showMultiplierModal) {
            UpdatedMultiplierSelectionModal(appState: appState, isPresented: $showMultiplierModal)
        }
    }
    
    private func getOperationDisplaySymbol(_ operation: MathOperation) -> String {
        return operation.rawValue // Просто возвращаем символ операции
    }
}

// MARK: - ОБНОВЛЕННОЕ модальное окно выбора множителя
struct UpdatedMultiplierSelectionModal: View {
    @ObservedObject var appState: AppState
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    closeModal()
                }
            
            VStack(spacing: 16) {
                // Заголовок
                VStack(spacing: 6) {
                    Text("×")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    Text(appState.localizedString("multiplicationTable"))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                // ОБНОВЛЕНО: Кнопка случайных множителей (используем переводы)
                Button(action: {
                    appState.selectedMultiplier = 0
                    selectMultiplicationTable()
                }) {
                    VStack(spacing: 6) {
                        Text(appState.localizedString("randomMultipliers"))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text(appState.localizedString("from2to9"))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, minHeight: 55)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(appState.selectedMultiplier == 0 ? Color.orange.opacity(0.3) : Color.white.opacity(0.1))
                            .stroke(appState.selectedMultiplier == 0 ? Color.orange : Color.cyan.opacity(0.5), lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Разделитель
                Rectangle()
                    .fill(Color.cyan.opacity(0.3))
                    .frame(height: 1)
                
                // ОБНОВЛЕНО: Выбор множимого (используем переводы)
                Text(appState.localizedString("chooseMultiplicand"))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(2...9, id: \.self) { multiplier in
                        Button(action: {
                            appState.selectedMultiplier = multiplier
                            selectMultiplicationTable()
                        }) {
                            VStack(spacing: 3) {
                                Text("\(multiplier)")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                // ОБНОВЛЕНО: Текст "два умножить", "три умножить" и т.д.
                                Text(getMultiplierText(multiplier))
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 60, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(appState.selectedMultiplier == multiplier ? Color.blue.opacity(0.4) : Color.white.opacity(0.1))
                                    .stroke(appState.selectedMultiplier == multiplier ? Color.blue : Color.cyan.opacity(0.5), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Кнопка закрытия (используем переводы)
                Button(action: closeModal) {
                    Text(appState.localizedString("close"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.95))
                    .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: Color.cyan.opacity(0.3), radius: 15)
            .padding(.horizontal, 20)
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
    
    private func getMultiplierText(_ multiplier: Int) -> String {
        if appState.selectedLanguage == "ru" {
            let numbers = ["", "", "два", "три", "четыре", "пять", "шесть", "семь", "восемь", "девять"]
            return "\(numbers[multiplier])\nумножить"
        } else {
            let numbers = ["", "", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
            return "\(numbers[multiplier])\nmultiply"
        }
    }
    
    private func selectMultiplicationTable() {
        // Деактивируем все остальные операции при выборе умножения
        appState.selectedOperations.removeAll()
        appState.selectedOperations.insert(.multiplicationTable)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        AudioServicesPlaySystemSound(1057) // Tink
        
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

// MARK: - Difficulty Button (компактная для iPhone)
struct DifficultyButton: View {
    let difficulty: Difficulty
    @ObservedObject var appState: AppState
    let action: () -> Void
    
    var body: some View {
        let isSelected = appState.selectedDifficulty == difficulty
        
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 2) {
                Text(iconForDifficulty(difficulty))
                    .font(.system(size: 12))
                
                Text(appState.getLocalizedDifficultyName(difficulty))
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 28)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.blue, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForDifficulty(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy: return "🟢"
        case .medium: return "🟡"
        case .hard: return "🔴"
        }
    }
}

// MARK: - Control Button (компактная для iPhone)
struct ControlButton: View {
    let icon: String
    let text: String
    let color: Color
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Text(text)
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(minWidth: 40, minHeight: 30)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(isDisabled ? Color.clear : color.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isDisabled ? Color.white.opacity(0.3) : Color.white.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Responsive Grid для iPhone
struct ResponsiveGrid<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    init(spacing: CGFloat = 4, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.content()
        }
    }
}

// MARK: - Современные компактные кнопки для iPhone
struct ModernButton: View {
    let title: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    init(title: String, icon: String, color: Color = .blue, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEnabled ? color.opacity(0.8) : Color.gray.opacity(0.4))
                    .shadow(color: isEnabled ? color.opacity(0.4) : .clear, radius: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEnabled ? color : Color.gray, lineWidth: 1)
            )
            .scaleEffect(isEnabled ? 1.0 : 0.95)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Компактная карточка для группировки элементов на iPhone
struct CardView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            content
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Компактный переключатель для iPhone
struct ToggleCard: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let action: (() -> Void)?
    
    init(title: String, icon: String, isOn: Binding<Bool>, action: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self._isOn = isOn
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isOn.toggle()
            }
            action?()
        }) {
            HStack {
                Text(icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isOn ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 28, height: 16)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .offset(x: isOn ? 6 : -6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.2))
                    .stroke(isOn ? Color.green.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
