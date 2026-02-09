# Phase 5: Card System Infrastructure - Research

**Researched:** 2026-02-08
**Domain:** Resource-based card data model, card shop UI, coin economy, rarity-weighted selection, per-run lifecycle management (Godot 4.5 / GDScript)
**Confidence:** HIGH

## Summary

Phase 5 builds the entire card system infrastructure: the data model (CardData resources), the runtime manager (CardManager autoload), the HUD card slots, the shop overlay, the starter card pick screen, and the coin/rarity economics. This is the largest phase so far -- it touches every layer of the architecture. The good news is that the existing codebase is exceptionally well-prepared: ScoreManager already tracks coins and emits `coins_awarded` and `score_threshold_reached` signals, GameManager already has a state machine and `reset_game()`, the pause-overlay pattern is proven (PauseMenu on CanvasLayer layer 10 with PROCESS_MODE_ALWAYS), and the FruitData Resource pattern provides the exact template for CardData resources.

The core architectural decision is to separate card DATA (what a card is) from card EFFECTS (what a card does). Phase 5 handles only the data/infrastructure side -- CardData resources define name, description, rarity, cost, and icon. Card effects (the actual gameplay modifications) are deferred to Phases 6 and 7. This means Phase 5 cards are "inert" -- they display in slots, can be bought/sold, and have descriptions, but their effects do not fire until the effect scripts are implemented. This separation is critical: it lets us build and test the entire card lifecycle (pick, display, buy, sell, reset) without the complexity of effect application.

The shop uses the same tree-pause pattern as the existing PauseMenu: a CanvasLayer with `process_mode = ALWAYS` that becomes visible when `score_threshold_reached` fires, pausing the game via a new `SHOPPING` state in GameManager. The starter card pick at run start uses the same pattern -- a CanvasLayer overlay that appears before the first drop, letting the player pick from 3 random cards.

**Primary recommendation:** Create a CardData Resource class mirroring FruitData, a CardManager autoload for inventory/economy, a SHOPPING GameState that pauses the tree, and shop/starter-pick CanvasLayer overlays following the proven PauseMenu pattern.

## Standard Stack

### Core

| System | Version | Purpose | Why Standard |
|--------|---------|---------|--------------|
| Custom Resource (CardData) | Godot 4.5 | Define card properties as .tres files | Proven pattern in this project (FruitData). Data-driven, editor-friendly, serializable. |
| Autoload (CardManager) | Godot 4.5 | Runtime card inventory, shop logic, coin tracking | Autoloads persist across scene reloads, same as GameManager/EventBus. Card state needs to survive scene transitions. |
| CanvasLayer + process_mode ALWAYS | Godot 4.5 | Shop and starter-pick overlays | Proven pattern (PauseMenu). Overlays on layer 10-11 that function while tree is paused. |
| GameManager.GameState enum | Godot 4.5 | SHOPPING state for shop pause | Extend existing enum. Same pattern as PAUSED state. |
| EventBus signals | Godot 4.5 | card_purchased, card_sold, shop_opened, shop_closed, starter_pick_completed | Existing decoupling pattern. HUD listens to card signals just like it listens to score signals. |

### Supporting

| System | Version | Purpose | When to Use |
|--------|---------|---------|-------------|
| HBoxContainer | Godot 4.5 | Card slot layout in HUD | 3 card slots laid out horizontally. Standard Control layout. |
| VBoxContainer / GridContainer | Godot 4.5 | Shop card offer layout | 3-4 card offers arranged vertically or in a grid. |
| Tween | Godot 4.5 | Card slot animations, shop transitions | Entrance/exit animations for shop overlay. Pulse on card purchase. |
| randf() + cumulative weights | Godot 4.5 | Weighted random rarity selection | Select card rarity based on probability weights. No plugin needed. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CardManager autoload | Scene-local CardManager node | Autoload persists across reloads; scene-local would reset. We need persistence within a run (scene might reload). But GameManager.reset_game() handles run-end cleanup. Autoload is simpler. |
| Separate CardData Resource files | JSON card database | Resources integrate with Godot editor, have type safety, and match FruitData pattern. JSON would require parsing/validation. |
| Manual weighted random | WeightedChoice plugin | Our rarity system has only 3 tiers -- a 10-line function is simpler than a plugin dependency. |
| SHOPPING state that pauses tree | Manual input blocking without pause | Tree pause freezes physics (fruits stay in place during shop). Manual blocking risks physics drift, input leaks, and doesn't match the PAUSED pattern already working. |

