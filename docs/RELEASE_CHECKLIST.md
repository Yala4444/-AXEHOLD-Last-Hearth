# AXEHOLD — Release Checklist

## Уже в проекте
- Portrait-first Godot project.
- Версионированное JSON-сохранение и миграция save v1 → v2.
- Ежедневный reset каравана и ежедневных заданий по системной дате.
- Главное меню, карта биомов, кузница, задания, трофеи, косметические облики и настройки.
- Core loop: день → добыча → склад → строительство → ночь → волна → босс.
- HUD: HP героя/Очагa, рюкзак, волна, XP, ресурсы, отдельная boss HP bar.
- Feedback: баннеры фазы, телеграф атаки босса, damage/block flash.
- Rewarded Ads stub: supply, revive, ×2 result.
- Analytics stub и события run_start / wave_start / run_end.
- Android/iOS export presets как стартовая конфигурация.
- App icon и wordmark в SVG.

## Перед закрытым тестом
1. Открыть в Godot 4.7.2 и выполнить editor parse/run.
2. Поставить Android/iOS export templates той же версии движка.
3. Прогнать 20–30 полных забегов и подстроить время дня, HP волн и стоимость построек.
4. Добавить реальные SFX/Music и нативную haptic-обвязку.
5. Заменить placeholder vector art на production sprites/animations.
6. Подключить crash reporting + analytics provider.
7. Проверить safe areas на устройствах с Dynamic Island/notch.
8. Подготовить consent/privacy flow перед реальным рекламным SDK.

## Перед store submission
- Реальный bundle/package id компании.
- Signing keys / Apple certificates.
- Privacy policy и disclosure по analytics/ads.
- Store screenshots, icon variants, promo art.
- Google Play: production export через AAB/Gradle и release keystore.
- iOS: Xcode archive/signing и App Store Connect metadata.
- Device QA минимум на нескольких aspect ratio и слабом Android-устройстве.
