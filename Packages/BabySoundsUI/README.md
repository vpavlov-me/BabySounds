# BabySoundsUI

Переиспользуемые UI компоненты для BabySounds.

## 🎯 Назначение

Этот пакет содержит:
- 🧩 **Components** - базовые UI компоненты
- 🖼 **Views** - сложные композитные View
- ✨ **Modifiers** - кастомные ViewModifier
- 🎨 **Design System** - цвета, шрифты, отступы

## 📋 Зависимости

- Swift 6.0+
- iOS 17.0+
- SwiftUI
- BabySoundsCore

## 🏗 Архитектура

```
BabySoundsUI/
├── Components/         # Базовые компоненты
│   ├── Buttons/       # Кнопки
│   ├── Cards/         # Карточки
│   └── Controls/      # Элементы управления
├── Views/             # Сложные View
│   ├── Sheets/        # Модальные окна
│   └── Overlays/      # Оверлеи
└── Modifiers/         # ViewModifier
    ├── Animations/    # Анимации
    └── Styling/       # Стили
```

## 🚀 Использование

```swift
import BabySoundsUI

struct ContentView: View {
    var body: some View {
        VStack {
            BabyButton(
                title: "Play Sound",
                style: .primary
            ) {
                // Action
            }
            
            SoundCard(sound: .whiteNoise)
                .kidsSafeModifier()
        }
    }
}
```

## ✅ Принципы

- **SwiftUI-only** - никакого UIKit
- **Accessibility** - VoiceOver support
- **Kids-safe** - безопасность для детей
- **Reusable** - максимальная переиспользуемость
- **Testable** - UI тесты включены 