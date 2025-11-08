# BabySounds - Правила работы с проектом для AI-разработки

> Быстрый справочник для Claude и других AI-инструментов при работе с проектом BabySounds

## 📋 Обзор проекта

**BabySounds** - iOS приложение для детского сна с профессиональными звуками и родительским контролем.

- **Платформа**: iOS 17.0+
- **Язык**: Swift 6.0
- **UI**: SwiftUI
- **Архитектура**: MVVM + Swift Package Manager
- **Статус**: v1.0 на 95% (подготовка к App Store)

### Ключевые метрики
- 12,907 строк Swift кода
- 48 unit тестов
- Без внешних зависимостей
- COPPA-совместимо, WHO hearing safety guidelines

---

## 🏗 Архитектура проекта

### Структура директорий

```
BabySounds/
├── Package.swift                    # SPM манифест
├── BabySounds/Sources/BabySounds/  # Основное приложение (12,907 LOC)
│   ├── App/                        # Точка входа приложения
│   ├── Core/                       # Бизнес-логика
│   │   ├── Audio/                  # Аудио-движок (1,780 LOC)
│   │   │   ├── AudioEngineManager.swift      (799 LOC)
│   │   │   ├── SafeVolumeManager.swift       (477 LOC)
│   │   │   └── BackgroundAudioManager.swift  (504 LOC)
│   │   ├── Data/                   # Менеджеры данных
│   │   └── Models/                 # Модели данных
│   ├── Features/                   # Экраны функций
│   │   ├── Sleep/                  # Библиотека звуков
│   │   ├── Playroom/               # Детский интерфейс
│   │   ├── Favorites/              # Избранные звуки
│   │   ├── Schedules/              # Расписания сна
│   │   ├── Settings/               # Настройки
│   │   ├── ParentalControls/       # Родительский контроль
│   │   └── Subscription/           # StoreKit 2
│   ├── Services/                   # Внешние сервисы
│   ├── UI/                         # Переиспользуемые компоненты
│   └── Resources/                  # Аудио файлы, JSON
├── Packages/                       # SPM модули
│   ├── BabySoundsCore/            # Основная библиотека
│   └── BabySoundsUI/              # UI компоненты
└── docs/                          # Документация
```

### Ключевые компоненты

1. **Аудио система** (1,780 LOC)
   - Multi-track playback (до 4 треков одновременно)
   - WHO volume safety compliance
   - Fade-in/fade-out эффекты
   - Background playback + Now Playing integration

2. **Премиум система**
   - StoreKit 2 integration
   - Feature gating (Favorites, Timer, Custom Mixes)
   - Monthly $4.99 / Annual $29.99

3. **Родительский контроль**
   - Math challenges
   - Parent gate для защищённых действий
   - 5-минутный таймаут после верификации

4. **Расписания сна**
   - Автоматический запуск звуков
   - Повторение по дням недели
   - Интеграция с уведомлениями

---

## 🔧 Технические требования

### Обязательно

- macOS 14.0 (Sonoma) или новее
- Xcode 15.4 или новее
- Swift 6.0
- Git

### Рекомендуется

- GitHub CLI (`gh`)
- SwiftLint (форматирование)
- SwiftFormat (стиль кода)

### Проверка окружения

```bash
# Версия Xcode
xcodebuild -version  # Должно быть 15.4+

# Версия Swift
swift --version      # Должно быть 6.0+

# Git
git --version
```

---

## 🚀 Быстрый старт для AI-разработки

### 1. Открытие проекта

```bash
cd /Users/pavlov/Documents/Vibecoding/BabySounds/BabySounds
open Package.swift
```

### 2. Сборка и запуск

```bash
# Сборка
swift build

# Запуск тестов
swift test

# В Xcode
# Cmd+B - Build
# Cmd+R - Run
# Cmd+U - Test
```

### 3. Структура схем

- **BabySoundsApp** - основная схема для запуска
- Рекомендуемый симулятор: iPhone 15 Pro

