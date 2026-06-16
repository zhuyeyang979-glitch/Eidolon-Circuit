# main.gd 可维护性改造可行性文档

日期：2026-06-16

## 目标

本次改造不以压缩 `scripts/main.gd` 行数为主要指标。目标是降低维护和升级时的认知成本，让开发者能按功能边界快速定位代码，并且让后续迁移可以通过探针验证，避免大范围重写带来的回归。

核心原则：

- `main.gd` 可以继续作为应用装配层和临时兼容层。
- 具体视图、特效、规则、控制器和持久化策略应逐步迁到明确 owner。
- 每一批迁移都必须行为不变、调用点稳定、合同探针先行。
- 不为了“瘦身”拆代码，只在职责边界更清楚时拆。

## 当前可行性判断

项目已经具备渐进式改造条件：

- 已有 `scripts/views/`、`scripts/effects/`、`scripts/controllers/`、`scripts/services/`、`scripts/modes/` 等目录。
- 已有 `docs/architecture_boundaries.md` 和 EC-SLIM backlog，说明目标边界已初步成形。
- 已有大量 headless Godot probe，可支撑小步迁移。
- `main_inline_class_guard_probe.gd` 已能防止已提取类重新内联。
- 最近已成功提取多组 VFX 类，证明“先合同、再外置、再回归”的路径可用。

主要风险：

- `main.gd` 仍承担大量 Godot 节点副作用，不能一次性重写。
- 很多探针仍直接 preload `main.gd`，因此迁移必须保留旧 public wrapper 和字段名。
- 编辑器面板、装配板和战斗运行时耦合较高，不能和低风险视图类混在同一批。
- Godot 脚本 `preload()` 对缺失文件的解析失败不总是可靠返回非零退出码，新增合同探针应优先用运行期 `FileAccess`/`load()` 检查缺失文件。

## 推荐架构方向

`main.gd` 的长期定位是 Composition Root：

```text
main.gd
  启动
  共享资源创建
  mode 注册与切换
  临时兼容 wrapper
  少量跨模式生命周期 glue
```

目标 ownership：

```text
scripts/views/
  纯表现层。创建控件、绘制、展示 model、发 signal。

scripts/effects/
  VFX 节点、短生命周期动画、粒子池。

scripts/controllers/
  用户操作协调、页面局部行为、UI model 组装。

scripts/services/
  可测试规则和决策。优先 RefCounted，不直接依赖场景树。

scripts/modes/
  顶层页面/状态 owner。负责 enter/exit/update/input。

scripts/app/
  AppModeHost、全局 mode 编排。
```

## 优先级顺序

### P0：文档和合同护栏

目的：先定义什么能留在 `main.gd`，什么不能新增到 `main.gd`。

可交付：

- 本文档。
- 每批迁移对应的 `docs/superpowers/plans/*.md`。
- 合同探针覆盖迁移后的文件存在、class_name、main preload、禁止重新内联。

成功标准：

- 新增功能能根据文档判断落点。
- 已提取类不会被重新写回 `main.gd`。

### P1：低耦合视图/特效类型边界

目的：让 `main.gd` 不再定义具体表现层类型，只装配它们。

首批候选：

- `MobiusStripSurfaceView`
- `MobiusStardustBandView`

理由：

- 它们是表现层视图，调用点集中。
- 已有大量 Mobius 视觉探针覆盖运行行为。
- 提取后 `main.gd` 仍负责创建节点和设置 shader/material，不改变运行时 ownership。

成功标准：

- 两个类移动到 `scripts/views/`。
- `main.gd` 只 preload 和 instantiate。
- Mobius 视觉相关探针继续通过。

### P2：目录卡片与预览缓存组

候选：

- `PartPreviewTextureRenderCanvas`
- `PartPreviewTextureCache`
- `PartPreviewIconView`
- `CatalogCardTextLayer`
- `CatalogCardBodyTextureRenderCanvas`
- `CatalogCardBodyTextureCache`
- `CatalogCardRetainedItem`
- `PartCatalogCardButton`

理由：

- 它们属于 Unit Editor 目录表现层。
- 未来优化 catalog UI、卡片可读性、缓存策略时，不应回到 `main.gd` 找类体。

风险：

