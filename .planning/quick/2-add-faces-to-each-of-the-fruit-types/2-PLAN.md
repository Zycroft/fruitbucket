---
phase: quick-2
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - scenes/fruit/fruit.tscn
  - scenes/fruit/fruit.gd
  - scenes/fruit/face_renderer.gd
  - scenes/ui/hud.tscn
  - scenes/ui/hud.gd
autonomous: true
must_haves:
  truths:
    - "Each of the 8 fruit types displays a unique face on it"
    - "Faces scale correctly with fruit size (tiny blueberry to large watermelon)"
    - "Faces appear in both the game bucket and the next-fruit HUD preview"
    - "Faces do not interfere with physics, merging, or any existing gameplay"
  artifacts:
    - path: "scenes/fruit/face_renderer.gd"
      provides: "Custom Node2D that draws cartoon face using _draw()"
    - path: "scenes/fruit/fruit.tscn"
      provides: "FaceRenderer child node added to fruit scene"
    - path: "scenes/fruit/fruit.gd"
      provides: "initialize() configures face on the FaceRenderer child"
  key_links:
    - from: "scenes/fruit/fruit.gd"
      to: "scenes/fruit/face_renderer.gd"
      via: "initialize() calls FaceRenderer.set_face(tier)"
      pattern: "FaceRenderer|set_face|face_renderer"
---

<objective>
Add unique cartoon faces to each of the 8 fruit types so every fruit has personality.

Purpose: Visual polish -- fruits currently render as colored circles with no character. Adding faces makes each fruit type visually distinct and the game more charming.
Output: FaceRenderer script, updated fruit scene and script, updated HUD preview.
</objective>

<execution_context>
@/home/zycroft/.claude/get-shit-done/workflows/execute-plan.md
@/home/zycroft/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@scenes/fruit/fruit.tscn
@scenes/fruit/fruit.gd
@resources/fruit_data/fruit_data.gd
@scenes/ui/hud.tscn
@scenes/ui/hud.gd
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create FaceRenderer and add to fruit scene</name>
  <files>scenes/fruit/face_renderer.gd, scenes/fruit/fruit.tscn, scenes/fruit/fruit.gd</files>
  <action>
Create `scenes/fruit/face_renderer.gd` -- a Node2D script that draws a cartoon face using `_draw()`. This avoids needing external texture assets and scales perfectly at any size.

**FaceRenderer design:**
- Extends Node2D with class_name FaceRenderer
- `var face_tier: int = 0` and `var face_radius: float = 15.0` -- set externally
- `func set_face(tier: int, radius: float) -> void:` -- stores values, calls `queue_redraw()`
- `func _draw() -> void:` -- draws face features relative to `face_radius`
- All face features drawn in BLACK with slight transparency (Color(0, 0, 0, 0.85))
- Face features scale proportionally to `face_radius` so they look correct at every fruit size

**Per-tier face expressions (8 unique faces):**
- Tier 0 (Blueberry, r=15): Tiny dot eyes, small "o" mouth (surprised/cute). Eyes: two filled circles at (-0.25r, -0.1r) and (0.25r, -0.1r), radius 0.08r. Mouth: small filled circle at (0, 0.2r), radius 0.06r.
- Tier 1 (Grape, r=20): Happy closed-eye smile. Eyes: two arcs (half-circles, opening downward) at y=-0.1r. Mouth: upward arc from (-0.25r, 0.15r) to (0.25r, 0.15r).
- Tier 2 (Cherry, r=27): Cheerful wide eyes, big grin. Eyes: filled circles radius 0.1r with small white highlight circles (0.04r) at upper-right of each eye. Mouth: wide upward arc from (-0.3r, 0.1r) to (0.3r, 0.1r).
- Tier 3 (Strawberry, r=35): Winking face. Left eye: filled circle 0.09r. Right eye: horizontal line (wink). Mouth: slight smirk arc, offset right.
- Tier 4 (Orange, r=44): Confident grin. Eyes: slightly oval (draw_arc wider than tall), with flat bottom (half-circle eyes like anime). Mouth: broad smile arc, thicker line width.
- Tier 5 (Apple, r=54): Cool/smug. Eyes: narrow horizontal ovals (squinting). Mouth: small smirk, one side raised.
- Tier 6 (Pear, r=66): Sleepy/content. Eyes: curved downward lines (droopy/relaxed). Mouth: gentle wavy smile.
- Tier 7 (Watermelon, r=80): Big happy face. Large round eyes with big highlights, wide open smile (filled arc/pie shape showing "teeth" as negative space -- draw a wide black arc for upper lip, a thin white rectangle gap, then lower arc).

