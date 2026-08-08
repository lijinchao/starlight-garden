# 星光花园 - ChatGPT Image 2 素材提示词与接入清单

## 1. 使用目标

本清单服务当前项目的两条主线：

1. 迭代 F：前三局花园恢复反馈
2. 迭代 G：前 5 关主题化目标与 `清风唤醒`

因此本轮素材优先级不是“大而全”，而是：

- 先替换当前高频出现的纯色背景
- 先补齐前 5 关主题化关卡所需视觉
- 先做可直接落入项目的位图资产

---

## 2. 推荐下载顺序

按以下顺序生成和下载：

1. 局内背景 `1-2` 张
2. 花园阶段背景 `3` 张
3. 花朵棋子 `6` 张
4. `清风唤醒` 特效 `2` 张

---

## 3. 统一风格前缀

以下内容建议作为每个提示词的固定前缀：

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark
```

---

## 4. 文件命名与落盘路径

建议直接按以下命名下载到项目内：

| 资源 | 建议文件名 | 建议尺寸 | 建议目录 |
|------|------|------|------|
| 局内背景-通用 | `bg_puzzle_garden_soft.png` | `1080x1920` | `assets/sprites/backgrounds/` |
| 局内背景-初始修复 | `bg_puzzle_garden_awaken_early.png` | `1080x1920` | `assets/sprites/backgrounds/` |
| 花园背景-阶段1 | `bg_garden_stage_1.png` | `1080x1920` | `assets/sprites/backgrounds/` |
| 花园背景-阶段2 | `bg_garden_stage_2.png` | `1080x1920` | `assets/sprites/backgrounds/` |
| 花园背景-阶段3 | `bg_garden_stage_3.png` | `1080x1920` | `assets/sprites/backgrounds/` |
| 红玫瑰棋子 | `tile_red_rose.png` | `512x512` | `assets/sprites/tiles/` |
| 蓝勿忘我棋子 | `tile_blue_forget_me_not.png` | `512x512` | `assets/sprites/tiles/` |
| 紫薰衣草棋子 | `tile_purple_lavender.png` | `512x512` | `assets/sprites/tiles/` |
| 黄向日葵棋子 | `tile_yellow_sunflower.png` | `512x512` | `assets/sprites/tiles/` |
| 白茉莉棋子 | `tile_white_jasmine.png` | `512x512` | `assets/sprites/tiles/` |
| 粉樱花棋子 | `tile_pink_cherry.png` | `512x512` | `assets/sprites/tiles/` |
| 清风轨迹特效 | `fx_breeze_trail.png` | `1024x512` | `assets/sprites/vfx/` |
| 唤醒闪光特效 | `fx_breeze_burst.png` | `512x512` | `assets/sprites/vfx/` |

说明：

- 背景图用竖版，方便主菜单、局内、花园通用裁切
- 棋子图建议透明背景、单物体、居中，尺寸做大一点，进游戏缩小更稳
- 特效图建议透明背景 PNG

---

## 5. 提示词

### 5.1 局内背景

#### A. 通用局内背景

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A softly blurred enchanted garden background for a match-3 puzzle board, viewed frontally for mobile UI, subtle flower beds, faint glowing paths, soft grass, distant garden lights, pastel pink lavender sky, calm decorative depth, center area visually quieter for placing a 7x7 puzzle board, readable composition, no characters, no large foreground objects, vertical mobile game background, 1080x1920
```

#### B. 前 1-3 关局内背景

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A half-awakened garden puzzle background, soft neglected flower beds, a few curled leaves, dim small lights, faint starlight beginning to appear, gentle sense of restoration, quiet and healing mood, mobile match-3 board background, center kept visually clean for gameplay, vertical composition, 1080x1920
```

### 5.2 花园阶段背景

#### C. 阶段 1

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A small healing garden in early restoration stage, a few empty pots, one patch of fresh sprouts, soft grass, light pink and lavender sky, subtle fallen leaves remaining, cozy magical atmosphere, front-facing mobile game garden scene, readable and uncluttered, vertical 1080x1920
```

#### D. 阶段 2

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A healing garden in mid restoration stage, one flower bed blooming, terrace vines becoming lively, a garden path gently lit, pastel flowers opening, warm magical dusk light, front-facing mobile game scene, decorative but still clean and readable, vertical 1080x1920
```

#### E. 阶段 3

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A fully awakened cozy starlight garden, glowing bench light, blooming flower path, gentle lantern glow, sparkling magical air, warm evening garden, elegant and calm, front-facing mobile game garden scene, readable composition for UI overlay, vertical 1080x1920
```

### 5.3 花朵棋子

所有棋子提示词都建议附加这段：

