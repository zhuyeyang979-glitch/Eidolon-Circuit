# 《星魂回环》资料索引

核对日期：2026-10-02。项目身份为 **Eidolon Circuit / Star Soul Loop（星魂回环）**。Windows 活动开发源是 `E:\New project`；仓库为 `zhuyeyang979-glitch/Eidolon-Circuit`。本索引只标注来源和适用性，不移动工程依赖。远端开发分支仍落后本地 10 个旧提交，因此部分下列路径目前只在本地活动 checkout 中存在。

## 现行依据（有效：设计或源码依据，非今日试玩验收）

| 类别 | 从哪里开始 | 使用边界 |
| --- | --- | --- |
| 设计规则 | `docs/godotmaker_existing_loop_contract.md`、`GDD.md`、`PLAN.md`、`ROADMAP.md` | `v0.1.0` 现有循环恢复：主菜单 → Team Edit / Training → 战斗反馈 → 复盘、重赛或返回。以具体源码和新验收处理文档冲突。 |
| 架构与实现 | `STRUCTURE.md`、`SCENES.md`、`docs/architecture_boundaries.md`、`scripts/main.gd`、`scripts/fighter.gd` | Hero / Puppet / Barrier、部件合法性、动量优先战斗、确定性本地行为。大文件重构应围绕可复现故障逐步进行。 |
| 美术与授权 | `ASSETS.md`、`STYLE.md`、`docs/resource_policy.md`、`assets/generated/`、`assets/concepts/` | 复用仓库已有素材；`ASSETS.md` 的 `PROVIDED` 表示文件已提供，不能证明外部素材的商用许可。新素材另核授权。 |
| 开发交接 | `MEMORY.md`、`memory/`、`docs/local_development_status.md` | 优先读取最近且与当前提交相符的条目；该状态文档有旧分支/旧文件长度快照。 |

## 候选设计与历史材料

| 状态 | 资料 | 处理方式 |
| --- | --- | --- |
| 候选 | `docs/plans/`、`docs/superpowers/plans/`、`docs/superpowers/specs/`、`docs/reports/` | 保留方案、取舍和实验来源；只有与当前 `PLAN.md`、源码及试玩结果一致的部分进入本阶段。 |
| 混合年代 | `README.md`、`WORKLOG_RULEBOOK.md` | 含有旧预算、旧按键与较新的治理说明。逐条核对，不能整篇当作现行规则。 |
| 不适用 | “球体星球地图上的隐藏信息实时 PVE roguelike”“VerticalSliceShowcase / VisualEventLayer / scripts/map_view.gd” | 这些线索属于其他项目的历史误检，不用于《星魂回环》的设计或实现。 |

## 开发、测试与试玩版本

| 状态 | 来源 | 当前可得结论 |
| --- | --- | --- |
| 有限历史证据 | `tools/run_godot_checked.ps1`、`tools/run_probe_manifest.py`、`tools/run_verify.py`、`tools/probe_manifest.json`、`e2e/` | 本地 `MEMORY.md` 记录 2026-07-03 修复后 E2E 13/13 通过；不是 2026-10-02 的新运行结果。 |
| 未完成验收 | `.godotmaker/evaluation.json`、`.godotmaker/verify_report.json`、`.godotmaker/stage.jsonl` | 最后正式评价仍为 `reject`（整套 E2E 稳定性）；随后修复有记录，但缺新的完整评价和玩家实机验收。 |
| 参考截图 | `e2e/screenshots/`、`.godotmaker/evaluation-runs/` | 用于定位历史界面；动态截图和单帧不能证明动作流畅或操作闭环。 |
| 试玩版本 | Git 标签与交付包 | 2026-10-02 在活动 checkout 未发现 `v0.1.0` Git 标签；不宣称已发布可试玩版本。 |
| 性能测量 | `scripts/perf/hot_path_profiler.gd` 与实际运行日志 | 有测量代码路径；尚无本次环境的帧时间数据。下次测量须记 Godot 版本、场景、输入路线、采样时长和日志位置。 |

## 本次交接边界

活动 checkout `ae4c1dc` 位于 `codex/yhzlxp-eidolon-work`，比其远端跟踪分支领先 10 个旧提交；远端 `main` 更旧。工作区已有监控日志、仪表板和 E2E 截图改动。它们不是本次改动，不应被顺手提交。下一项唯一优先工作是按串行测试安排，复核主菜单、Team Edit、Training 的真实输入、战斗反馈、退出/重开闭环，再针对第一处复现故障做最小修复。