## Architecture Patterns

### Recommended Project Structure

```
resources/
  card_data/
    card_data.gd              # CardData Resource class (class_name CardData)
    bouncy_berry.tres          # Common physics card
    heavy_hitter.tres          # Uncommon physics card
    wild_fruit.tres            # Rare merge card
    quick_fuse.tres            # Common score card
    fruit_frenzy.tres          # Common score card
    big_game_hunter.tres       # Uncommon score card
    golden_touch.tres          # Common economy card
    lucky_break.tres           # Uncommon economy card
    cherry_bomb.tres           # Common physics card
    pineapple_express.tres     # Uncommon triggered card
scripts/
  autoloads/
    card_manager.gd            # NEW: Card inventory, shop logic, rarity selection
    event_bus.gd               # MODIFIED: Add card signals
    game_manager.gd            # MODIFIED: Add SHOPPING state, card reset
scenes/
  ui/
    card_shop.tscn             # NEW: Shop overlay (CanvasLayer, layer 11)
    card_shop.gd               # NEW: Shop logic, buy/sell/skip
    starter_pick.tscn          # NEW: Run-start card pick overlay
    starter_pick.gd            # NEW: Pick 1 of 3 free cards
    card_slot_display.tscn     # NEW: Reusable card slot UI component
    card_slot_display.gd       # NEW: Renders a single card (name, desc, rarity border)
    hud.tscn                   # MODIFIED: Add 3 card slots, update coin display
    hud.gd                     # MODIFIED: Listen to card signals, update slots
  game/
    game.tscn                  # MODIFIED: Add CardShop and StarterPick nodes
    game.gd                    # MODIFIED: Connect threshold signal, show shop/pick
```

### Pattern 1: CardData Resource (Data-Driven Card Definition)

**What:** Define each card as a .tres resource using a custom CardData class. Mirrors the FruitData pattern exactly. Card effects are referenced by ID string, not by script -- effect implementation is Phase 6/7.

**When to use:** For every card definition. Never hardcode card properties in scripts.

**Example:**
```gdscript
# resources/card_data/card_data.gd
class_name CardData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE }

## Unique identifier for this card (used by effect system in Phase 6/7).
@export var card_id: String = ""

## Display name shown in HUD and shop.
@export var card_name: String = ""

## Effect description shown on the card face.
@export var description: String = ""

## Rarity tier affecting shop price and appearance frequency.
@export var rarity: Rarity = Rarity.COMMON

## Base price in coins (before shop-level inflation).
@export var base_price: int = 10

## Card icon/art (placeholder until art phase).
@export var icon: Texture2D
```

**Corresponding .tres file (bouncy_berry.tres):**
```tres
[gd_resource type="Resource" script_class="CardData" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/card_data/card_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
card_id = "bouncy_berry"
card_name = "Bouncy Berry"
description = "Small fruits (tier 1-3) bounce 50% higher on impact"
rarity = 0
base_price = 8
```

### Pattern 2: CardManager Autoload (Inventory + Economy + Shop Logic)

**What:** A single autoload that owns the active card array (max 3 slots), handles card purchasing/selling, generates shop offers based on rarity weights and shop level, and resets all card state between runs.

**When to use:** For all card inventory and economy operations. No other system should directly modify card state.