```text
single game icon, centered, transparent background, no shadow cutoff, no frame, no text, polished mobile puzzle tile, high readability at small size
```

#### 红玫瑰

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A red rose match-3 tile icon, rounded layered petals, soft glossy finish, tiny golden flower core, gentle magical sparkle, single game icon, centered, transparent background, no frame, no text, polished mobile puzzle tile, high readability at small size
```

#### 蓝勿忘我

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A blue forget-me-not match-3 tile icon, five rounded petals, small warm yellow center, glossy candy-like finish, soft magical sparkle, single game icon, centered, transparent background, no frame, no text, polished mobile puzzle tile, high readability at small size
```

#### 紫薰衣草

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A lavender match-3 tile icon, stylized purple flower cluster, soft rounded silhouette, readable at small size, glossy dreamy finish, gentle sparkle, single game icon, centered, transparent background, no frame, no text, polished mobile puzzle tile
```

#### 黄向日葵

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A sunflower match-3 tile icon, warm yellow petals, soft brown center, rounded cheerful silhouette, glossy magical finish, single game icon, centered, transparent background, no frame, no text, polished mobile puzzle tile, readable at small size
```

#### 白茉莉

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A white jasmine match-3 tile icon, layered white petals with pearl-like sheen, soft rounded silhouette, subtle magical sparkle, single game icon, centered, transparent background, no frame, no text, polished mobile puzzle tile
```

#### 粉樱花

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A pink cherry blossom match-3 tile icon, heart-shaped petals, soft pink gradient, glossy dreamy finish, gentle sparkle, single game icon, centered, transparent background, no frame, no text, polished mobile puzzle tile
```

### 5.4 清风唤醒特效

#### F. 清风轨迹

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A magical gentle breeze effect for a healing garden puzzle game, swirling pale gold and soft mint wind trail, tiny flower petals and sparkles carried in the air, elegant curved motion, transparent background, VFX asset, centered, no frame, no text
```

#### G. 唤醒闪光

```text
Dreamy healing casual game art for a mobile match-3 garden game, feminine audience, pastel macaron palette, soft warm lighting, starlight sparkle accents, gentle dusk atmosphere, clean readable shapes, rounded forms, polished mobile game asset quality, whimsical but not childish, elegant and cozy, high clarity, no text, no watermark.

A small awakening burst effect for a garden match-3 game, warm golden glow, soft star particles, subtle floral light bloom, magical but gentle, transparent background, VFX asset, centered, no frame, no text
```

---

## 6. 当前项目中的优先替换落点

### 第一批：直接提升观感

1. `scripts/ui/SimpleGameController.gd`
   - 当前局内背景是 `ColorRect`
   - 优先替换为 `TextureRect` + 局内背景图

2. `scripts/ui/GardenUI.gd`
   - 当前花园背景是 `ColorRect`
   - 优先替换为 `TextureRect`
   - 可按 `restoration_stage` 切换 `stage_1 / stage_2 / stage_3`

3. `scripts/ui/MainMenu.gd`
   - 当前主菜单背景是 `ColorRect`
   - 可复用 `bg_garden_stage_2.png` 或 `bg_garden_stage_3.png`

### 第二批：直接替换程序花朵

4. `scripts/ui/Tile.gd`
   - 当前使用 `SpriteGenerator.generate_flower_texture()`
   - 后续可改成按 `tile_type` 读取本地 PNG

### 第三批：补局内差异化

5. `scripts/ui/BoardVisual.gd`
   - 当前 `show_awakening_animation()` 用 `Label` 做提示
   - 可替换为 `fx_breeze_trail.png` / `fx_breeze_burst.png`

---

## 7. 下载时的额外约束

为了让图片更适合当前项目，建议每次补这类限制：

### 背景图

```text
keep the center area visually calm for gameplay UI
```

### 棋子图

```text
transparent background, single object only, centered, no extra decoration
```

### 特效图

```text
transparent background, isolated VFX asset
```

---

## 8. 下一步接入顺序

你下载完成后，建议按下面顺序接项目：

1. 接局内背景
2. 接花园背景
3. 接菜单背景
4. 接棋子 PNG
5. 接清风唤醒特效

这样每一步都能单独验证，不会一口气改太多。

---

## 9. 当前接入状态

- [x] 局内背景按前 3 关与后续关卡切换
- [x] 花园与主菜单背景按恢复阶段切换
- [x] 六类普通花朵棋子优先使用透明 PNG
- [x] `清风唤醒` 接入轨迹与闪光素材
- [x] 缺失图片或特殊棋子保留程序纹理回退
- [x] 自动化测试覆盖素材加载、棋子接入与特效创建
