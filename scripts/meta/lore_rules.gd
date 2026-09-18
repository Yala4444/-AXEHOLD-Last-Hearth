class_name LoreRules
extends RefCounted

const CHAPTER_TITLE := "ГЛАВА I · ПОГАСАНИЕ"
const CHAPTER_PROMISE := "Последний Очаг ещё горит. Остальные давно молчат."
const CHAPTER_TWO_TITLE := "ГЛАВА II · ДОРОГА К ОГНЯМ"
const CHAPTER_TWO_PROMISE := "Хранители были ключами. Теперь нужно найти Очаги, которые они когда-то защищали."

const CHAPTER_ONE_FINALE := "Три реликвии складываются в один знак — карту старой сети Очагов. На обратной стороне выжжено предупреждение: «Один огонь не удержит ночь». Странник больше не должен ждать у последнего костра. Нужно идти туда, где свет погас первым."
const CHAPTER_TWO_OBJECTIVE := "Подготовить дальнюю экспедицию и найти первый внешний Очаг за пределами известных трёх регионов."

const BIOME_TAGLINES: Array[String] = [
    "Там, где дорога исчезла под корнями.",
    "Холод сохранил то, что лес успел забыть.",
    "Под пеплом всё ещё дышит старый огонь."
]

const BIOME_LORE: Array[String] = [
    "Когда-то через эту чащу шли караваны к соседнему Очагу. Теперь тропы заросли, а Лесной Хранитель не подпускает никого к руинам.",
    "Морозная лощина застыла в ночь Погасания. В ледяных развалинах остались следы тех, кто пытался удержать свет до последнего.",
    "Здесь стояли кузницы старого мира. После Погасания земля раскололась, а Пепельный Тиран превратил остатки огня в оружие."
]

const RELIC_CLUES: Array[String] = [
    "Реликвия хранит знак старого Очага. Хранитель когда-то защищал его, а не уничтожал.",
    "Внутри льда виден тот же знак. Похоже, все Хранители служили одной сети Очагов.",
    "На реликвии выжжены слова: «Один огонь не удержит ночь». Последний Очаг нельзя защищать вечно."
]

static func biome_tagline(index: int) -> String:
    return BIOME_TAGLINES[clampi(index, 0, BIOME_TAGLINES.size() - 1)]

static func biome_lore(index: int) -> String:
    return BIOME_LORE[clampi(index, 0, BIOME_LORE.size() - 1)]

static func relic_clue(index: int) -> String:
    return RELIC_CLUES[clampi(index, 0, RELIC_CLUES.size() - 1)]

static func camp_whisper(relic_count: int) -> String:
    match relic_count:
        0:
            return "За границей света что-то ждёт. Первый Хранитель знает дорогу дальше."
        1:
            return "Первая реликвия изменила пламя. Хранители явно не всегда были врагами."
        2:
            return "Две реликвии откликаются друг на друга. Старые Очаги были связаны."
        _:
            return "Один огонь не удержит ночь. Теперь Странник знает, что нужно искать дальше."

static func chapter_title(chapter_one_complete: bool) -> String:
    return CHAPTER_TWO_TITLE if chapter_one_complete else CHAPTER_TITLE

static func chapter_promise(chapter_one_complete: bool) -> String:
    return CHAPTER_TWO_PROMISE if chapter_one_complete else CHAPTER_PROMISE

static func chronicle_relic_progress(relics: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for i: int in range(3):
        var found: bool = i < relics.size() and bool(relics[i])
        result.append({
            "index":i,
            "found":found,
            "name":WeaponRules.relic_name(i),
            "clue":relic_clue(i) if found else "След реликвии ещё скрыт во Тьме."
        })
    return result