**Example:**
```gdscript
# scripts/autoloads/card_manager.gd
extends Node

## Maximum number of active card slots.
const MAX_CARD_SLOTS: int = 3

## Cards currently in the player's slots (null = empty slot).
var active_cards: Array = []  # Array of CardData or null

## All available card definitions loaded from resources.
var _card_pool: Array[CardData] = []

## Number of shops opened this run (affects pricing and rarity).
var _shop_level: int = 0

## Rarity weights per shop level: [Common, Uncommon, Rare]
## Later shops offer more rare cards.
const RARITY_WEIGHTS: Array = [
    [0.70, 0.25, 0.05],  # Shop 1 (score 500)
    [0.55, 0.35, 0.10],  # Shop 2 (score 1500)
    [0.40, 0.40, 0.20],  # Shop 3 (score 3500)
    [0.25, 0.40, 0.35],  # Shop 4 (score 7000)
]

## Price multiplier per shop level (prices increase as run progresses).
const PRICE_MULTIPLIERS: Array[float] = [1.0, 1.25, 1.5, 2.0]

func _ready() -> void:
    _load_card_pool()
    reset()

func reset() -> void:
    active_cards.clear()
    for i in MAX_CARD_SLOTS:
        active_cards.append(null)
    _shop_level = 0

func has_empty_slot() -> bool:
    return active_cards.has(null)

func add_card(card: CardData) -> int:
    ## Add card to first empty slot. Returns slot index, or -1 if full.
    for i in active_cards.size():
        if active_cards[i] == null:
            active_cards[i] = card
            return i
    return -1

func remove_card(slot_index: int) -> CardData:
    ## Remove and return card from slot. Returns null if slot was empty.
    if slot_index < 0 or slot_index >= active_cards.size():
        return null
    var card: CardData = active_cards[slot_index]
    active_cards[slot_index] = null
    return card

func get_sell_price(card: CardData) -> int:
    ## Sell price is 50% of purchase price (which includes inflation).
    return int(card.base_price * _get_price_multiplier() * 0.5)

func generate_shop_offers(count: int = 3) -> Array[CardData]:
    ## Generate shop card offers based on current shop level.
    var offers: Array[CardData] = []
    var weights: Array = RARITY_WEIGHTS[mini(_shop_level, RARITY_WEIGHTS.size() - 1)]
    for i in count:
        var rarity: int = _pick_weighted_rarity(weights)
        var card: CardData = _pick_random_card_of_rarity(rarity)
        if card:
            offers.append(card)
    return offers

func _pick_weighted_rarity(weights: Array) -> int:
    ## Weighted random selection. weights = [common_weight, uncommon_weight, rare_weight]
    var roll: float = randf()
    var cumulative: float = 0.0
    for i in weights.size():
        cumulative += weights[i]
        if roll <= cumulative:
            return i
    return 0  # Fallback to common
```

### Pattern 3: SHOPPING State (Tree Pause for Shop)

**What:** Add a SHOPPING state to GameManager's enum. When score_threshold_reached fires, transition to SHOPPING, which pauses the tree exactly like PAUSED. The shop CanvasLayer has process_mode ALWAYS so it functions during the pause.

**When to use:** Every time a score threshold is crossed.

**Example:**
```gdscript
# game_manager.gd additions
enum GameState {
    READY,
    DROPPING,
    WAITING,
    PAUSED,
    SHOPPING,     # NEW: Card shop is open, tree paused
    PICKING,      # NEW: Starter card pick at run start
    GAME_OVER,
}

func change_state(new_state: GameState) -> void:
    if current_state == new_state:
        return
    if new_state == GameState.PAUSED:
        _previous_state = current_state
    current_state = new_state
    EventBus.game_state_changed.emit(new_state)
    # Pause tree for PAUSED, SHOPPING, and PICKING states
    match new_state:
        GameState.PAUSED, GameState.SHOPPING, GameState.PICKING:
            get_tree().paused = true
        _:
            get_tree().paused = false

func reset_game() -> void:
    get_tree().paused = false
    _previous_state = GameState.READY
    score = 0
    coins = 0
    CardManager.reset()  # NEW: Reset card state
    change_state(GameState.READY)
```

### Pattern 4: Shop Overlay (CanvasLayer with ALWAYS)

**What:** The card shop is a CanvasLayer on layer 11 (above HUD on layer 1, above PauseMenu on layer 10) with process_mode ALWAYS. It shows 3-4 card offers, the player's current cards (with sell buttons), and a skip button.

**When to use:** When score_threshold_reached fires and game enters SHOPPING state.

**Example structure:**
```
CardShop (CanvasLayer) [layer = 11, process_mode = ALWAYS]
  Overlay (ColorRect) [full rect, Color(0, 0, 0, 0.6), mouse_filter = STOP]
    ShopContainer (VBoxContainer) [centered]
      TitleLabel (Label) ["CARD SHOP"]
      CoinLabel (Label) ["Coins: 42"]
      OffersContainer (HBoxContainer or VBoxContainer)
        [CardOffer instances x3-4]
      Divider (HSeparator)
      YourCardsLabel (Label) ["Your Cards"]
      SlotsContainer (HBoxContainer)
        [CardSlotDisplay instances x3]
      SkipButton (Button) ["Skip"]
```

### Pattern 5: Starter Pick Overlay

**What:** Before the first drop, a CanvasLayer overlay shows 3 random cards. Player picks one for free. This introduces the card system immediately and mirrors the shop UI pattern.

**When to use:** At run start, before DROPPING state.

