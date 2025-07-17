# 📊 GitHub Projects Setup Guide

## 🍼 BabySounds Project Management

Эта инструкция описывает настройку GitHub Projects для эффективного управления разработкой BabySounds - Kids Category iOS приложения.

## 📋 Project 1: Development Board

### 🎯 Назначение
Основная доска для отслеживания ежедневной разработки, багфиксов и небольших улучшений.

### 📝 Создание проекта

1. Перейдите в `Projects` tab в репозитории
2. Нажмите `New project`
3. Выберите `Table` template
4. Назовите проект: `🔨 BabySounds Development`
5. Добавьте описание: `Daily development tracking for BabySounds iOS app`

### 🏗️ Структура колонок

#### 📥 Backlog
- **Назначение**: Новые задачи, ожидающие тriage
- **Автоматизация**: Новые issues автоматически попадают сюда
- **Критерии**: Любые новые задачи без назначенного исполнителя

#### 🔍 Triage  
- **Назначение**: Задачи в процессе оценки и планирования
- **Автоматизация**: Перемещается при добавлении меток priority
- **Критерии**: Issues с метками `needs-triage` или `needs-review`

#### 🏗️ In Progress
- **Назначение**: Активно разрабатываемые задачи
- **Автоматизация**: Перемещается при создании linked PR
- **Критерии**: Issues с назначенным исполнителем + активный PR

#### 👀 Review
- **Назначение**: Pull requests ожидающие код-ревью
- **Автоматизация**: PR автоматически появляются здесь
- **Критерии**: Открытые PR с запросом на ревью

#### 🧪 Testing  
- **Назначение**: Функции в процессе QA тестирования
- **Автоматизация**: Перемещается при merge в develop
- **Критерии**: Merged PR, готовые к тестированию

#### ✅ Done
- **Назначение**: Завершенные задачи
- **Автоматизация**: Перемещается при закрытии issue/PR
- **Критерии**: Closed issues/PR за последние 30 дней

### 🏷️ Custom Fields

#### Priority
- **Type**: Single select
- **Options**: 
  - 🚨 Critical (красный)
  - 🔴 High (оранжевый) 
  - 🟡 Medium (желтый)
  - 🟢 Low (зеленый)

#### Category  
- **Type**: Single select
- **Options**:
  - 🎵 Audio Engine
  - 🔒 Safety & Compliance
  - 💎 Premium Features
  - ♿ Accessibility
  - 🎨 UI/UX
  - 🔧 DevOps
  - 🐛 Bug Fix

#### Estimate
- **Type**: Number
- **Description**: Story points (1-13 fibonacci)

#### Kids Category Impact
- **Type**: Single select  
- **Options**:
  - 🛡️ COPPA Compliance
  - 🔊 Hearing Safety
  - 👶 Child Safety
  - ♿ Accessibility
  - 🚫 No Impact

### ⚙️ Automation Rules

```yaml
# .github/workflows/project-automation.yml
name: 📊 Project Board Automation

on:
  issues:
    types: [opened, closed, labeled, assigned]
  pull_request:
    types: [opened, closed, ready_for_review, review_requested]
  
jobs:
  update_project:
    runs-on: ubuntu-latest
    steps:
      - name: Move new issues to Backlog
        if: github.event.action == 'opened' && github.event.issue
        uses: alex-page/github-project-automation-plus@v0.9.0
        with:
          project: BabySounds Development
          column: Backlog
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          
      - name: Move labeled issues to Triage  
        if: github.event.action == 'labeled' && contains(github.event.label.name, 'needs-')
        uses: alex-page/github-project-automation-plus@v0.9.0
        with:
          project: BabySounds Development
          column: Triage
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          
      - name: Move assigned issues to In Progress
        if: github.event.action == 'assigned'
        uses: alex-page/github-project-automation-plus@v0.9.0
        with:
          project: BabySounds Development
          column: In Progress
          repo-token: ${{ secrets.GITHUB_TOKEN }}
```

## 🎯 Project 2: Release Planning Board

### 🎯 Назначение
Стратегическое планирование релизов и крупных функций. Отслеживание прогресса по версиям.

### 📝 Создание проекта

1. Создайте новый проект: `🚀 BabySounds Releases`
2. Выберите `Board` template
3. Добавьте описание: `Release planning and milestone tracking`

### 🏗️ Структура колонок

#### 💡 Ideas
- **Назначение**: Идеи для будущих релизов
- **Критерии**: Issues с меткой `enhancement` без milestone

#### 🎯 Planned
- **Назначение**: Функции запланированные для следующего релиза
- **Критерии**: Issues с назначенным milestone

#### 🏗️ Development
- **Назначение**: Функции в активной разработке
- **Критерии**: Issues с активными PR + milestone

#### 🧪 Testing
- **Назначение**: Функции в процессе тестирования
- **Критерии**: Merged features awaiting release

#### 📦 Release Candidate  
- **Назначение**: Готовые к релизу функции
- **Критерии**: Tested features ready for App Store

#### 🚀 Released
- **Назначение**: Функции выпущенные в App Store
- **Критерии**: Features in production

### 🏷️ Custom Fields для Release Board

#### Release Version
- **Type**: Single select
- **Options**:
  - v1.2.0 (Current)
  - v1.3.0 (Next)
  - v1.4.0 (Future)
  - v2.0.0 (Major)