---

## 📝 Git Workflow

### Текущая фаза (Pre-v1.0)

**ВАЖНО**: До релиза v1.0 работаем напрямую в ветке `main`

```bash
# Текущий workflow
git checkout main
git pull origin main

# ... делаем изменения ...

git add .
git commit -m "feat(scope): description"
git push origin main
```

### Правила для main

✅ **МОЖНО:**
- Коммитить часто с чёткими сообщениями
- Тестировать перед коммитом
- Атомарные и фокусированные коммиты
- Conventional commit формат

❌ **НЕЛЬЗЯ:**
- Ломать сборку в main
- Work-in-progress коммиты
- Коммиты без тестирования

### Формат коммит-сообщений

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Types:**
- `feat` - новая функция
- `fix` - исправление бага
- `docs` - документация
- `style` - форматирование кода
- `refactor` - рефакторинг
- `test` - тесты
- `chore` - обслуживание

**Scopes:**
- `audio` - аудио система
- `ui` - интерфейс
- `premium` - премиум функции
- `safety` - безопасность (volume, parent gate)
- `schedule` - расписания
- `settings` - настройки
- `store` - покупки

**Примеры:**
```bash
feat(audio): implement buffer scheduling for playback
fix(volume): correct WHO decibel calculation
docs: update README with new features
test: add unit tests for AudioEngineManager
```

### После v1.0 (Future)

После релиза переходим на feature branch workflow:
- `main` - production
- `develop` - integration
- `feature/*` - новые функции
- `fix/*` - исправления
- `hotfix/*` - критические исправления

---

## 💻 Стандарты кодирования

### Swift Style Guide

Следуем Apple Swift API Design Guidelines:

```swift
// Типы: UpperCamelCase
class AudioEngineManager { }
struct Sound { }
enum SoundCategory { }

// Переменные и функции: lowerCamelCase
var currentSound: Sound?
func playSound(_ sound: Sound) { }

// Константы: lowerCamelCase
let maxVolume = 1.0
let defaultFadeDuration = 2.0
```

### Swift 6 Requirements

❌ **ЗАПРЕЩЕНО:**
```swift
// Force unwrapping
let sound = sounds[id]!

// Implicitly unwrapped optionals
var currentSound: Sound!
```

✅ **ПРАВИЛЬНО:**
```swift
// Optional binding
guard let sound = sounds[id] else { return }

// Explicit optionals
var currentSound: Sound?

// @MainActor для UI
@MainActor
class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
}
```

### Организация кода

```swift
// MARK: - Type Definition
class SoundManager {

    // MARK: - Properties
    private var sounds: [Sound] = []

    // MARK: - Initialization
    init() {
        loadSounds()
    }

    // MARK: - Public Methods
    func play(_ sound: Sound) {
        // Implementation
    }

    // MARK: - Private Methods
    private func loadSounds() {
        // Implementation
    }
}
```

### Accessibility

Все UI должно быть доступным:

```swift
Button("Play Sound") { }
    .accessibilityLabel("Play white noise sound")
    .accessibilityHint("Double tap to start playing")
    .accessibilityAddTraits(.startsMediaSession)
```

---

## 🧪 Тестирование

### Структура тестов

```swift
import XCTest
@testable import BabySounds

final class SoundManagerTests: XCTestCase {

    var sut: SoundManager!

    override func setUp() {
        super.setUp()
        sut = SoundManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testPlaySound_WhenSoundExists_ReturnsTrue() {
        // Given
        let sound = Sound.whitenoise

        // When
        let result = sut.play(sound)

        // Then
        XCTAssertTrue(result)
    }
}
```

### Запуск тестов

```bash
# Все тесты
swift test

# Конкретный тест
swift test --filter AudioEngineManagerTests

# С покрытием
swift test --enable-code-coverage
```

---

## 🎯 Правила для AI-ассистента