**Drawing implementation notes:**
- Use `draw_circle()` for filled circles (eyes, pupils)
- Use `draw_arc()` for curved mouths and eye arcs. draw_arc params: center, radius, start_angle, end_angle, point_count, color, width.
- For line-based features use `draw_line()` with appropriate width (scale line width with radius: `maxf(1.0, face_radius * 0.04)`)
- All coordinates relative to (0, 0) since the Node2D will be at the fruit center
- Keep z_index default (same as parent) -- faces render on top because they're child nodes drawn after parent Sprite2D

**Update fruit.tscn:**
Add a Node2D child named "FaceRenderer" after Sprite2D, with the face_renderer.gd script attached:
```
[node name="FaceRenderer" type="Node2D" parent="."]
script = ExtResource("X_face")
```
Add the ext_resource for face_renderer.gd.

**Update fruit.gd initialize():**
After the existing sprite scaling code (line 43), add:
```gdscript
# Configure face renderer
$FaceRenderer.set_face(data.tier, data.radius)
```
This is all that's needed -- FaceRenderer handles all drawing internally.
  </action>
  <verify>
Run the game. Fruits should display unique faces on top of their colored circles. Each tier should have a different expression. Faces should be proportional to fruit size. All 8 tiers should be visually distinct.
Verify no errors in Godot console: look for any draw-related warnings.
Verify merging still works: merge two same-tier fruits and confirm the resulting fruit shows the correct next-tier face.
  </verify>
  <done>All 8 fruit types display unique cartoon faces drawn via _draw(). Faces scale with fruit radius. No gameplay regression.</done>
</task>

<task type="auto">
  <name>Task 2: Add face to next-fruit HUD preview</name>
  <files>scenes/ui/hud.tscn, scenes/ui/hud.gd</files>
  <action>
The NextFruitPreview in the HUD uses a bare Sprite2D to show the upcoming fruit. It needs a matching FaceRenderer so the preview also shows the face.

**Update hud.tscn:**
Add a FaceRenderer Node2D child to NextFruitPreview, positioned at the same spot as NextFruitSprite (position 50, 60):
```
[node name="NextFacRenderer" type="Node2D" parent="NextFruitPreview"]
position = Vector2(50, 60)
script = ExtResource("X_face")
```
Add ext_resource for face_renderer.gd.

**Update hud.gd update_next_fruit():**
After the existing sprite update code (around line 186), add face configuration:
```gdscript
# Update face preview -- use display radius matching the preview scale.
# The preview target size is 50px, so the "effective radius" for face drawing
# should be 25.0 (half of 50px display) so the face proportions match.
$NextFruitPreview/NextFaceRenderer.set_face(tier, 25.0)
```

This ensures the next-fruit preview shows the same face expression the fruit will have when dropped. The radius is fixed at 25.0 (half of the 50px preview size) so face features are appropriately sized for the preview regardless of the fruit's actual game radius.
  </action>
  <verify>
Run the game. The "NEXT" fruit preview in the top-right should show a face on the colored circle. Drop a fruit and confirm the preview updates to show the next fruit's face. Cycle through multiple drops to verify different tier faces appear correctly in the preview.
  </verify>
  <done>Next-fruit HUD preview shows the matching face for each fruit tier. Face updates correctly when the next fruit changes.</done>
</task>

</tasks>

<verification>
- Launch game and observe fruits dropping with faces
- Verify all 8 tiers have visually distinct expressions (merge up through tiers to see them all)
- Confirm next-fruit preview shows matching face
- Confirm faces scale proportionally (small face on blueberry, large face on watermelon)
- Confirm no physics/merge/overflow regressions
- Confirm no console errors or warnings
</verification>

<success_criteria>
All 8 fruit types display unique cartoon faces. Faces render in both the game bucket and HUD preview. No gameplay regressions. Faces scale with fruit size.
</success_criteria>

<output>
After completion, create `.planning/quick/2-add-faces-to-each-of-the-fruit-types/2-SUMMARY.md`
</output>