**Example flow:**
```gdscript
# game.gd modified _ready()
func _ready() -> void:
    GameManager.change_state(GameManager.GameState.PICKING)
    # StarterPick overlay shows 3 random cards
    # Player picks one -> card added to slot
    # -> GameManager.change_state(GameManager.GameState.DROPPING)
```

### Pattern 6: Reusable Card Slot Display Component

**What:** A single reusable scene (card_slot_display.tscn) that renders one card: name, description, rarity-colored border, and optional price tag. Used in both the HUD (showing active cards) and the shop (showing offers).

**When to use:** Everywhere a card is displayed.

**Example:**
```gdscript
# scenes/ui/card_slot_display.gd
extends PanelContainer

## Rarity-to-color mapping for card borders.
const RARITY_COLORS: Dictionary = {
    CardData.Rarity.COMMON: Color(0.7, 0.7, 0.7),     # Grey
    CardData.Rarity.UNCOMMON: Color(0.2, 0.7, 0.3),    # Green
    CardData.Rarity.RARE: Color(0.8, 0.6, 0.1),        # Gold
}

func display_card(card: CardData) -> void:
    $CardName.text = card.card_name
    $Description.text = card.description
    # Set border color based on rarity
    var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
    style.border_color = RARITY_COLORS[card.rarity]
    add_theme_stylebox_override("panel", style)

func display_empty() -> void:
    $CardName.text = "Empty"
    $Description.text = ""
```

### Anti-Patterns to Avoid

- **CardManager as a scene-local node:** Cards must survive within a run but reset between runs. A scene-local node resets on reload_current_scene(), which is correct for between-run reset, BUT during a run the scene should not reload. However, since restart triggers reload, the autoload pattern with manual reset_game() is safer and consistent with GameManager.

- **Cards as nodes in the scene tree:** Cards are data, not behavior (in Phase 5). Storing them as Resources in an array is correct. Nodes would add unnecessary scene tree overhead and lifecycle complexity.

- **Hardcoding card definitions in CardManager:** Every card should be a .tres file. CardManager loads them with ResourceLoader. This matches FruitData pattern and allows easy card additions without code changes.

- **Blocking input manually instead of pausing tree:** The SHOPPING state must pause the tree so physics freezes. Fruits should not drift or settle while the shop is open. Manual input blocking misses physics updates.

- **Modifying ScoreManager's coin system:** ScoreManager already awards coins via COIN_THRESHOLD (100 score = 1 coin). Phase 5 should use the EXISTING coin system, not replace it. The `GameManager.coins` variable is the source of truth. CardManager reads/writes `GameManager.coins` for purchases.

- **Making shop appear on a separate scene:** The shop must overlay the game (player sees their frozen fruits behind it). A separate scene would lose the game context. CanvasLayer overlay is the correct pattern.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Weighted random rarity | Complex probability distribution system | Simple cumulative weight function (10 lines) | Only 3 rarity tiers. A loop over cumulative weights is trivially correct and debuggable. |
| Card display styling | Custom drawing with _draw() | PanelContainer with StyleBoxFlat | Standard Godot UI. StyleBoxFlat supports border_color, corner_radius, bg_color. Rarity colors via stylebox override. |
| Shop overlay blocking | Manual input interception | CanvasLayer + tree pause | Proven pattern (PauseMenu). Tree pause freezes physics atomically. ColorRect with mouse_filter=STOP blocks click-through. |
| Card inventory management | Custom data structure | Simple Array of size 3 (null = empty) | 3 slots is trivial. Array index = slot index. null means empty. No need for a custom container class. |
| Price inflation | Complex economy formula | Lookup table (PRICE_MULTIPLIERS array) | 4 shop levels = 4 multiplier values. A lookup table is more readable and tunable than a formula. |
| Run reset | Per-field manual cleanup | CardManager.reset() called from GameManager.reset_game() | Single reset function clears all card state. GameManager already calls reset_game() on restart. |

**Key insight:** Phase 5 is mostly UI and data management -- domains where Godot's built-in Control nodes, Resources, and signals excel. The complexity is in getting the lifecycle right (pick -> play -> shop -> play -> shop -> game over -> reset), not in individual technical challenges.

## Common Pitfalls

### Pitfall 1: Card State Not Resetting Between Runs

**What goes wrong:** Player restarts via PauseMenu or game over, but cards from the previous run remain in slots, coins carry over, or shop level does not reset.

**Why it happens:** CardManager is an autoload. Autoloads persist across `reload_current_scene()`. If `CardManager.reset()` is not called in `GameManager.reset_game()`, card state leaks between runs.