- 探针中有部分直接引用 `MainScene.PartPreviewTextureCache` 或 `MainScene.AssemblyBoardView`，需要先提供兼容路径或更新探针。

### P3：编辑器详情面板组

候选：

- `EditorStatsRailView`
- `EditorPartHoverPopupView`
- `TorsoDetailPanelView`
- `EngineMomentumAllocationPanelView`
- `UnitEditorPowerDockView`

理由：

- 这些类变化原因高度集中在编辑器 UI。
- 但与 `main.gd` 当前编辑器状态、选中零件、分配面板交互耦合较高。

策略：

- 先提取只绘制/展示的部分。
- 再让 `TeamEditMode` 或 editor controller 接管更多状态协调。

### P4：装配板渲染和交互组

候选：

- `AssemblyBoardRenderLayer`
- `AssemblyBoardRenderComponentItem`
- `AssemblyBoardRenderItem`
- `AssemblyBoardView`

理由：

- 这是 Unit Editor 的核心交互区域，未来升级频率高。

风险：

- 涉及拖拽、拓扑、pose、链接、hover、保存校验和大量探针。

策略：

- 分两步：先移动 render item/layer，再迁 `AssemblyBoardView`。
- 保留旧字段和 wrapper，避免一次性触碰所有 board probes。

### P5：BattleRuntimeFacade

目的：让战斗 tick、输入、投射物、接触、VFX、HUD 更新的调用路径更像流程，而不是散落在 `main.gd` 中。

建议：

- 新增 `scripts/battle/battle_runtime_facade.gd` 或先放在 `scripts/services/` 作为 staging。
- 第一阶段只协调已有 service，不移动深层算法。
- `main.gd` 保留 wrapper，逐步委托给 facade。

当前状态：

- 已新增 `scripts/battle/battle_runtime_facade.gd`。
- 第一阶段代理 `BattleFrameOrchestratorService` 的 frame step、simulation phase、contact pass、post-step state 四类纯计划方法。
- 第二阶段代理 `BattleRuntimeLifecycleService` 和 `BattleRuntimeActionTelemetryService` 中已经纯化的 intent/model 方法。
- 第三阶段增加 `BattlePresentationFrameService`，只代理 motion snapshot state 和 render frame plan。
- 第四阶段增加 `BattlePresentationApplier`，负责按 render frame plan 调用 host 上的 presentation 刷新副作用。
- 第五阶段增加 `BattlePresentationHostAdapter`，把 applier 依赖的 host interface 显式化，避免 applier 直接依赖 `main.gd` 私有方法名。
- `main.gd` 的 battle tick、lifecycle intent、action telemetry、presentation frame plan 入口已经通过 `_battle_runtime_facade()` 进入该边界，render frame 副作用由 `BattlePresentationApplier` 通过 host adapter 执行。深层命中、投射物、VFX、单位状态更新算法暂不迁移。

## 决策记录

### ADR-001：采用模块化单体和渐进式外置，不做大重写

决策：继续保留 Godot 单项目结构，使用 modular monolith + strangler fig 的方式迁移。

取舍：

- 优点：风险低，现有探针可复用，能持续交付。
- 缺点：迁移期间 `main.gd` 会保留兼容 wrapper，看起来不会马上变小。

### ADR-002：成功指标采用可导航性和边界清晰度

决策：不以行数作为主要 KPI。

验收问题：

- 修改菜单视觉是否只需要看 `MenuView` 和 layout tokens？
- 修改 VFX 是否只需要看 `scripts/effects/` 和 VFX budget？
- 修改 Mobius 视觉是否只需要看 Mobius view + `MobiusWorld`？
- 修改战斗规则是否能优先落在 service/system，而不是直接写进 `main.gd`？

### ADR-003：每批迁移必须合同探针先行

决策：新增或更新 probe 后先看 RED，再迁移实现。

取舍：

- 优点：能证明探针真的约束了新边界。
- 缺点：每批迁移多一步，但能避免“看起来拆了，实际没守住边界”。

### ADR-004：BattleRuntimeFacade 先做薄门面，不做第二个 main.gd

决策：`BattleRuntimeFacade` 第一阶段只收束 battle frame orchestration 调用路径，内部继续委托给已存在的 `BattleFrameOrchestratorService`。

