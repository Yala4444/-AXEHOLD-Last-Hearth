# AXEHOLD — GitHub CI и запуск игры

Проект подготовлен для автоматической проверки в Godot 4.7.2 и сборки Web-версии через GitHub Actions.

## Что происходит после каждого push

1. GitHub запускает контейнер с Godot 4.7.2.
2. Godot импортирует проект и ресурсы.
3. `scripts/ci/smoke_test.gd` загружает и создаёт все ключевые сцены.
4. Главная сцена запускается headless на несколько кадров.
5. Godot экспортирует Web-сборку в `build/web/`.
6. Сборка прикладывается к Workflow Run как artifact `AXEHOLD-Web`.

Так мы получаем настоящий runtime/parse test проекта, а не только статическую проверку текста GDScript.

## Как подключить репозиторий

1. Создать на GitHub пустой репозиторий `AXEHOLD-Last-Hearth`.
2. Не добавлять README, `.gitignore` или license при создании — они уже находятся в проекте.
3. После этого ChatGPT сможет загрузить файлы проекта через подключённый GitHub-коннектор.
4. Первый push автоматически запустит workflow `AXEHOLD Godot CI`.

## Как получить Web-сборку

GitHub → Actions → `AXEHOLD Godot CI` → последний успешный run → Artifacts → `AXEHOLD-Web`.

После распаковки содержимое можно запустить через обычный HTTP-сервер. Web-export Godot использует WebAssembly/WebGL и не должен открываться напрямую как `file://`.

## Играбельная ссылка через GitHub Pages

Workflow уже умеет публиковать Web-build в GitHub Pages, но по умолчанию это выключено, чтобы не раскрыть проект случайно.

Чтобы включить:

1. Repository → Settings → Pages → Source → GitHub Actions.
2. Repository → Settings → Secrets and variables → Actions → Variables.
3. Создать repository variable `ENABLE_PAGES` со значением `true`.
4. Сделать новый push или вручную запустить workflow.

Если Pages доступен для выбранной видимости репозитория и тарифа GitHub, job `Deploy playable build to Pages` выдаст URL игры.

## Почему Web preset без threads

`variant/thread_support=false` выбран специально для простого playtest-хостинга. Так Web-build не требует обязательных COOP/COEP заголовков и проще запускается на Pages и других статических хостингах.

## Следующий этап

После первого зелёного CI:
- исправить любые реальные ошибки Godot из логов;
- добавить автоматическую Android debug-сборку;
- при необходимости подключить itch.io как закрытый playtest-канал;
- добавить игровые unit/integration tests для экономики и сохранений.