**How to avoid:** Call `CardManager.reset()` inside `GameManager.reset_game()`. The existing `reset_game()` already resets score and coins. Add card reset to the same function. Test restart flow: play -> buy cards -> restart -> verify slots are empty and coins are 0.

**Warning signs:** Cards from a previous run appear in the HUD after restart. Coin count does not reset to 0.

### Pitfall 2: Shop Overlay Not Blocking Game Input

**What goes wrong:** Player can still move/drop fruits behind the shop overlay, or click-through the shop to interact with game elements.

**Why it happens:** Either the tree is not paused (so DropController processes input), or the overlay ColorRect has `mouse_filter = IGNORE` (so clicks pass through).

**How to avoid:** The SHOPPING state must call `get_tree().paused = true`. The shop overlay must have a full-rect ColorRect with `mouse_filter = STOP` as the first child, blocking all input from reaching nodes behind it. This is the exact pattern PauseMenu uses (Overlay ColorRect with mouse_filter=0 in pause_menu.tscn).

**Warning signs:** Fruits drop or move while the shop is visible. Click sounds play from game elements behind the shop.

### Pitfall 3: Score Threshold Fires Multiple Times

**What goes wrong:** A single merge crosses a score threshold, triggering `score_threshold_reached` correctly. But the shop takes time to open, and during that time another merge fires, crossing the same threshold again (or the next one), causing multiple shops to queue up or the signal to fire redundantly.

**Why it happens:** ScoreManager uses a `_thresholds_reached` counter to track which thresholds have fired, but if multiple merges happen in the same physics frame (chain reactions), the counter advances correctly in the `while` loop. The real risk is: two thresholds are crossed in the same chain, causing two `score_threshold_reached` signals before the first shop can open.

**How to avoid:** ScoreManager already handles this correctly with its `while` loop -- it emits one signal per threshold crossed. The game.gd listener should only open the shop for the FIRST signal received while in DROPPING/WAITING state. If the game is already in SHOPPING state when a second threshold signal arrives, queue it for after the current shop closes. Alternatively, since the tree pauses when the shop opens, no further merges can fire during the shop -- this is self-regulating.

**Warning signs:** Two shops open in rapid succession. Shop opens but immediately closes and reopens.

### Pitfall 4: Starter Pick Not Blocking Gameplay

**What goes wrong:** The starter card pick overlay appears but the player can also interact with the game behind it -- dropping fruits before picking a card.

**Why it happens:** The PICKING state does not pause the tree, or the starter pick overlay does not have mouse_filter=STOP on its background.

**How to avoid:** PICKING state must pause the tree just like SHOPPING and PAUSED. The starter pick overlay follows the same CanvasLayer + full-rect ColorRect pattern. Game flow: READY -> PICKING (tree paused, overlay shown) -> player picks card -> DROPPING (tree unpaused, gameplay begins).

**Warning signs:** Fruits spawn or drop before the player picks a starter card.

### Pitfall 5: Card Slot UI Not Updating After Purchase/Sell

**What goes wrong:** Player buys a card in the shop, but the HUD card slots do not reflect the purchase until the shop closes or the next merge happens.

**Why it happens:** The HUD listens to EventBus signals, but no signal is emitted after a card purchase/sell, or the signal is emitted before the card is actually added to the inventory.

**How to avoid:** Emit `EventBus.card_purchased(card, slot_index)` AFTER successfully adding the card to CardManager. Emit `EventBus.card_sold(card, slot_index)` AFTER removing and refunding. HUD connects to these signals and calls `display_card()` or `display_empty()` on the appropriate slot.

**Warning signs:** HUD shows stale card state. Cards appear in HUD only after another game event triggers a refresh.

### Pitfall 6: Shop Prices Not Reflecting Inflation

**What goes wrong:** All shops show the same prices regardless of when they appear in the run.

**Why it happens:** Using `card.base_price` directly instead of applying the shop-level price multiplier.

**How to avoid:** The shop display must call `CardManager.get_buy_price(card)` which applies the price multiplier. The sell price must also use the multiplied price (50% of what the player would pay at the current shop level, NOT 50% of base price). However, tracking what the player ACTUALLY paid for a card is simpler and more transparent -- store the purchase price on the active card entry.

**Warning signs:** Prices feel flat throughout the run. Rare cards in early shops cost the same as late shops.

### Pitfall 7: Coin Economy Too Stingy or Too Generous

**What goes wrong:** Players either cannot afford any cards (frustrating) or can buy every card offered (trivializes choices).