### Что делать ВСЕГДА

1. **Читать файлы перед изменением**
   - Используй `Read` tool перед `Edit` или `Write`
   - Понимай контекст изменений

2. **Проверять перед коммитом**
   ```bash
   swift build  # Сборка без ошибок
   swift test   # Все тесты проходят
   ```

3. **Следовать конвенциям**
   - Swift 6 strict concurrency
   - No force unwrapping
   - MVVM architecture
   - Accessibility-first

4. **Документировать изменения**
   - Добавлять комментарии к сложной логике
   - Обновлять документацию при необходимости

### Что делать НИКОГДА

❌ **ЗАПРЕЩЕНО:**
- Создавать файлы без необходимости
- Использовать force unwrapping (`!`)
- Использовать implicitly unwrapped optionals (`!`)
- Коммитить незавершённый код в main
- Пушить сломанную сборку
- Игнорировать тесты
- Добавлять TODO комментарии (используй Issues)

### Безопасность

- Проверяй на уязвимости: XSS, SQL injection, command injection
- Следуй WHO guidelines для громкости
- COPPA compliance - никаких данных от детей
- Parent gate для всех чувствительных действий

### Типичные задачи

**1. Добавление новой функции:**
```bash
# 1. Создать модель в Core/Models/
# 2. Создать ViewModel в Features/[Feature]/
# 3. Создать View в Features/[Feature]/
# 4. Добавить тесты в Tests/
# 5. Обновить документацию
```

**2. Исправление бага:**
```bash
# 1. Воспроизвести баг
# 2. Написать failing test
# 3. Исправить код
# 4. Убедиться что тест проходит
# 5. Закоммитить: fix(scope): description
```

**3. Рефакторинг:**
```bash
# 1. Убедиться что все тесты проходят
# 2. Сделать рефакторинг
# 3. Убедиться что тесты ещё проходят
# 4. Закоммитить: refactor(scope): description
```

---

## 📚 Ключевые файлы для справки

### Основная логика

- `AudioEngineManager.swift` (799 LOC) - multi-track audio engine
- `SafeVolumeManager.swift` (477 LOC) - WHO volume safety
- `BackgroundAudioManager.swift` (504 LOC) - background playback
- `PremiumManager.swift` - feature gating
- `ParentGateManager.swift` - parental controls
- `SleepScheduleManager.swift` - schedules

### Модели данных

- `Sound.swift` - звуковые объекты
- `SoundCategory.swift` - категории звуков
- `SleepSchedule.swift` - расписания

### UI компоненты

- `SoundCard.swift` - карточка звука
- `MiniPlayerView.swift` - мини-плеер
- `NowPlayingView.swift` - полноэкранный плеер

---

## 🔍 Полезные команды

### Поиск по коду

```bash
# Найти TODO (не должно быть!)
grep -r "TODO" --include="*.swift" .

# Найти русский текст
grep -r "[А-Яа-я]" --include="*.swift" .

# Подсчёт строк кода
find . -name "*.swift" -not -path "./Tests/*" | xargs wc -l

# Найти force unwrapping
grep -r "!" --include="*.swift" . | grep -v "!="
```

### Отладка

```bash
# Очистка build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Список симуляторов
xcrun simctl list devices

# Запуск симулятора
xcrun simctl boot "iPhone 15 Pro"
```

### Git команды

```bash
# Статус
git status
git log --oneline -10

# Откат изменений
git restore <file>
git restore .

# Откат последнего коммита (сохранить изменения)
git reset --soft HEAD~1
```

---

## 🎨 Особенности проекта

### Audio System

- **AVAudioEngine** с 4 player nodes
- Fade-in/fade-out эффекты
- Individual volume + pan control
- Gapless looping
- WHO volume limits (30-75%)

### Premium Features

- Unlimited Favorites (Free: 5)
- Extended Timer (Free: 30 min)
- Custom Mixes (4 tracks)
- StoreKit 2 integration

