
# 🚀 SpaceMathTrainer

**Interactive Math Skills Trainer with Voice Control for iOS**

[Русский](README.ru.md) | **English**

SpaceMathTrainer is a modern iOS application for learning and practicing mathematical skills using voice interaction, speech recognition, and adaptive audio notifications.

## ✨ Features

### 🎯 Interactive Mathematics
- **Voice Questions** - App speaks mathematical problems aloud
- **Voice Answers** - Answer with your voice, no typing required
- **Instant Feedback** - Audio and haptic notifications

### 📚 Mathematical Operations
- ➕ **Addition** - Addition problems
- ➖ **Subtraction** - Subtraction problems  
- ✖️ **Multiplication** - Multiplication tables and general problems
- ➗ **Division** - Integer division problems

### 🎚️ Difficulty Settings
- **Easy Level** - Numbers from 1 to 10
- **Medium Level** - Numbers from 1 to 50
- **Hard Level** - Numbers from 1 to 100

### 🌍 Multilingual Support
- **Russian Language** - Full Russian speech support
- **English Language** - Full English speech support
- **Automatic Voice Switching** and recognition

### 🔊 Advanced Audio System
- **High-Quality Sounds** using AVAudioPlayer
- **Different Tones** for correct and incorrect answers
- **Haptic Feedback** (vibration) on supported devices
- **Milena Voice** for Russian language (when available)

## 🛠 Technical Requirements

### Minimum Requirements
- **iOS 15.0+**
- **iPhone/iPad** with microphone support
- **Permissions**: Microphone and Speech Recognition

### Recommended Settings
- **Media Volume**: 75%+
- **Silent Mode Switch**: Disabled
- **Settings > Sounds > Keyboard Clicks**: Enabled
- **Headphones**: Recommended for better audio quality

## 🏗 Architecture

### Core Components

#### `MathGameManager`
- Game process management
- Mathematical problem generation
- Answer processing and result tracking
- Audio system coordination

#### `SpeechManager`
- Speech synthesis (Text-to-Speech)
- Speech recognition (Speech-to-Text)
- Audio session management
- Sound notifications and feedback

#### `AppState`
- Global application state
- User preferences
- Component coordination

### Used Frameworks
- **SwiftUI** - User interface
- **AVFoundation** - Audio and speech synthesis
- **Speech** - Speech recognition
- **AudioToolbox** - System sounds and haptics

## 🚀 Installation and Setup

### Prerequisites
```bash
Xcode 14.0+
iOS 15.0+ deployment target
macOS 12.0+ for development
```

### Clone Repository
```bash
git clone https://github.com/your-username/SpaceMathTrainer.git
cd SpaceMathTrainer
```

### Project Setup
1. Open `SpaceMathTrainer.xcodeproj` in Xcode
2. Select target device (iPhone/iPad)
3. Ensure correct development team is selected
4. Run the project (`Cmd + R`)

### Permissions
On first launch, the app will request:
- **Microphone Access** - For voice answer recognition
- **Speech Recognition** - For voice command processing

## 📱 Usage

### Starting Training
1. Select **mathematical operations** (multiple allowed)
2. Set **difficulty level**
3. Choose **number of problems**
4. Set **interface language**
5. Tap **"Start Training"**

### Learning Process
1. **Listen to question** - App will speak a math problem
2. **Answer with voice** - Speak the answer clearly
3. **Receive feedback** - Sound and vibration confirm correctness
4. **Move to next** - Automatically or by timeout

### Controls
- **Repeat Question** - "🔄" button
- **Skip Question** - "⏭️" button
- **Stop Training** - "⏹️" button

## 🔧 Configuration and Troubleshooting

### Audio Issues
If sounds don't play:

1. **Check Silent Mode Switch**
   ```
   Physical switch on left side of iPhone
   Red stripe visible = Silent mode enabled
   ```

2. **Increase Media Volume**
   ```
   Use volume buttons ⬆️⬇️
   Recommended 75%+
   ```

3. **Check Sound Settings**
   ```
   Settings > Sounds & Haptics > Keyboard Clicks = ON
   ```

4. **Connect Headphones**
   ```
   Often resolves iPhone speaker issues
   ```

### Speech Recognition Issues
If speech recognition fails:

1. **Speak clearly and loudly**
2. **Minimize background noise**
3. **Ensure microphone isn't blocked**
4. **Check permissions in Settings > Privacy**

### Debugging
For detailed logging:
```swift
print("🔊 Audio session volume: \(audioSession.outputVolume)")
print("📱 Current audio route: \(currentRoute.outputs)")
print("🎤 Microphone permission: \(microphonePermission)")
```

## 📊 Statistics and Results

### Progress Tracking
- **Number of correct answers**
- **Total number of questions**
- **Success percentage**
- **Response time for each question**
- **Answer history**

### Result Format
```swift
struct TaskResult {
    let question: String        // Question text
    let userAnswer: String      // User's answer
    let correctAnswer: Int      // Correct answer
    let isCorrect: Bool         // Correctness
    let responseTime: TimeInterval // Response time
    let timestamp: Date         // Question timestamp
}
```

## 🤝 Contributing

### Code Structure
```
SpaceMathTrainer/
├── Models/
│   ├── MathOperation.swift
│   ├── Difficulty.swift
│   └── TaskResult.swift
├── Managers/
│   ├── MathGameManager.swift
│   ├── SpeechManager.swift
│   └── AppState.swift
├── Views/
│   ├── ContentView.swift
│   ├── GameView.swift
│   └── SettingsView.swift
└── Resources/
    ├── Info.plist
    └── Assets.xcassets
```

### Code Guidelines
- Use `@MainActor` for UI operations
- Handle audio session errors properly
- Test on real devices
- Follow MVVM principles

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📝 License

MIT License

```
MIT License

Copyright (c) 2024 SpaceMathTrainer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 🆘 Support

### Common Issues
- **No Sound** → Check silent mode switch
- **Speech Not Recognized** → Check microphone permissions
- **Poor Audio Quality** → Use headphones
- **App Crashes** → Update iOS to latest version

### Getting Help
- **Issues**: [GitHub Issues](https://github.com/your-username/SpaceMathTrainer/issues)
- **Documentation**: [Wiki](https://github.com/your-username/SpaceMathTrainer/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/SpaceMathTrainer/discussions)

### Contact
- **Email**: your-email@example.com
- **Twitter**: [@your_handle](https://twitter.com/your_handle)
- **Telegram**: [@your_username](https://t.me/your_username)

## 🏆 Acknowledgments

- **Apple** - For excellent Speech and AVFoundation frameworks
- **iOS Community** - For continuous inspiration and support
- **Beta Testers** - For valuable feedback and bug reports

## 🗺 Roadmap

### Upcoming Features
- [ ] **Custom Problem Sets** - Create your own math problems
- [ ] **Progress Analytics** - Detailed learning analytics
- [ ] **Multiplayer Mode** - Compete with friends
- [ ] **Apple Watch Support** - Training on your wrist
- [ ] **More Languages** - Spanish, French, German support
- [ ] **Adaptive Learning** - AI-powered difficulty adjustment

### Version History
- **v1.0.0** - Initial release with basic math operations
- **v1.1.0** - Added voice recognition and feedback
- **v1.2.0** - Enhanced audio system and multi-language support

---

**SpaceMathTrainer** - Making math learning interactive and engaging! 🚀📱✨

## 📱 Download

[<img src="https://developer.apple.com/app-store/marketing/guidelines/images/badge-example-preferred.png" width="200">](https://apps.apple.com/app/spacemathtrainer/id1234567890)

*Download from the App Store*
