# Eidolon Circuit Art Asset Pack

This folder contains concept and production-direction art for `Eidolon Circuit / 星魂回环`.

## Preview

- `art_asset_pack_contact_sheet_v3.png` - full overview of the current art pack, with assembly parts first.
- `art_asset_pack_contact_sheet_v2.png` - previous overview before the assembly-parts pass.
- `generated_contact_sheet_latest.png` - raw image2 output contact sheet from the current batch.

## Key Art Backgrounds

These are background/key-art images. They are not captured gameplay.

- `main_menu_promo_concept_a.png` - recommended main menu key art background.
- `main_menu_promo_concept_b.png` - alternate promotional main menu key art.
- `battle_arena_key_art_v1.png` - Mobius battle arena background.
- `unit_editor_workshop_key_art_v1.png` - modular assembly/editor workshop background.
- `saved_units_hangar_key_art_v1.png` - saved units / roster hangar background.
- `loading_transition_key_art_v1.png` - loading / transition resource-cycle background.

## Screen Mockups

These are complete target mockups with local UI/HUD composited over the backgrounds.
Use them as visual targets when implementing or refining Godot screens.

- `screens/combat_screen_mockup_v1.png` - battle HUD target.
- `screens/unit_editor_screen_mockup_v1.png` - unit editor target.
- `screens/unit_editor_parts_first_screen_mockup_v1.png` - revised unit editor target emphasizing part inventory, socket graph assembly, and selected-part inspection.
- `screens/saved_units_screen_mockup_v1.png` - saved units / roster target.
- `screens/loading_screen_mockup_v1.png` - loading screen target.
- `screens/mode_select_screen_mockup_v1.png` - mode select target.
- `screens/settings_screen_mockup_v1.png` - settings screen target.
- `screens/screen_mockups_contact_sheet_v1.png` - four-screen overview.

## Unit Art

Whole-unit portraits are result previews/card art. The hero should be assembled from parts first, then rendered as a complete unit.

- `units/starcore_vanguard_portrait_v1.png` - hero unit portrait.
- `units/aegis_guardian_portrait_v1.png` - shield guardian portrait.
- `units/razor_scout_portrait_v1.png` - fast scout portrait.
- `units/source_artillery_portrait_v1.png` - artillery support portrait.
- `units/unit_portraits_contact_sheet_v1.png` - raw portrait overview.
- `units/unit_card_sheet_v1.png` - card-style presentation sheet.

## Assembly Parts

These are the optimized source assets for hero construction. Use them before whole-unit art.

- `parts/hero_assembly_parts_concept_sheet_image2_v1.png` - image2 concept sheet for high-detail modular component direction.
- `parts/hero_assembly_parts_atlas_v1.png` - transparent 4x4 assembly part atlas, 256 px cells, 1024x1024 total.
- `parts/hero_assembly_parts_atlas_v1.json` - atlas slicing metadata, including `id`, `slot`, connector count, and cell rect.
- `parts/hero_assembly_parts_atlas_preview_v1.png` - dark-background preview with labels and socket counts.
- `parts/hero_assembly_exploded_view_v2.png` - assembly relationship diagram showing torso sockets, joints, limbs, terminals, boosters, and software modules.
- `parts/individual/` - standalone production-direction part files: 16 transparent 512x512 PNG sprites plus per-part preview cards.
- `parts/individual/individual_parts_manifest_v1.json` - single-part manifest with file paths, slot type, connector count, and source atlas rect.
- `parts/individual/hero_assembly_individual_parts_contact_sheet_v1.png` - overview sheet for reviewing every standalone assembly part.
- `parts/image2_individual/` - image2-generated standalone part files: 16 transparent 1024x1024 PNG sprites plus per-part preview cards.
- `parts/image2_individual/sources/` - original image2 chroma-key source outputs, kept for audit and re-keying.
- `parts/image2_individual/image2_individual_parts_manifest_v1.json` - image2 single-part manifest with source, transparent sprite, preview card, slot, and connector metadata.
- `parts/image2_individual/hero_assembly_image2_individual_parts_contact_sheet_v1.png` - overview sheet for reviewing the image2 standalone part set.
- `parts/image2_individual/runtime_image2_component_art_probe_v1.png` - Godot runtime preview rendered through `ComponentArtView`.
- `parts/image2_individual/runtime_editor_image2_component_preview_v1.png` - Godot runtime editor screenshot showing image2 part art in the unit editor UI.

## UI Atlases

These PNGs are transparent and intended to be sliced or used as references for Godot UI skinning.

- `ui/resource_status_icon_atlas_v1.png` - 4x2 resource/status icons.
- `ui/part_category_icon_atlas_v1.png` - 4x2 part category icons.
- `ui/ui_skin_panel_atlas_v1.png` - panel, button, slider, toggle, tab, separator samples.
- `ui/*_preview_v1.png` - dark-background previews for inspection.

## VFX Atlas

- `vfx/combat_vfx_style_atlas_v1.png` - transparent 4x4 VFX style atlas: slash, bullet, laser, shield hit, explosion, heat, code, ether, lock, boost, barrier, blind zone, pickup, transfer, salvo marker, impact.
- `vfx/combat_vfx_style_atlas_preview_v1.png` - dark-background preview.

## Integration Notes

- Use key-art backgrounds as low-alpha or masked backdrops; keep interactive UI and readable text rendered by Godot.
- Use screen mockups as targets, not source assets for UI text.
- Prefer transparent atlases for icons/VFX so they can be recolored, animated, or sliced in-engine.
- Keep image2 outputs text-free when generating future assets; add Chinese/English labels in Godot or via deterministic local composition.