取舍：

- 优点：调用入口更清晰，后续 battle tick ownership 有稳定落点。
- 缺点：短期内不会显著减少 `main.gd` 行数，主要收益体现在调用路径和边界可维护性。

### ADR-005：Facade 第二阶段只接纯 intent/model service

决策：`BattleRuntimeFacade` 第二阶段接入 `BattleRuntimeLifecycleService` 和 `BattleRuntimeActionTelemetryService`，但不迁移 `_render_battle_frame()`、motion snapshot、VFX spawn、unit mutation 等副作用流程。

取舍：

- 优点：battle runtime 的纯决策入口统一，`main.gd` 更像 effect applier。
- 缺点：渲染插值和节点生命周期仍留在 `main.gd`，需要后续更细的 presentation/system 边界再迁。

### ADR-006：Presentation 先抽 frame plan，不搬渲染副作用

决策：新增 `BattlePresentationFrameService`，只负责 motion snapshot 相机状态推进和 render frame 刷新顺序计划。`main.gd` 继续执行 `_refresh_mobius_surface_view()`、`_refresh_unit_screen_positions()`、`_update_battle_ui()` 等副作用。

取舍：

- 优点：presentation 的状态推进和刷新顺序有独立合同，后续可继续拆出 effect applier。
- 缺点：`_render_battle_frame()` 仍保留在 `main.gd`，短期收益主要是结构可读性和回归保护。

### ADR-007：Presentation 副作用使用 applier，不进入 facade

决策：新增 `BattlePresentationApplier` 执行 render frame plan。`BattleRuntimeFacade` 继续只负责返回纯 plan/model，applier 接收 host 和 plan 后调用现有刷新方法。

取舍：

- 优点：`_render_battle_frame()` 只保留编排入口，副作用调用顺序集中到 applier，并可用 fake host 做合同验证。
- 缺点：第一版 applier 仍依赖 host 方法名，是过渡性边界；后续已通过 ADR-008 收束为显式 adapter。

### ADR-008：Presentation host interface 显式化

决策：新增 `BattlePresentationHostAdapter`，由 `main.gd` 负责把现有私有刷新方法绑定为 callback。`BattlePresentationApplier` 只调用 adapter 的公开接口，不再知道 `_refresh_mobius_surface_view()`、`_update_battle_ui()` 等 `main.gd` 私有方法名。

取舍：

- 优点：applier 的依赖面从“任意 host + 字符串方法名”收窄为小型接口，后续 presentation 刷新步骤变更时有明确落点。
- 缺点：callback binding 仍在 `main.gd`，因此它还不是完整的 presentation subsystem；但这是保持行为不变的低风险过渡层。

## 执行进度

### 已完成：P1 视图/特效外置

已将低耦合表现层类型从 `main.gd` 迁出：

- Mobius 视图：`MobiusStripSurfaceView`、`MobiusStardustBandView`
- 战斗/训练/拖拽视图：HUD、minimap、diagnostics、part preview、intro、drag ghost、component art 等
- 战斗特效：命中、连击、投射物轨迹、telegraph、field aura、identity transfer、contact VFX pool 等

### 已完成：P2/P3 编辑器视图外置

已将目录卡片、预览缓存、hover popup、stats rail、unit detail、power dock、engine allocation、torso detail 等编辑器视图迁到 `scripts/views/catalog/` 和 `scripts/views/editor/`。

### 已完成：P4 装配板边界外置

已将 `AssemblyBoardRenderLayer`、`AssemblyBoardRenderComponentItem`、`AssemblyBoardRenderItem` 和 `AssemblyBoardView` 迁到 `scripts/views/editor/assembly_board_view.gd`。`main.gd` 只负责 preload、创建节点和连接 signal。

当前守卫：

- `tools/main_inline_class_guard_probe.gd` 预期 `main.gd` 内联类数量为 0。
- `tools/view_extraction_contract_probe.gd` 覆盖 27 个已抽取视图边界。
- 装配板 retained render / edge / socket / overlay / deferred component 探针覆盖迁移后的行为。

### 已开始：P5 服务边界收紧

当前选择先收紧已有 service，而不是一次性新建大 facade：

