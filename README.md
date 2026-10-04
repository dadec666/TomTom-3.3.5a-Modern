# TomTom (WoW 3.3.5a Modernized)

[English](#english) | [Русский](#русский)

---

## English

A modernized version of the **TomTom** navigation addon for World of Warcraft 3.3.5a (Wrath of the Lich King), rebuilt with modern UI standards, performance enhancements, and zero loss of backward compatibility.

### Key Features
* **Modern Retail UI:** Fully standalone settings frame (`/tomtom`) featuring a sleek Dragonflight/Retail aesthetic with modern switches (toggles), flat progress sliders with direct numeric input, and real-time color pickers.
* **Minimap Button:** Built-in `LibDBIcon-1.0` and `LibDataBroker-1.1` integration (Left-click for options, Right-click for batch import, freely draggable).
* **Batch Coordinate Import (`/ttpaste`):** Easily import multi-line waypoints directly from leveling guides and forum macros.
* **Performance Optimizations:** Distance string caching, zero-allocation table pooling, and throttled Crazy Arrow updates to eliminate garbage collection spikes and micro-stutters.
* **Full Localization:** Clean separation of strings with full `enUS` and `ruRU` support — no hardcoded text in UI logic.
* **100% Backward Compatibility:** Seamless drop-in replacement compatible with Questie, Carbonite, DBM, and ElvUI via standard TomTom API.

### Installation
1. Download or clone this repository.
2. Copy the **`TomTom`** folder (located inside this repository) directly into your game directory:  
   `World of Warcraft/Interface/AddOns/`
3. Path structure must be: `World of Warcraft/Interface/AddOns/TomTom/TomTom.toc`.
4. Launch the game or run `/reload` in chat.

---

## Русский

Модернизированная версия аддона **TomTom** для World of Warcraft 3.3.5a (Wrath of the Lich King), переработанная под стандарты современного интерфейса с оптимизацией производительности и сохранением полной обратной совместимости.

### Основные особенности
* **Современный Retail-интерфейс:** Полностью автономное окно конфигурации (`/tomtom`) в плоском темном стиле Retail/Dragonflight: стильные тумблеры (Switch), плоские слайдеры с возможностью ручного ввода точных значений с клавиатуры и удобные пикеры цвета.
* **Кнопка у миникарты:** Интеграция с библиотеками `LibDBIcon-1.0` и `LibDataBroker-1.1` (ЛКМ — настройки, ПКМ — окно пакетного импорта, свободное перетаскивание вокруг обода миникарты).
* **Пакетный импорт точек (`/ttpaste`):** Быстрая вставка списков координат из гайдов и макросов в один клик.
* **Оптимизация производительности:** Кэширование строк дистанции, переиспользование таблиц (pooling) и регулируемая частота обновления стрелки без лагов и спайков сборщика мусора (GC).
* **Чистая локализация:** Полная поддержка русской (`ruRU`) и английской (`enUS`) локализаций без жестко зашитых в коде фраз.
* **100% совместимость:** Полная совместимость со сторонними аддонами (Questie, Carbonite, DBM, ElvUI) через стандартные методы API TomTom.

### Установка
1. Скачайте репозиторий через кнопку **Code -> Download ZIP** или клонируйте его.
2. Скопируйте папку **`TomTom`** (находящуюся внутри репозитория) в каталог аддонов:  
   `World of Warcraft/Interface/AddOns/`
3. Итоговый путь должен выглядеть так: `World of Warcraft/Interface/AddOns/TomTom/TomTom.toc`.
4. Перезапустите игру или выполните `/reload` в игре.
