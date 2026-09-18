class_name VisualSystem
extends RefCounted

const BG := Color("091014")
const BG_SOFT := Color("0d1519")
const SURFACE := Color("111b20")
const SURFACE_2 := Color("162229")
const SURFACE_3 := Color("1b2a31")
const BORDER := Color("2f3f45")
const BORDER_SOFT := Color(0.25, 0.32, 0.34, 0.45)
const TEXT := Color("f2eadb")
const TEXT_SOFT := Color("aeb9b9")
const TEXT_MUTED := Color("778487")
const GOLD := Color("d5a652")
const GOLD_BRIGHT := Color("e4c276")
const GREEN := Color("7eaa86")
const RED := Color("d46a61")
const BLUE := Color("7fa8bd")
const VIOLET := Color("9a7ab2")
const COIN := Color("d9ad57")
const SHARD := Color("d77a61")

static func panel(fill: Color = SURFACE, border: Color = BORDER_SOFT, radius: int = 5, margin: int = 10, width: int = 1) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.content_margin_left = margin
    style.content_margin_right = margin
    style.content_margin_top = margin
    style.content_margin_bottom = margin
    return style

static func button(primary: bool = false, pressed: bool = false) -> StyleBoxFlat:
    var fill: Color = GOLD if primary else SURFACE_2
    var border: Color = GOLD_BRIGHT if primary else BORDER
    if pressed:
        fill = fill.darkened(0.12)
        border = border.lightened(0.03)
    return panel(fill, border, 5, 9, 1)

static func chip(accent: Color) -> StyleBoxFlat:
    return panel(Color(accent, 0.10), Color(accent, 0.34), 5, 6, 1)