- 新增 `_battle_hud_service()` lazy accessor。
- `BattleHudStateService` 成为 HUD 文本、条形模型、ammo display、scoreboard、instrument gauge model 的唯一 owner。
- 删除 `main.gd` 中的 legacy Battle HUD fallback 函数。
- `tools/battle_hud_state_service_contract_probe.gd` 会阻止 legacy HUD fallback 回流。
- 新增 `_battle_input_service()` lazy accessor。
- `BattleInputService` 成为 battle action names、edge frame、control route、spectator intent、direction edge、movement input state、input vector shaping 的唯一 owner。
- 删除 `main.gd` 中的 legacy Battle Input fallback 函数。
- `tools/battle_input_service_contract_probe.gd` 会阻止 legacy input fallback 回流。
- 新增 `_saved_unit_library_service()` lazy accessor。
- `SavedUnitLibraryService` 成为 saved-unit cache signature、cache refresh intent、latest-name lookup、save path、payload、readback status、entry restore、rejected entry、record-to-entry conversion 的唯一 owner。
- 删除 `main.gd` 中的 legacy saved-unit library fallback 函数。
- `tools/saved_unit_library_service_contract_probe.gd` 会阻止 legacy saved-unit fallback 回流。
- 新增 `_training_entry_service()` lazy accessor。
- `TrainingEntryService` 成为 training dummy math/stats/entry、intro segments、pending imports、import loadout、first legal hero、starter loadout、training side assignment 的唯一 owner。
- 删除 `main.gd` 中的 legacy training entry fallback 函数。
- `tools/training_entry_service_contract_probe.gd` 会阻止 legacy training fallback 回流。
- 新增 `BattleRuntimeFacade` 第一阶段 staging boundary。
- `_tick_battle()`、`_tick_battle_simulation()` 和接触 pass 入口通过 `_battle_runtime_facade()` 调用 frame/phase/contact/post-step plans。
- `tools/battle_runtime_facade_contract_probe.gd` 会阻止 `main.gd` 绕过 facade 直接调用 frame orchestrator plan 方法。
- 扩展 `BattleRuntimeFacade` 第二阶段 staging boundary。
- battle cleanup summary、kill flow、destroy economy、escape pod、retreat、fracture brood、action telemetry、projectile target diagnostics 入口通过 `_battle_runtime_facade()` 代理到原 service。
- `tools/battle_runtime_lifecycle_service_contract_probe.gd` 和 `tools/battle_runtime_action_telemetry_service_contract_probe.gd` 会阻止这些路径回退到 direct service call。
- 新增 `BattlePresentationFrameService` 第三阶段 boundary。
- motion snapshot 的相机 previous/current/init 推进和 render frame 刷新顺序通过 `_battle_runtime_facade()` 获取纯 plan，`main.gd` 继续应用节点副作用。
- `tools/battle_presentation_frame_service_contract_probe.gd` 会阻止 presentation plan 绕过 facade 或 service 吸收节点副作用。
- 新增 `BattlePresentationApplier` 第四阶段 boundary。
- `_render_battle_frame()` 缩为获取 render frame plan 并交给 `_battle_presentation_applier().apply_render_frame(_battle_presentation_host_adapter(), plan)`。
- `tools/battle_presentation_applier_contract_probe.gd` 会守住 render frame 副作用顺序，并阻止 `_render_battle_frame()` 回退到直接调用刷新函数。
- 新增 `BattlePresentationHostAdapter` 第五阶段 boundary。
- `main.gd` 通过 `_battle_presentation_host_callbacks()` 绑定现有 presentation 刷新 callback，applier 只依赖 adapter 公开方法。
- `tools/battle_presentation_host_adapter_contract_probe.gd` 会阻止 adapter 吸收节点、运行时、spawn 或 `main.gd` 私有方法名依赖。

## 下一批建议

优先继续做“已有 service 的边界收紧”，而不是开启大规模搬迁：

1. 继续逐个收紧其它已有 battle runtime service 的 direct/null fallback，优先选择 probe 覆盖充足的路径。
2. 如果 presentation 刷新步骤继续增多，再考虑把 `BattlePresentationHostAdapter` 从 callback adapter 升级为专门的 presentation subsystem owner。