**Why it happens:** The coin threshold (100 score = 1 coin) was designed before card prices were defined. The math may not balance.

**How to avoid:** Calculate expected coin income at each threshold. Score 500 = ~5 coins minimum. Score 1500 = ~15 coins. Common cards should cost 8-12 coins. By the first shop, the player should be able to afford 1 common card but not 2. Test with actual gameplay data after implementation. The coin economy will need tuning -- make all values constants, not magic numbers.

**Warning signs:** Players always skip the shop (too expensive). Players always buy max cards (too cheap). No meaningful purchase decisions.

## Code Examples

### EventBus Card Signals (Additions)

```gdscript
# scripts/autoloads/event_bus.gd -- NEW signals to add

## Emitted when the starter card pick UI should appear.
signal starter_pick_requested(offers: Array)

## Emitted when the player picks a starter card.
signal starter_pick_completed(card: CardData)

## Emitted when the card shop should open.
signal shop_opened(offers: Array, shop_level: int)

## Emitted when the player closes the shop (buy, skip, or sell).
signal shop_closed()

## Emitted when a card is purchased and added to a slot.
signal card_purchased(card: CardData, slot_index: int)

## Emitted when a card is sold from a slot.
signal card_sold(card: CardData, slot_index: int, refund: int)

## Emitted when active cards change (purchase, sell, or reset).
signal active_cards_changed(cards: Array)
```

### Weighted Rarity Selection

```gdscript
# In CardManager -- simple weighted random, no plugin needed
func _pick_weighted_rarity(weights: Array) -> int:
    ## Returns 0 (COMMON), 1 (UNCOMMON), or 2 (RARE).
    ## weights = [common_chance, uncommon_chance, rare_chance] summing to ~1.0
    var roll: float = randf()
    var cumulative: float = 0.0
    for i in weights.size():
        cumulative += weights[i]
        if roll <= cumulative:
            return i
    return 0  # Fallback to common

func _pick_random_card_of_rarity(rarity: int) -> CardData:
    ## Pick a random card from the pool matching the given rarity.
    var matching: Array[CardData] = []
    for card in _card_pool:
        if card.rarity == rarity:
            matching.append(card)
    if matching.is_empty():
        # Fallback: if no cards of this rarity, try common
        return _pick_random_card_of_rarity(CardData.Rarity.COMMON)
    return matching.pick_random()
```

### Shop Buy/Sell Flow

```gdscript
# In card_shop.gd
func _on_buy_pressed(card: CardData) -> void:
    var price: int = CardManager.get_buy_price(card)
    if GameManager.coins < price:
        # Flash "not enough coins" feedback
        return
    if not CardManager.has_empty_slot():
        # Flash "no empty slots" feedback
        return
    GameManager.coins -= price
    var slot: int = CardManager.add_card(card)
    EventBus.card_purchased.emit(card, slot)
    # Update shop UI to reflect purchase

func _on_sell_pressed(slot_index: int) -> void:
    var card: CardData = CardManager.active_cards[slot_index]
    if card == null:
        return
    var refund: int = CardManager.get_sell_price(card)
    CardManager.remove_card(slot_index)
    GameManager.coins += refund
    EventBus.card_sold.emit(card, slot_index, refund)
    # Update shop UI to reflect sale

func _on_skip_pressed() -> void:
    EventBus.shop_closed.emit()
    GameManager.change_state(GameManager.GameState.DROPPING)
```

### Game Flow Integration

```gdscript
# In game.gd -- Modified to handle card system flow
func _ready() -> void:
    GameManager.change_state(GameManager.GameState.READY)
    EventBus.game_over_triggered.connect(_on_game_over)
    EventBus.score_threshold_reached.connect(_on_score_threshold)
    EventBus.shop_closed.connect(_on_shop_closed)
    EventBus.starter_pick_completed.connect(_on_starter_pick_done)

    # Start with starter card pick instead of going directly to DROPPING
    await get_tree().create_timer(0.3).timeout
    _show_starter_pick()

func _show_starter_pick() -> void:
    var offers: Array = CardManager.generate_starter_offers(3)
    GameManager.change_state(GameManager.GameState.PICKING)
    EventBus.starter_pick_requested.emit(offers)

func _on_starter_pick_done(_card: CardData) -> void:
    GameManager.change_state(GameManager.GameState.DROPPING)

func _on_score_threshold(threshold: int) -> void:
    if GameManager.current_state == GameManager.GameState.DROPPING \
            or GameManager.current_state == GameManager.GameState.WAITING:
        var offers: Array = CardManager.generate_shop_offers()
        CardManager._shop_level += 1
        GameManager.change_state(GameManager.GameState.SHOPPING)
        EventBus.shop_opened.emit(offers, CardManager._shop_level)

func _on_shop_closed() -> void:
    GameManager.change_state(GameManager.GameState.DROPPING)
```

