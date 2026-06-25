# AceStep-Portable-Scripts

Portable Windows scripts and Russian localization for [ACE-Step-1.5](https://github.com/ace-step/ACE-Step-1.5).

## 🚀 Быстрый старт

1. Склонируйте этот репозиторий в `D:\AceStep-1.5`
2. Запустите `Start.bat`
3. Выберите "Установка / Обновление компонентов" → "Установить все"
4. После установки выберите "Запуск AceStep-1.5"

## 📁 Структура

```text
D:\AceStep-1.5
├── Start.bat              # Главное меню
├── scripts\               # Скрипты установки и запуска
├── repo\                  # Клон форка ACE-Step-1.5
├── python-3.11.9\         # Portable Python
├── models\                # Модели (base, xl-base, xl-sft, xl-turbo)
├── data\                  # Изоляция AppData, TEMP, HOME
└── output\                # Сгенерированные треки


## 🎵 Модели

| Модель | Размер | VRAM | Качество |
|--------|--------|------|----------|
| base | ~8GB | 8GB+ | Хорошее |
| xl-base | ~20GB | 20GB+ | Отличное |
| xl-sft | ~20GB | 20GB+ | Fine-tuned |
| xl-turbo | ~20GB | 20GB+ | Очень быстрое |

## ⚙️ Требования

- Windows 10/11 x64
- NVIDIA GPU с поддержкой CUDA (рекомендуется RTX 3090/4090/5090)
- 32GB+ VRAM для XL моделей
- Интернет для первой установки

## 📝 Лицензия

MIT License — см. [LICENSE](LICENSE)