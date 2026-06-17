# main.gd 结构优化可行性

## 目标
- 不追求单纯压缩行数
- 优先降低耦合、重复分支和维护成本
- 保持现有行为不变，继续依赖现有探针做回归保护

## 已落地
- `scripts/main.gd` 的音频退出清理已补上，修复了退出时的 `ObjectDB instances leaked` 警告
- 规则服务调用已统一成 accessor 风格，去掉了分散的 `new()` 兜底
- `tools/image2_*` 截图类探针已改成 headless 跳过，避免无图形环境下误报

## 优先级 1
先拆 `main.gd` 里最密集的规则计算和数据修正逻辑。

建议先切这些块：
- `_compute_unit_stats`
- `_resolve_attack`
- `_build_editor_ui`
- `_refresh_editor_visual_views`
- `_apply_editor_panel_visibility`

建议落点：
- `scripts/services/` 下补纯逻辑服务
- `scripts/main.gd` 只保留编排和状态切换

收益：
- 最高
- 能最快降低 main 的阅读成本

风险：
- 中等
- 需要保留现有 contract probes

## 优先级 2
拆编辑器和卡片类视图。

建议优先拆：
- `scripts/views/editor/assembly_board_view.gd`
- `scripts/views/editor/engine_momentum_allocation_panel_view.gd`
- `scripts/views/editor/torso_detail_panel_view.gd`
- `scripts/views/catalog/part_catalog_card_button.gd`
- `scripts/views/catalog/part_preview_texture_render_canvas.gd`

收益：
- 高
- 更容易独立维护 UI、渲染和缓存逻辑

风险：
- 低到中
- 主要是信号、状态和缓存边界要对齐

## 优先级 3
继续清理 headless / probe 约束。

建议：
- 视觉类 probe 默认 headless skip
- 仍保留纯逻辑 contract probe
- 新增 probe 时先判断能否在 headless 稳定运行

收益：
- 中
- 减少 CI 和本地验证噪音

风险：
- 低

## 建议顺序
1. 先拆规则计算
2. 再拆 editor UI
3. 再拆 catalog / preview / panel 视图
4. 最后继续补探针和收尾清理