#### Feature Size
- **Type**: Single select
- **Options**:
  - 🐭 Small (1-3 days)
  - 📦 Medium (1-2 weeks)  
  - 🐘 Large (3+ weeks)
  - 🦣 Epic (multiple sprints)

#### Business Impact
- **Type**: Single select
- **Options**:
  - 💰 Revenue Impact
  - 👶 User Experience
  - 🛡️ Compliance Required
  - 🔧 Technical Debt
  - 🚀 Performance

#### App Store Category
- **Type**: Multi-select
- **Options**:
  - 🆕 New Feature
  - 🔧 Improvement
  - 🐛 Bug Fix
  - 🛡️ Security Update

## 🎯 Project 3: Kids Category Compliance Board

### 🎯 Назначение  
Специальная доска для отслеживания задач связанных с Kids Category соответствием.

### 📝 Создание проекта

1. Создайте проект: `👶 Kids Category Compliance`
2. Описание: `COPPA compliance and Kids Category requirements tracking`

### 🏗️ Структура колонок

#### 🔍 Compliance Review
- **Назначение**: Задачи требующие проверки соответствия
- **Критерии**: Issues с метками `kids-category`, `coppa-compliance`

#### 🛡️ Security Audit
- **Назначение**: Безопасность и приватность
- **Критерии**: Issues с меткой `security`, `privacy`

#### ♿ Accessibility Check
- **Назначение**: Проверка доступности
- **Критерии**: Issues с меткой `accessibility`, `a11y`

#### 🔊 Audio Safety
- **Назначение**: Проверка слуховой безопасности  
- **Критерии**: Issues с меткой `hearing-protection`, `audio-bug`

#### ✅ Approved
- **Назначение**: Одобренные для Kids Category
- **Критерии**: Issues прошедшие все проверки

#### 🚫 Needs Rework
- **Назначение**: Требует доработки для соответствия
- **Критерии**: Issues с проблемами соответствия

### 🏷️ Compliance-Specific Fields

#### COPPA Compliance Status
- **Type**: Single select
- **Options**:
  - ✅ Compliant
  - ⚠️ Needs Review
  - ❌ Non-Compliant
  - 🔍 Under Review

#### WHO Hearing Safety
- **Type**: Single select
- **Options**:
  - ✅ Safe Levels
  - ⚠️ Needs Limits
  - 🔊 Check Required
  - 📊 Measurements Needed

#### Accessibility Level
- **Type**: Single select  
- **Options**:
  - ♿ Full WCAG 2.1 AA
  - 🎯 Partial Support
  - 🚧 In Progress
  - ❌ Not Accessible

## 📊 Project Views и Filters

### 🔍 Полезные фильтры

#### Current Sprint View
```
assignee:@me 
label:"in-progress"
milestone:"v1.2.0"
```

#### Kids Category Issues
```
label:"kids-category" OR label:"coppa-compliance" OR label:"safety"
```

#### High Priority Bugs
```
label:"bug" 
label:"priority-high" OR label:"priority-critical"
is:open
```

#### Accessibility Tasks
```
label:"accessibility" OR label:"a11y"
sort:updated-desc
```

### 📈 Useful Reports

#### Sprint Burndown
- Track completion rate for current milestone
- Monitor velocity across sprints
- Identify bottlenecks

#### Kids Category Compliance Rate
- Percentage of features compliant
- Time to compliance for new features
- Security audit coverage

#### Release Readiness
- Features ready vs planned
- Compliance status per feature
- Testing completion rate

## 🤖 Automation Scripts

### 📱 Slack Integration

```javascript
// Webhook для уведомлений о релизах
const releaseNotification = {
  channel: "#babysounds-releases",
  message: "🚀 BabySounds v1.2.0 moved to Release Candidate!",
  attachments: [
    {
      color: "good",
      fields: [
        { title: "Features", value: "5 new features ready" },
        { title: "Bug Fixes", value: "12 issues resolved" },
        { title: "Compliance", value: "✅ All checks passed" }
      ]
    }
  ]
};
```

### 🔄 Auto-Milestone Assignment

```yaml
# Автоматическое назначение milestone на основе меток
- name: Auto-assign milestone
  uses: actions/github-script@v6
  with:
    script: |
      if (context.payload.label.name.includes('v1.2.0')) {
        await github.rest.issues.update({
          owner: context.repo.owner,
          repo: context.repo.repo,
          issue_number: context.issue.number,
          milestone: 5  // v1.2.0 milestone number
        });
      }
```

## 🎯 Best Practices

### 📋 Daily Workflow

1. **Morning Standup**: Review Development Board
2. **Sprint Planning**: Use Release Planning Board  
3. **Compliance Review**: Weekly Kids Category Board review
4. **Release Prep**: Move items through Release pipeline

### 🏷️ Labeling Strategy

- **Priority first**: Always add priority label
- **Category second**: Add technical category
- **Compliance last**: Add Kids Category compliance status

### 📊 Metrics to Track

- **Velocity**: Story points completed per week
- **Lead Time**: Time from idea to release
- **Compliance Rate**: % of features passing Kids Category review
- **Bug Escape Rate**: Bugs found in production vs testing

---

## 🆘 Support

**Questions about Projects setup?**
- 📚 Check GitHub Projects documentation
- 💬 Ask in `#babysounds-dev` Slack channel  
- 📧 Email: `devops@babysounds.com`

---

**Last Updated**: March 2024  
**Next Review**: June 2024 