### CardData Definitions for All 10 Cards

Score values per tier for coin economy reference (from existing .tres files):
- Tier 0 (Blueberry): 1 point
- Tier 1 (Grape): 2 points
- Tier 2 (Cherry): 4 points
- Tier 3 (Strawberry): 8 points
- Tier 4 (Orange): 16 points
- Tier 5 (Apple): 32 points
- Tier 6 (Pear): 64 points
- Tier 7 (Watermelon): 128 points
- Watermelon vanish: 1000 flat bonus

Coin rate: 1 coin per 100 cumulative score.

Expected coins at each threshold:
- Score 500: ~5 coins
- Score 1500: ~15 coins
- Score 3500: ~35 coins
- Score 7000: ~70 coins

Recommended card pricing:

| Card | Rarity | Base Price | Description |
|------|--------|-----------|-------------|
| Bouncy Berry | Common | 8 | Small fruits (tier 1-3) bounce 50% higher on impact |
| Quick Fuse | Common | 8 | Merges within 1s of previous merge grant +25% score |
| Fruit Frenzy | Common | 10 | +2x score multiplier for chains of 3+ |
| Golden Touch | Common | 10 | +2 coins per merge |
| Cherry Bomb | Common | 8 | When cherries merge, push nearby fruits outward |
| Heavy Hitter | Uncommon | 18 | Next 3 drops have 2x mass, push harder |
| Big Game Hunter | Uncommon | 20 | +50% score for tier 7+ merges |
| Lucky Break | Uncommon | 16 | 15% chance any merge drops bonus 5 coins |
| Pineapple Express | Uncommon | 18 | When pineapple created: +20 coins, +100 score |
| Wild Fruit | Rare | 30 | One random fruit becomes wild (merges with same OR adjacent tier) |

At shop 1 (score 500, ~5 coins): Player has their free starter card + ~5 coins. Can afford 1 common card (price ~8-10 after 1.0x multiplier). Tight but fair -- creates a meaningful buy/skip decision.

At shop 2 (score 1500, ~15 coins): ~10 additional coins since shop 1. Can afford 1 common (price ~10-12.5 after 1.25x) or save for an uncommon.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Singleton autoload per card | CardManager autoload + CardData resources | Godot 4.0+ Resource improvements | Resources scale to 50+ cards. Autoloads per card do not. |
| Inner class Resources (class keyword) | Separate .gd files per Resource type | Godot 4.0+ serialization fix | Inner class resources do not serialize custom properties correctly. Each Resource class needs its own .gd file. |
| PopupDialog for shops | CanvasLayer overlays | Godot 4.0+ (PopupDialog deprecated behavior) | CanvasLayer gives full control over layering, sizing, and process mode. PopupDialog has inconsistent behavior across platforms. |

**Deprecated/outdated:**
- `pause_mode` (Godot 3): Use `process_mode` in Godot 4
- Inner class Resources: Do not use `class` keyword inside a script for Resource subclasses that need .tres serialization. Use separate .gd files.

## Open Questions

1. **Should sell price be 50% of BASE price or 50% of INFLATED price?**
   - What we know: CARD-07 says "50% of purchase price." If the player buys at an inflated price, selling should refund 50% of what they paid.
   - What's unclear: Do we track actual purchase price per card instance, or compute 50% of current-shop-level price?
   - Recommendation: Store `purchase_price` on the active card entry (not on CardData). When selling, refund `purchase_price / 2`. This is simpler and matches player expectations ("I paid X, I get X/2 back"). Implement as a wrapper: `active_cards` stores `{card: CardData, purchase_price: int}` dictionaries instead of raw CardData references.

2. **Should duplicate cards be allowed in the shop and in active slots?**
   - What we know: Requirements do not mention this. Balatro allows duplicate jokers in some cases.
   - What's unclear: Can a player have 2 copies of "Golden Touch" active? Can the shop offer the same card twice?
   - Recommendation: Allow duplicates in active slots (stacking effects is fun and strategically interesting). Avoid duplicates in a single shop offering (feels like a bug). Filter shop generation to avoid offering the same card_id twice in one shop.

