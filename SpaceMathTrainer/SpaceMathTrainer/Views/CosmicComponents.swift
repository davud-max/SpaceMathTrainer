import Foundation
import SwiftUI

// MARK: - Cosmic Background with Stationary Blinking Stars (BLACK BACKGROUND)
struct ImprovedCosmicBackgroundView: View {
    @State private var starPositions: [(x: CGFloat, y: CGFloat)] = []
    @State private var starSizes: [CGFloat] = []
    @State private var starColors: [Color] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // ИЗМЕНЕНО: Полностью черный фон
                Rectangle()
                    .fill(Color.black)
                
                // Stationary blinking stars
                ForEach(0..<150, id: \.self) { index in
                    if starPositions.indices.contains(index) &&
                       starSizes.indices.contains(index) &&
                       starColors.indices.contains(index) {
                        StationaryBlinkingStar(
                            size: starSizes[index],
                            position: starPositions[index],
                            color: starColors[index],
                            index: index
                        )
                    }
                }
                
                // Subtle nebulae (completely stationary)
                ForEach(0..<6, id: \.self) { index in
                    StationaryNebulaEffect(
                        index: index,
                        position: CGPoint(
                            x: CGFloat.random(in: 200...geometry.size.width-200),
                            y: CGFloat.random(in: 200...geometry.size.height-200)
                        )
                    )
                }
            }
        }
        .onAppear {
            generateStars()
        }
    }
    
    private func generateStars() {
        starPositions = (0..<150).map { _ in
            (x: CGFloat.random(in: 0...1600), y: CGFloat.random(in: 0...1200))
        }
        starSizes = (0..<150).map { _ in CGFloat.random(in: 0.8...3.5) }
        starColors = (0..<150).map { _ in getRandomStarColor() }
    }
    
    private func getRandomStarColor() -> Color {
        let colors: [Color] = [
            .white, .white, .white, .white, // Больше белых звёзд
            Color(red: 0.9, green: 0.9, blue: 1.0), // Голубоватые
            Color(red: 1.0, green: 0.95, blue: 0.8), // Жёлтые
        ]
        return colors.randomElement() ?? .white
    }
}

// MARK: - Stationary Blinking Star (полное гашение/загорание)
struct StationaryBlinkingStar: View {
    let size: CGFloat
    let position: (x: CGFloat, y: CGFloat)
    let color: Color
    let index: Int
    
    @State private var isVisible: Bool = true
    
    var body: some View {
        ZStack {
            // Main star
            Circle()
                .fill(color)
                .frame(width: size, height: size)
            
            // Subtle glow for larger stars
            if size > 2.5 {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: size * 1.8, height: size * 1.8)
                    .blur(radius: 1.5)
            }
        }
        .opacity(isVisible ? 1.0 : 0.0) // Полное гашение/загорание
        .position(x: position.x, y: position.y) // ФИКСИРОВАННАЯ позиция
        .onAppear {
            startBlinking()
        }
    }
    
    private func startBlinking() {
        // Каждая звезда мигает с периодом 2 секунды, но с разными задержками
        let initialDelay = Double.random(in: 0...4) // Случайная начальная задержка
        
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            // Запускаем периодическое мигание каждые 2 секунды
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                // Полное гашение
                withAnimation(.easeOut(duration: 0.1)) {
                    isVisible = false
                }
                
                // Загорание через короткую паузу
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isVisible = true
                    }
                }
            }
        }
    }
}

// MARK: - Stationary Nebula Effect
struct StationaryNebulaEffect: View {
    let index: Int
    let position: CGPoint
    @State private var opacity: Double = 0.08
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        getNebulaColor().opacity(0.15),
                        getNebulaColor().opacity(0.08),
                        getNebulaColor().opacity(0.02),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 80
                )
            )
            .frame(width: 160, height: 160)
            .opacity(opacity)
            .position(position) // ФИКСИРОВАННАЯ позиция
            .onAppear {
                startSubtlePulsing()
            }
    }
    
    private func getNebulaColor() -> Color {
        let colors: [Color] = [
            Color.blue, Color.purple, Color.indigo
        ]
        return colors[index % colors.count]
    }
    
    private func startSubtlePulsing() {
        let delay = Double.random(in: 0...10)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(
                Animation.easeInOut(duration: 12)
                    .repeatForever(autoreverses: true)
            ) {
                opacity = Double.random(in: 0.03...0.12)
            }
        }
    }
}

// MARK: - Animated Background Elements (пустая версия)
struct AnimatedBackgroundElements: View {
    var body: some View {
        EmptyView() // Никаких движущихся элементов
    }
}
