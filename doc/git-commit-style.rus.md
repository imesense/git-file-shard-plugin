---
title: git commit style
version: v0.1.0
---

<!-- markdownlint-disable MD025 -->

# Стиль фиксаций Git

<!-- markdownlint-enable MD025 -->

[English](./git-commit-style.md) | Русский

В документе определены стандарты для написания сообщений фиксации для ведения чёткой, последовательной и содержательной истории изменений проекта.

## Назначение

Описываемый формат собщении об изменений необходим для:

- Удобства чтения, понимания и поиска изменений.
- Выстраивания сотрудничества между членами команды.
- Поддержать автоматическое формирование списка изменений.
- Упростить отслеживание изменений и отладку проблем.

## Структура сообщения фиксации

### 1. Заголовок

- __Формат__: `<Глагол> <существительное>`
- __Заглавная__ первая буква.
- __Максимальная длина__: 72 символа.
- __Повелительное наклонение__ (например, `Fix`/`Add`/`Remove` и не `Fixed`/`Added`).
- __Без префиксов__ вида `[Fix]` или `[Feature]`.

Примеры правильных коммитов:

- `Fix memory leak in data parser`
- `Add user profile validation`

Пример коммитов, которые не допускаются к сливанию:

- `Fixed bug` - слишком расплывчато
- `[Feature] New login screen` - префикс не разрешён

### 2. Тело (опционально, для комплексных изменений)

- Объяснить __что изменилось__ и __почему__.
- Уместить текст в __72 символа__ на строку.
- Использовать маркированный список для нескольких изменений (при схлопывании).

Правильный пример:

```text
Optimize database query performance

- Replace nested queries with JOINs
- Add indexes on frequently filtered columns
- Reduces response time by ~40% in benchmarks
```

### 3. Подвал (опционально, для метаданных)

- Ссылки на проблемы (например, `Closes #123`).
- Соавторы (например, `Co-authored-by: Name <email>`).

## Распространённые ошибки

- Использование тегов или метаданных:
  - Не правильно: `[BUGFIX] Fix null pointer exception`
  - Правильно: `Fix null pointer exception in parser`

- Неправильная форма глагола:
  - Не правильно: `Fixed broken tests`
  - Правильно: `Fix broken unit tests`

- Глаголы без повелительного наклонения:
  - Не правильно: `Fixes rendering bug`
  - Правильно: `Fix rendering bug`

- Неопределённые сообщения:
  - Не правильно: `Make it better`
  - Правильно: `Improve image loading performance`

- Неправильное положение существительных:
  - Не правильно: `Add support compression`
  - Правильно: `Add compression support`

## Примеры сообщений о фиксации

### Однострочные сообщения

```text
Fix race condition in thread manager
```

```text
Refactor configuration parser
```

```text
Update dependencies to latest versions
```

```text
Remove legacy compatibility layer
```

### Многострочные сообщения

```text
Improve error handling in network module

Added comprehensive error checking for socket operations and implemented
proper cleanup routines for failed connections. The changes prevent
memory leaks during network failures.
```

```text
Add performance benchmarks for core functions

Implemented a new benchmarking suite that measures execution time of
critical path operations. Includes tests for various input sizes and
edge cases.
```