### Safety Features

- WHO hearing safety guidelines
- Parent gate (math challenges)
- Listening time tracking
- Safe link wrapper
- COPPA compliance

### Playroom Mode

- Large, child-friendly buttons
- Child-appropriate sound filtering
- Simple, colorful interface

---

## 📊 Текущий статус (v1.0 - 95%)

### ✅ Завершено

- Аудио-движок с multi-track
- WHO volume safety
- 5-tab интерфейс (Apple Music style)
- Parent gate с аналитикой
- Sleep schedule management
- Premium feature gating (StoreKit 2)
- 15 профессиональных звуков
- Privacy Policy & Terms of Service
- Settings screen
- 48 unit tests
- Playroom content filtering
- English локализация
- GitHub Pages документация

### 🚧 Осталось для v1.0

- App Store assets (screenshots, icon) - Issue #20
- Финальное тестирование

---

## 🚨 Критические правила

### 1. НИКОГДА не ломай сборку

```bash
# Перед коммитом ВСЕГДА:
swift build && swift test
```

### 2. Тестируй критические функции

- Audio playback
- Volume safety
- Premium feature gating
- Parent gate verification
- Schedule triggers

### 3. Безопасность детей - приоритет

- Громкость всегда в пределах WHO (30-75%)
- Parent gate для всех внешних ссылок
- Никаких данных о детях (COPPA)
- Child-appropriate content в Playroom

### 4. Accessibility - обязательно

- VoiceOver labels на всех кнопках
- Dynamic Type support
- High Contrast Mode
- Reduce Motion respect

---

## 📖 Дополнительные ресурсы

### Документация проекта

- [README.md](README.md) - общий обзор
- [CONTRIBUTING.md](CONTRIBUTING.md) - руководство для контрибьюторов
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - архитектура
- [docs/SETUP.md](docs/SETUP.md) - настройка окружения
- [docs/GIT_WORKFLOW.md](docs/GIT_WORKFLOW.md) - Git workflow
- [APP_STORE.md](APP_STORE.md) - App Store подготовка

### Apple Documentation

- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [AVFoundation](https://developer.apple.com/documentation/avfoundation)
- [StoreKit 2](https://developer.apple.com/documentation/storekit)

### GitHub

- [Issues](https://github.com/vpavlov-me/BabySounds/issues)
- [Discussions](https://github.com/vpavlov-me/BabySounds/discussions)
- [Milestone v1.0](https://github.com/vpavlov-me/BabySounds/milestone/1)

---

## 🤖 Шаблон для AI промптов

При работе с проектом используй этот контекст:

```
Проект: BabySounds
Язык: Swift 6.0, SwiftUI
Архитектура: MVVM, SPM
iOS: 17.0+
Статус: v1.0 (95% complete)

Правила:
- Работаем в main branch
- No force unwrapping (!)
- @MainActor для UI
- Accessibility-first
- WHO volume safety
- COPPA compliance
- Тестируем перед коммитом

Текущая задача: [описание]
Файлы: [список]
```

---

## ✅ Checklist перед каждым коммитом

```bash
# 1. Сборка без ошибок
swift build
# ✅ Build succeeded

# 2. Все тесты проходят
swift test
# ✅ All tests passed

# 3. Нет force unwrapping
grep -r "!" --include="*.swift" BabySounds/Sources | grep -v "!=" | wc -l
# ✅ 0 results (или только безопасные случаи)

# 4. Нет TODO комментариев
grep -r "TODO" --include="*.swift" BabySounds/Sources | wc -l
# ✅ 0 results

# 5. Conventional commit message
git commit -m "feat(scope): clear description"
# ✅ Follows convention

# 6. Push to main
git push origin main
# ✅ Pushed successfully
```

---

**Последнее обновление**: November 2024
**Версия документа**: 1.0
**Автор**: Vadim Pavlov (@vpavlov-me)

---

*Made with ❤️ for better baby sleep*
