# BabySounds 🍼🎵

[![iOS Build](https://github.com/vpavlov-me/BabySounds/actions/workflows/ios-build.yml/badge.svg)](https://github.com/vpavlov-me/BabySounds/actions/workflows/ios-build.yml)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![iOS 17.0+](https://img.shields.io/badge/iOS-17.0+-blue)](https://developer.apple.com/ios/)
[![Kids Category](https://img.shields.io/badge/Category-Kids-green)](https://developer.apple.com/app-store/kids-apps/)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen)](https://swift.org/package-manager/)

> **Production-Ready Kids Category iOS App** - Professional sleep aid app for children with modular Swift Package Manager architecture.

## 🏗 Архитектура проекта

Проект организован с **Feature-First** подходом и модульной архитектурой через SPM:

```
BabySounds/
├── 📱 BabySounds/        # Основное приложение (SwiftUI + Swift 6)
├── 📦 Packages/          # SPM модули (Core + UI)
├── 🛠 Tools/            # DevOps инструменты
├── 📚 Examples/         # Примеры использования
└── 📖 docs/            # Полная документация
```

**Детальная документация:** [📁 Структура проекта](docs/PROJECT_STRUCTURE.md)

## 🚀 Быстрый старт

### Требования
- **Xcode 15.4+** (iOS 17 SDK)
- **Swift 6.0+** 
- **macOS Ventura 13.0+**
- Apple Developer Account (для StoreKit)

### Установка

```bash
# Клонирование проекта
git clone https://github.com/vpavlov-me/BabySounds.git
cd BabySounds

# Автоматическая настройка
make bootstrap

# Альтернативно: ручная настройка
swift package resolve
```

### Сборка и тестирование

```bash
# Сборка всех модулей
swift build

# Запуск тестов
swift test

# Проверка кода
make lint

# Форматирование
make format
```

## 📦 Модули SPM

### BabySoundsCore
Основная логика без UI dependencies:
- 🔊 AudioEngine управление
- 📊 Data services и модели  
- ⚡ Utilities и extensions

### BabySoundsUI  
Переиспользуемые SwiftUI компоненты:
- 🧩 UI Components
- 🎨 Design System
- ♿ Accessibility support

## 🎯 Ключевые фичи

- **🎵 Audio Engine** - AVAudioEngine с поддержкой 4+ звуков
- **⏰ Sleep Schedules** - Smart расписание сна
- **💳 StoreKit 2** - Подписки без сторонних SDK
- **👨‍👩‍👧‍👦 Parental Gate** - Безопасность для детей
- **🌍 Локализация** - EN/RU с поддержкой новых языков
- **♿ Accessibility** - VoiceOver и Switch Control

## 📋 Команды разработки

```bash
# Разработка
make dev          # Запуск development сервера
make test         # Все тесты
make test-ui      # UI тесты
make clean        # Очистка

# Качество кода  
make lint         # SwiftLint проверка
make format       # SwiftFormat автоформат
make danger       # Danger PR проверки

# Деплой
make build        # Release сборка
make archive      # Archive для App Store
fastlane beta     # TestFlight upload
```

## 📖 Документация

- **[📁 Структура проекта](docs/PROJECT_STRUCTURE.md)** - Архитектура и организация
- **[🔧 Техническая документация](docs/technical/)** - Глубокое погружение  
- **[👨‍💻 Contributing Guide](docs/development/CONTRIBUTING.md)** - Workflow разработки
- **[🏪 App Store материалы](docs/app-store/)** - Релиз процедуры
- **[🚀 Отчет о реорганизации](docs/REFACTORING_SUMMARY.md)** - Проделанная работа

## ✅ Принципы проекта

### 1. **Swift 6 + SwiftUI-only**
- Никаких UIKit/Storyboard
- Никаких force unwrap
- Async/await для асинхронности

### 2. **Feature-First Architecture**  
- Каждая фича — отдельная папка
- Структура: `Feature > Data > UI > Tests`
- Четкие boundaries

### 3. **Kids Category Compliance**
- COPPA совместимость
- Parental controls
- Безопасная громкость (WHO guidelines)
- Никаких сторонних трекеров

### 4. **Production Quality**
- Comprehensive testing (Unit/UI/Integration)
- CI/CD через GitHub Actions + Fastlane
- Автоматический code quality контроль
- StoreKit тестирование

## 🤝 Contributing

Мы приветствуем вклад в развитие проекта! 

1. **Прочитайте** [Contributing Guide](docs/development/CONTRIBUTING.md)
2. **Создайте** feature branch
3. **Следуйте** code style (SwiftLint + SwiftFormat)
4. **Добавьте** тесты для новой функциональности
5. **Создайте** Pull Request

## 📄 Лицензия

MIT License. Подробности в [LICENSE](LICENSE) файле.

## 📞 Поддержка

- **Issues:** [GitHub Issues](https://github.com/vpavlov-me/BabySounds/issues)
- **Документация:** [docs/](docs/)
- **Email:** support@babysounds.app

---

**Сделано с ❤️ для детей и их родителей** 