3. **When exactly should the shop appear -- immediately on threshold, or after current merge chain finishes?**
   - What we know: Score thresholds fire in ScoreManager during merge processing. If a chain reaction crosses a threshold mid-chain, pausing immediately would interrupt the chain.
   - What's unclear: Whether interrupting feels bad to the player (they want to see their chain play out).
   - Recommendation: Since `get_tree().paused = true` stops physics immediately, the chain would freeze mid-cascade. This might feel jarring. Consider a brief delay: when threshold fires, set a flag, and show the shop after the chain ends (connect to `chain_ended` signal). However, if no chain is active (single merge crosses threshold), open immediately. This adds slight complexity but improves feel.

4. **What CanvasLayer layer should the shop use?**
   - What we know: HUD is layer 1 (default CanvasLayer). PauseMenu is layer 10.
   - What's unclear: Should the shop be above or below the pause menu?
   - Recommendation: Shop on layer 11. If the player somehow triggers pause during shop (unlikely since tree is paused and PauseMenu checks state), the pause menu appears above. In practice, both are mutually exclusive. Starter pick also on layer 11.

## Sources

### Primary (HIGH confidence)
- Existing codebase analysis: EventBus signals (score_threshold_reached, coins_awarded already exist), ScoreManager coin economy (COIN_THRESHOLD = 100), GameManager state machine (PAUSED state pattern), PauseMenu overlay pattern (CanvasLayer layer 10, process_mode ALWAYS), FruitData Resource pattern (class_name, .tres files)
- [Godot official docs: Pausing games and process mode](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html) -- process_mode ALWAYS, SceneTree.paused behavior
- [Godot official docs: Resources](https://docs.godotengine.org/en/stable/classes/class_resource.html) -- Resource serialization, custom Resource classes
- [Godot official docs: CanvasLayer](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html) -- Layer ordering for overlays
- [Godot official docs: Random number generation](https://docs.godotengine.org/en/latest/tutorials/math/random_number_generation.html) -- randf(), pick_random()

### Secondary (MEDIUM confidence)
- [Godot Forum: Custom Resource inheritance](https://forum.godotengine.org/t/solved-question-about-how-inheritance-works-for-resources-that-extend-a-custom-class/99976) -- Separate .gd files required for proper serialization of Resource subclasses
- [Godot Forum: Roguelike card inventory patterns](https://forum.godotengine.org/t/rogulike-card-inventory/98485) -- Community patterns for card inventory in roguelikes
- [Godot Forum: General best practices for popup menus](https://forum.godotengine.org/t/general-best-practices-for-popup-menus/39183) -- CanvasLayer overlay best practices
- [Weighted RNG Tutorial in Godot 4](https://medium.com/@minoqi/weighted-rng-tutorial-in-godot-4-338cbffe1012) -- Cumulative weight pattern for rarity selection
- Prior project research: [ARCHITECTURE.md](../../research/ARCHITECTURE.md) -- CardManager autoload pattern, card effect hook system, card shop flow
- Prior project research: [FEATURES.md](../../research/FEATURES.md) -- Card pool design, rarity system, starter card picks, pricing
- Prior project research: [PITFALLS.md](../../research/PITFALLS.md) -- Card combinatorial explosion (Pitfall 6)

### Tertiary (LOW confidence)
- [Card Framework - Godot Asset Library](https://godotengine.org/asset-library/asset/3616) -- Reviewed but not adopted. Too heavy for our needs (drag-and-drop, JSON data). Our Resource-based approach is simpler and consistent with existing FruitData.
- [WeightedChoice plugin](https://github.com/rehhouari/WeightedChoice) -- Reviewed but not adopted. Our 3-tier rarity is trivially implementable without a plugin.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All components use built-in Godot 4.5 systems (Resources, CanvasLayer, process_mode, signals). Patterns proven in this codebase (FruitData, PauseMenu).
- Architecture: HIGH -- CardManager autoload mirrors GameManager. Shop overlay mirrors PauseMenu. CardData Resource mirrors FruitData. No novel patterns -- all are extensions of existing proven architecture.
- Pitfalls: HIGH -- Primary risks (autoload state persistence, tree pause for shop, threshold signal ordering) are verified through existing codebase behavior and prior phase research.
- Economy/pricing: MEDIUM -- Coin thresholds and card prices are estimates. Will require playtesting and tuning. All values are constants for easy adjustment.

**Research date:** 2026-02-08
**Valid until:** 2026-03-08 (stable Godot features and established project patterns)
