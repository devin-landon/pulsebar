# PulseBar 路线图（Cursor 施工图）

- 版本：0.1
- 更新：2026-11-11
- 当前阶段：**M0 已完成**（框架可编译、可运行、可测试）
- 目标读者：接手后续开发的 Cursor / 工程师
- 配套文档：`AGENTS.md`、`PRD.md`、`docs/architecture.md`、`docs/battery-research.md`

---

## 0. 怎么使用这份文档

1. **先读 `AGENTS.md`**，了解构建命令、代码边界和禁止事项。
2. **一次只做一个里程碑**。按 M1 → M2 → M3 → M4 → M5 → M6 顺序推进；M4 是研究型任务，可独立评估后再决定是否进入。
3. **每个任务都有文件、做法、验收标准**。开始前先把任务拆成 3–6 个可验证的小步；完成后勾选复选框。
4. **先写测试，再写实现**（能测的部分）。不能测的硬件行为，写清楚手动验证步骤。
5. **不要伪造读数**。读不到就是 `nil` / “—”，这是产品底线。
6. **每完成一个任务**：`swift build`、`swift test`、`./build.sh`，更新本文件与 `CHANGELOG.md`，提交一次语义清晰的 commit。
7. **私有 API 必须隔离**：单独文件、可选降级、功能开关、文档标注风险；不允许散落在 UI 或 Store 里。

### 给 Cursor 的提示词模板

```text
阅读 AGENTS.md、roadmap.md、PRD.md。当前只做 M1.1「指标采样移出主线程」。
先给出不超过 6 步的实施计划，列出要改的文件和测试；确认后实现。
完成后运行 swift build、swift test，更新 roadmap 复选框，并总结验证结果。
不要顺手实现其他里程碑的任务。
```

```text
继续 M3。先检查 M3 的验收标准与当前代码差距，只实现第一个未完成任务。
遵守：Core 不依赖 SwiftUI/AppKit；不伪造电量；私有 API 必须可降级。
```

---

## 1. 产品定位

**一句话**：PulseBar 是常驻 macOS 菜单栏的「系统状态 + 外设电量」面板——保留 Pulse 的轻量原生体验，重做信息层级与视觉，并补上 Pulse 没有的外设电量中心。

### 差异化

1. **一屏读懂**：系统指标 + 外设电量在同一面板，默认不滚动。
2. **外设电量中心**：妙控系列、游戏手柄优先；逐步研究蓝牙音频与移动设备。
3. **读数诚实**：温度/GPU/第三方蓝牙读不到时明确显示“不可用”，不伪装成 0%。
4. **原生轻量**：SwiftUI + AppKit，无第三方运行库，无账户、无网络请求。
5. **可迭代**：Core/UI 分层、Provider 协议、单元测试、离屏快照，方便 Cursor 逐步接手。

### 非目标

- 进程管理、风扇控制、清垃圾、杀毒。
- 外设固件升级、改键、DPI 调节。
- 云端同步、账户体系、遥测。
- 保证所有第三方蓝牙设备都能读到电量。
- Mac App Store 分发（温度等私有 API 与沙盒限制）。

---

## 2. 当前基线（M0）

### 已完成

- [x] SwiftPM 工程：`PulseBarCore`（模型 / 采样 / 电量 / 格式化）+ `PulseBar`（AppKit 菜单栏 + SwiftUI UI）。
- [x] 菜单栏常驻：左键 Popover、右键菜单、仅图标 / CPU / 内存 / 最低外设电量四种标签。
- [x] Dashboard：360 × 648 深色面板，CPU / 内存 / GPU / 温度 / 存储 / 网络六类读数。
- [x] 真实采样：CPU（host_processor_info）、内存（host_statistics64）、内置存储、网络（getifaddrs）。
- [x] GPU 读取器：IOAccelerator `PerformanceStatistics`（按机型可能不可用）。
- [x] 外设电量：HID（IORegistry `AppleDeviceManagementHIDEventService`）+ GameController；合并、去重、30 秒轮询。
- [x] 设置窗口：菜单栏显示、刷新频率、电量轮询、登录时启动、关于。
- [x] 设计系统：色板、圆角、卡片、进度条、电池图形、空状态、低电量样式。
- [x] `--snapshot` 离屏渲染；`PULSEBAR_DEMO=1` 演示设备。
- [x] 13 个单元测试；`build.sh` 生成 ad hoc 签名 `.app`；应用图标。
- [x] 文档：README、PRD、roadmap、架构、外设电量调研、AGENTS、CHANGELOG。

### 已知限制（必须在后续里程碑解决或明确保留）

- CPU 温度是占位实现，始终返回 `nil`（M1.5）。
- 未展示外置磁盘（M1.6）。
- 网络速率使用 32 位接口计数器，未处理 VPN 重复统计（M1.7）。
- 指标采样在主线程（M1.1）。
- 只有深色主题；无紧凑模式、无历史曲线（M2）。
- 第三方 BLE 键鼠在 macOS 上不暴露 `BatteryPercent` 时读不到（M4 研究）。
- AirPods / iPhone / iPad 电量未实现（M4 研究）。
- 无低电量通知（M5）。
- 无 CI、无 Developer ID 签名与公证（M6）。

### 本地命令

```bash
swift build
swift test
./build.sh                 # 生成 PulseBar.app
open PulseBar.app
PULSEBAR_DEMO=1 swift run PulseBar
swift run PulseBar --snapshot docs/images/dashboard.png
```

---

## 3. 里程碑总览

| 里程碑 | 主题 | 预估 | 退出标准 |
| --- | --- | --- | --- |
| M0 | 可运行框架 | 已完成 | 编译、测试、构建、文档通过 |
| M1 | 指标内核 | 2–3 天 | 指标准确、离线不崩、采样不阻塞主线程 |
| M2 | UI 重构 | 3–5 天 | 深/浅色、紧凑模式、历史曲线、可访问性 |
| M3 | 外设电量 v1 | 2–3 天 | HID/GC 稳定、状态完整、文档与测试齐全 |
| M4 | 外设电量 v2（研究） | 4–8 天 | 蓝牙音频/移动设备可行性有结论，实验功能可控 |
| M5 | 提醒与历史 | 2–3 天 | 低电量通知、历史图、诊断导出 |
| M6 | 发布工程 | 2–3 天 | CI、签名、公证、DMG、发布清单 |

> 预估按“熟悉 Swift/macOS 的开发者、每天 4–6 小时”计算；研究型任务（M4）不确定性最高。

---

## 4. M1：指标内核（2–3 天）

### 4.1 指标采样移出主线程

- [ ] 新增 `MetricsScheduler`（串行队列或 actor），按刷新间隔采样。
- [ ] `SystemMetricsProvider` 的采样在后台队列执行；结果回到主线程更新 `DashboardStore`。
- [ ] `CPUSampler` / `NetworkSampler` 的状态只在同一串行上下文访问。
- [ ] 面板打开、设置修改、睡眠/唤醒时不产生竞态或重复定时器。

**文件**：`Sources/PulseBarCore/Metrics/MetricsScheduler.swift`（新）、`SystemMetricsProvider.swift`、`Features/Dashboard/DashboardStore.swift`

**验收**：

- 1 秒刷新时主线程单次采样阻塞 < 2 ms（Instruments / `CFAbsoluteTimeGetCurrent` 计时）。
- 快速开关面板 20 次无崩溃、无重复采样、无内存增长。
- `swift test` 通过；新增 `RateCalculator` / tick delta 的纯逻辑测试。

### 4.2 CPU 使用率准确性

- [ ] 抽出 `CPUTickAccumulator`（纯逻辑，可测试），处理 32 位 tick 回绕。
- [ ] 支持“所有核心聚合”和“性能/效率核心分组”（可选展示）。
- [ ] 空闲时不抖动：对显示值做 3 点 EMA 或死区（≤1% 变化不重绘数字）。
- [ ] 首次采样返回 `nil`，不显示 0%。

**验收**：`yes > /dev/null` 单核满载时总 CPU 明显上升；停止后回落；与 Activity Monitor 趋势一致（允许 ±5% 差异）。

### 4.3 内存口径对齐

- [ ] 明确公式：`active + wired + compressed`（当前实现），在代码注释与文档写清楚。
- [ ] 增加 `memoryUsedBytes` / `memoryTotalBytes` 的展示与单位测试。
- [ ] 处理 0 页、超大内存（≥128 GB）与内存压力接口（`host_statistics64` 失败时回退 `nil`）。

**验收**：与 Activity Monitor 的“已用内存”差异 ≤ 5%；总内存与“关于本机”一致。

### 4.4 GPU 可用性矩阵

- [ ] 在 Apple Silicon（M1–M4）与 Intel Mac 上验证 `IOAccelerator` 是否返回 `Device Utilization %`。
- [ ] 若不可用，评估 `IOGPU` / `AGXAccelerator` 的替代属性；仍不可用则明确展示“不可用”。
- [ ] 不因 GPU 读取失败影响其他指标或启动。

**验收**：`docs/gpu-support.md`（新）记录机型、macOS 版本、是否有读数；无读数时 UI 显示“—”，不崩溃。

### 4.5 CPU 温度（私有 API，可降级）

- [ ] 新建 `TemperatureSampler.swift`，通过 `dlopen`/`dlsym` 解析 `IOHIDEventSystemClientCreate`、`IOHIDEventSystemClientCopyServices`、`IOHIDServiceClientCopyEvent`、`IOHIDEventGetFloatValue` 等符号。
- [ ] 匹配传感器：`PMU tdie`、`pACC MTR`、`eACC MTR`（参考 Pulse 的 MIT 实现，保留出处说明）。
- [ ] 符号缺失、服务为空、数值越界（≤0 或 ≥150）时返回 `nil`。
- [ ] 增加设置开关“显示 CPU 温度（实验）”，默认开启；关闭后不调用私有符号。
- [ ] 在文件头与 `NOTICE`（如实际移植代码）标注来源与 MIT 许可。

**验收**：

- 测试 Mac 上空闲/满载温度有可解释变化（±5 °C 内合理）。
- 人为移除符号（单测注入）时不崩溃，UI 显示“—”。
- 在 macOS 14 / 15 / 26 / 27 至少各跑一次启动与展开面板。

**风险**：私有 API 随系统更新失效；不得用于 App Store；失败必须静默降级。

### 4.6 外置磁盘

- [ ] 用 `FileManager.mountedVolumeURLs` 枚举本地卷，过滤 `/`、网络卷、只读系统卷。
- [ ] 最多展示 3 个，剩余显示“还有 N 个卷”。
- [ ] 扩展 `SystemSnapshot`：`volumes: [VolumeInfo]`（name、used、total、isRemovable）。
- [ ] UI 增加“外置磁盘”卡片；无外置卷时隐藏卡片（不占空间）。

**验收**：插入外置 SSD 后 2 秒内出现，容量与 Finder 一致；拔出后卡片消失不崩溃。

### 4.7 网络速率与 VPN

- [ ] 改用 `sysctl(NET_RT_IFLIST2)` 读取 64 位计数器（`if_msghdr2` / `if_data64`），避免 32 位回绕。
- [ ] 只统计物理主接口（`en*`），排除 `utun`、`awdl`、`llw`、`bridge`、`gif`、`stf`、`anpi`。
- [ ] 抽出 `RateCalculator`：输入 (bytes, timestamp) 序列，输出 B/s；处理计数器回绕、重置、睡眠跨度和首样本。
- [ ] 睡眠/唤醒后重置基线，避免出现巨大尖峰。

**验收**：下载大文件时与 Activity Monitor 网络页趋势一致（±10%）；连接 VPN 时不重复累计；合盖再打开无尖峰。

### 4.8 睡眠 / 唤醒生命周期

- [ ] 监听 `NSWorkspace.willSleepNotification` / `didWakeNotification`，暂停/恢复定时器与采样。
- [ ] 唤醒后立即刷新一次指标与外设电量，并重置有状态采样器（CPU tick、网络计数）。
- [ ] 面板打开时刷新一次，关闭后不停止后台采样（菜单栏仍需更新）。

**验收**：合盖 10 秒再打开，CPU/网络/电量均正常，无冻结、无尖峰、无重复计时器。

### 4.9 诊断命令

- [ ] `PulseBar --diagnose` 输出 JSON：系统版本、架构、各指标可用性、GPU 原始属性键、电池 Provider 结果数量、错误信息。
- [ ] 不输出序列号、MAC 地址等可识别信息（哈希或省略）。
- [ ] 用于 issue 模板与 Cursor 排查。

**验收**：命令在无 GUI 会话下也能返回；JSON 可被 `jq` 解析。

### 4.10 性能预算

- [ ] Instruments 测量：空闲 CPU < 0.5%，面板展开时 < 2%，常驻内存 < 100 MB。
- [ ] 启动到菜单栏可点击 < 300 ms。
- [ ] 记录在 `docs/performance.md`，M6 CI 不强制但发布前复测。

---

## 5. M2：UI 重构（3–5 天）

### 5.1 深色 / 浅色主题

- [ ] 把 `Theme` 从固定深色改为语义令牌：背景、卡片、描边、文字、强调色。
- [ ] 支持“跟随系统 / 深色 / 浅色”设置，持久化。
- [ ] 浅色下对比度 ≥ 4.5:1；卡片层级用阴影/描边而非纯色差。
- [ ] 保留深色为默认（与 Pulse 视觉延续）。

### 5.2 紧凑模式

- [ ] 设置中增加“舒适 / 紧凑”密度；紧凑模式面板高度 560 pt、卡片 padding 10。
- [ ] 紧凑模式仍显示外设电量（至少 2 台），多出部分滚动。
- [ ] 菜单栏标签在窄屏/刘海屏不溢出（最长 “100%” + 图标）。

### 5.3 历史曲线

- [ ] 为 CPU / 内存 / GPU / 温度 / 网络保留最近 60–90 个样本（当前 `DashboardStore.history` 已预留）。
- [ ] 卡片内增加 40 pt 高的 sparkline；默认显示 CPU 与内存，其他可切换。
- [ ] 展开模式使用 Swift Charts 显示 1 分钟 / 5 分钟；内存有上限，不持久化。
- [ ] 无数据时显示平线占位，不伪造趋势。

### 5.4 外置磁盘卡片

- [ ] 复用 M1.6 数据；每个卷一行：名称、已用/总量、进度条、可移除图标。
- [ ] 最多 3 行；超过显示“还有 N 个卷”。
- [ ] 无外置卷时卡片完全隐藏，保持默认一屏。

### 5.5 状态与边界

- [ ] 加载中骨架（首帧 < 1 秒，避免闪烁）。
- [ ] 不可用：`—` + 灰色进度条 + tooltip “此机型不提供该读数”。
- [ ] 过期：外设电量超过 2 分钟未更新显示“数据可能过期”。
- [ ] 空状态：无外设、无外置卷、无网络接口分别有独立文案。
- [ ] 设备超过 3 台时列表滚动，卡片高度有上限。

### 5.6 菜单栏细节

- [ ] “最低外设电量”模式：无设备时显示 `—`，不显示 0%。
- [ ] 低电量（≤20%）时电池符号切换为低电量图标；tooltip 显示设备名与电量。
- [ ] 菜单栏文字与图标间距、字号在深色/浅色菜单栏都可读。
- [ ] 右键菜单增加“立即刷新”。

### 5.7 可访问性

- [ ] 所有图标按钮有 `accessibilityLabel`；电池行有组合标签（设备名、类型、电量、充电状态）。
- [ ] 支持 VoiceOver 导航；不依赖颜色传达状态（低电量同时有“低”文字）。
- [ ] 尊重“减少动态效果”（Live 脉冲、进度条动画、Popover 动画）。
- [ ] 尊重“增强对比度”；键盘可操作（Tab、Esc、⌘,）。
- [ ] 字体不随 Dynamic Type 无限放大导致裁切；至少支持系统“较大文字”。

### 5.8 本地化

- [ ] 引入 String Catalog（`Localizable.xcstrings`），中文（默认）+ 英文。
- [ ] 所有用户可见文案走 `String(localized:)`；日期/时间/字节单位使用 Locale。
- [ ] 设置中增加语言说明（跟随系统）。
- [ ] 英文文案长度检查：按钮/标签不因变长而溢出。

### 5.9 设置页重构

- [ ] 分组：外观（主题/密度）、菜单栏、外设电量、启动、关于。
- [ ] 增加“通知”占位（M5 实现）。
- [ ] 恢复默认设置按钮（二次确认）。
- [ ] 设置窗口可调整大小？保持固定 460 × 580，内容滚动。

### 5.10 快照与视觉回归

- [ ] 扩展 `--snapshot`：`--appearance dark|light`、`--density comfortable|compact`、`--scenario default|empty|low-battery|many-devices`。
- [ ] 生成 `docs/images/` 下 6 张基准图；CI 可选做像素对比（容差 1%）。
- [ ] README 使用深色默认图 + 浅色图。

**视觉验收清单**：

- 4 pt 网格对齐；卡片圆角 18；内外边距 13；卡片间距 10。
- 数字使用 rounded + monospacedDigit，不跳动。
- 强调色每屏不超过 4 种主色。
- 截断：设备名超长省略号；不撑破卡片。
- 360 pt 宽、648 pt 高默认无滚动（3 台外设）。
- 深浅色切换后无“白底白字/黑底黑字”。

---

## 6. M3：外设电量 v1（2–3 天）

### 6.1 HID Provider 加固

- [ ] 处理同一设备多个 HID 服务：按 `SerialNumber` 去重，保留最新/最高电量。
- [ ] `BatteryStatus` 兼容字符串与数字（1 充电 / 2 放电 / 3 满电 / 其他未知）。
- [ ] 过滤内建键盘/触控板、无 `BatteryPercent` 的服务。
- [ ] 名称清洗：去掉尾部空格、控制字符；空名称回退“未命名外设”。
- [ ] 稳定 ID：序列号优先；无序列号时用 `name + transport` 的哈希，避免每次轮询变化。
- [ ] 记录 `Transport`（Bluetooth / USB / FIFO）用于 UI 副标题与诊断。

**测试**：用 fixture 字典覆盖 Apple Magic Mouse / Keyboard / Trackpad、第三方鼠标、无电量服务、重复服务。

### 6.2 IOHIDDevice 回退

- [ ] 调研部分第三方设备是否在 `IOHIDDevice` 暴露 `BatteryPercent`；若是，增加 `HIDDeviceBatteryProvider`。
- [ ] 与 `HIDBatteryProvider` 结果按 ID 合并，避免重复。
- [ ] 若调研结论为“不暴露”，在 `docs/battery-research.md` 记录，不写死代码。

### 6.3 GameController Provider 加固

- [ ] 监听 `GCControllerDidConnect` / `GCControllerDidDisconnect`，连接变化时立即刷新。
- [ ] `batteryLevel < 0` → `nil`；`batteryState` 未知 → `.unknown`。
- [ ] ID 使用 vendor + productCategory + playerIndex，保证多手柄不冲突。
- [ ] 单元测试：把 `GCDeviceBattery` 映射抽成纯函数。

### 6.4 合并、优先级与过期

- [ ] 定义来源优先级：HID > GameController > BluetoothAudio > SystemProfiler > MobileDevice。
- [ ] 同一 ID 多来源时取“有电量且更新”的记录；电量未知不覆盖已知。
- [ ] 超过 120 秒未更新标记 `isStale`；UI 显示“可能过期”。
- [ ] 低电量排序：同一类型内低电量优先；类型顺序 鼠标 → 键盘 → 触控板 → 手柄 → 耳机 → 手机/平板 → 其他。
- [ ] 全部逻辑有单元测试（合并、优先级、过期、排序）。

### 6.5 轮询生命周期

- [ ] 默认 30 秒；睡眠暂停；唤醒立即刷新；面板打开立即刷新。
- [ ] 关闭“轮询电量”后停止定时器并清空列表；重新开启立即刷新。
- [ ] 手动刷新有 1 秒防抖，避免连点。
- [ ] 轮询耗时记录在诊断信息中（HID/GC 各自 < 50 ms）。

### 6.6 UI 状态完整

- [ ] 行内展示：名称、类型 · 来源、电量、电池图形、充电闪电、低电量标记。
- [ ] 未知电量显示“—”，电池图形为空；不显示 0%。
- [ ] 过期显示“可能过期”或更新时间。
- [ ] 5 台以上可滚动；卡片最大高度约 200 pt。
- [ ] 空状态文案与“如何获得电量”说明（妙控/手柄优先）。

### 6.7 设置与文案

- [ ] 说明哪些设备支持、哪些不支持；链接到 `docs/battery-research.md`（本地文本）。
- [ ] 轮询开关关闭时，菜单栏“最低外设电量”显示 `—` 并有 tooltip 说明。
- [ ] 低电量阈值 20%（M5 可配置）。

### 6.8 手动测试矩阵

至少覆盖：

| 设备 | 连接方式 | 预期 |
| --- | --- | --- |
| Magic Mouse / Keyboard / Trackpad | 蓝牙 | 显示电量、充电状态 |
| Xbox / DualSense / DualShock | 蓝牙/USB | 显示电量或未知 |
| AULA F87ProV2D-1（本机） | BLE HID | 预期无电量；不得崩溃/伪造 |
| HECATE G5M Pro（本机） | BLE HID | 同上 |
| 无外设 | — | 空状态 |

把结果写进 `docs/battery-research.md` 的验证记录。

### 6.9 文档

- [ ] README 支持矩阵与限制。
- [ ] `docs/battery-research.md` 更新结论与复现命令。
- [ ] 诊断命令包含每个 Provider 的设备数量与耗时。

---

## 7. M4：外设电量 v2（研究型，4–8 天）

> 原则：先做 spike，拿到结论再决定是否产品化。所有实验功能默认关闭、明确标注“实验性”，失败不影响 v1。

### 7.1 CoreBluetooth GATT 电量（第三方 BLE）

- [ ] 新增 `BluetoothGATTBatteryProvider`：扫描 `Battery Service 0x180F`，连接后读 `Battery Level 0x2A19`。
- [ ] 增加 `NSBluetoothAlwaysUsageDescription`；首次开启实验功能时说明用途并请求权限。
- [ ] 超时 5 秒、失败重试 1 次、完成后断开；缓存 5 分钟。
- [ ] 处理与 HID 设备的冲突：系统已占用的 HID 设备可能无法连接，记录失败原因。
- [ ] spike 目标：本机 AULA / HECATE 至少一个能读到电量；若都不能，写出结论与限制。
- [ ] 结果按 ID 与 HID 合并，避免重复行。

**验收**：开启实验开关后，扫描不导致 UI 卡顿；失败有日志；关闭开关后停止扫描并释放蓝牙资源。

### 7.2 蓝牙音频（AirPods / Beats）

- [ ] 调研路径（按优先级）：
  1. CoreBluetooth GATT（AirPods 是否暴露 0x180F）；
  2. `system_profiler SPBluetoothDataType -json`（部分设备有 battery 字段）；
  3. 私有 `IOBluetoothDevice` / `BatteryPercent`（Objective-C runtime 读取，需隔离）。
- [ ] 支持左右耳/充电盒分项（如系统提供）；不提供则只显示综合电量。
- [ ] 私有路径必须：独立文件、运行时符号检查、失败返回空、功能开关默认关闭。
- [ ] 至少在 AirPods Pro 2 与一款 Beats 上验证；记录 macOS 版本。

**验收**：实验开关关闭时零私有调用；开启后最坏情况 1 秒内返回空且不崩溃；文档写清系统版本差异。

### 7.3 iPhone / iPad（可选）

- [ ] 调研 `MobileDevice.framework`（私有）或 `libimobiledevice` 读取电池容量。
- [ ] 仅 USB 连接、信任此电脑时尝试；不扫描网络、不持久化 UDID。
- [ ] 评估签名/公证与沙盒影响；若不可控，明确“不实现”并关闭议题。

**验收**：有结论（实现或放弃），不留下半成品入口。

### 7.4 厂商私有协议（评估即可）

- [ ] 评估 Logitech HID++、Razer、Keychron 等是否需要厂商 SDK/私有协议。
- [ ] 结论写入文档；除非有明确需求，不进入实现。

### 7.5 实验功能与同意

- [ ] 设置中增加“实验性：增强蓝牙电量（可能不稳定）”，默认关闭。
- [ ] 打开时展示说明：读取范围、权限、可能的连接冲突。
- [ ] 一键关闭并释放资源；诊断信息标注当前启用的实验 Provider。

### 7.6 冲突与去重

- [ ] 同一设备多来源（HID / GATT / 音频）时，按“有电量且最新”合并。
- [ ] UI 不展示重复行；tooltip 可显示来源。
- [ ] 单元测试覆盖多来源冲突。

### 7.7 隐私复核

- [ ] 不持久化 MAC/UDID/序列号；内存中使用哈希 ID。
- [ ] 不发起网络请求；不集成第三方 SDK。
- [ ] README 隐私段落更新。

---

## 8. M5：提醒与历史（2–3 天）

### 8.1 低电量通知

- [ ] 使用 `UNUserNotificationCenter`；首次开启时请求授权，拒绝后显示引导。
- [ ] 阈值：20%（警告）、10%（严重）；同一设备同一放电周期只提醒一次。
- [ ] 充电后重置提醒状态；设备断开/重连不重复轰炸。
- [ ] 免打扰时段（可选 22:00–08:00）。
- [ ] 点击通知打开面板并聚焦该设备（至少打开面板）。

**验收**：模拟电量下降只触发一次；充电后再次下降到阈值可再次触发；关闭开关后无通知。

### 8.2 历史曲线

- [ ] 使用 Swift Charts 展示 1 分钟 / 5 分钟；数据来自 `DashboardStore.history`。
- [ ] 图表可切换指标；无数据时占位。
- [ ] 内存上限：90 个样本；窗口关闭不保留历史（或仅内存）。

### 8.3 菜单栏增强

- [ ] “最低外设电量”模式支持 tooltip 显示设备名。
- [ ] 低电量时菜单栏图标使用低电量符号；不改变系统菜单栏颜色。
- [ ] 可选显示“电量最低的设备名缩写”？默认关闭，避免拥挤。

### 8.4 诊断导出

- [ ] 设置中“复制诊断信息”：JSON 到剪贴板，包含版本、系统、指标可用性、Provider 状态、最近错误。
- [ ] 脱敏：序列号/MAC/UDID 哈希或移除。
- [ ] 用于 issue 模板。

---

## 9. M6：发布工程（2–3 天）

### 9.1 CI

- [ ] GitHub Actions：`macos-14` 与 `macos-15`（如可用）矩阵。
- [ ] 步骤：`swift build`、`swift test`、`UNIVERSAL=1 ./build.sh`、上传 `.app` artifact。
- [ ] 缓存 SwiftPM；失败时保留日志。
- [ ] 可选：快照像素对比（容差 1%）。

### 9.2 签名与公证

- [ ] Developer ID Application 证书；Hardened Runtime；无额外 entitlement。
- [ ] `notarytool submit` + `stapler staple`；验证 `spctl --assess`。
- [ ] 密钥只放 CI Secrets；本地脚本从环境变量读取。
- [ ] README 说明首次启动的 Gatekeeper 行为。

### 9.3 分发

- [ ] `Scripts/release.sh`：版本号校验、universal 构建、DMG（`hdiutil`）、SHA256、GitHub Release。
- [ ] DMG 背景/图标/许可（可选）；至少包含 App 与 README。
- [ ] 可选 Homebrew Cask。

### 9.4 版本与文档

- [ ] `CHANGELOG.md` 按 Keep a Changelog；语义化版本。
- [ ] README 截图：深色默认、浅色、紧凑、电量低。
- [ ] 支持矩阵、隐私、已知问题、构建要求。
- [ ] `docs/` 与 roadmap 勾选同步。

### 9.5 发布前 QA

- [ ] macOS 14 / 15 / 26 / 27；Apple Silicon + Intel（至少各一台）。
- [ ] 干净用户账户首次启动、登录项授权、通知授权。
- [ ] 无外设、1 台、5 台外设；外置盘插拔；VPN 开关；合盖唤醒。
- [ ] 卸载残留检查（UserDefaults、登录项）。
- [ ] 性能复测（M1.10）。

---

## 10. 外设电量技术方案

### 10.1 能力矩阵

| 设备类型 | 首选 API | 备选 | 权限 | 本机验证（2026-11-11） | 结论 |
| --- | --- | --- | --- | --- | --- |
| 妙控鼠标/键盘/触控板 | IORegistry `AppleDeviceManagementHIDEventService` 的 `BatteryPercent` | `system_profiler` | 无 | 无妙控设备，未实机验证 | v1 主路径 |
| 第三方 BLE HID（AULA/HECATE） | 同上 | CoreBluetooth GATT `0x180F/0x2A19` | 蓝牙（GATT） | 已连接，但 IORegistry/`system_profiler` 均无电量 | 预期读不到；M4 spike |
| Xbox/DualSense/DualShock | `GameController` 的 `GCDeviceBattery` | IOKit | 无 | 无手柄，未实机验证 | v1 主路径 |
| AirPods/Beats | 私有 IOBluetooth / GATT | `system_profiler` | 蓝牙 | 未连接，未验证 | M4 研究，默认关闭 |
| iPhone/iPad | MobileDevice 私有 / libimobiledevice | Finder 私有 | USB 信任 | 未验证 | M4 可选 |
| Logitech 等厂商私有 | HID++ / 厂商 SDK | — | 视厂商 | 未验证 | 暂不支持 |

### 10.2 本机探测结论（重要）

在开发机（macOS 27，Apple N1 蓝牙）上：

- 已连接 `AULA F87ProV2D-1`（键盘）与 `HECATE G5M Pro`（鼠标），均为 BLE HID。
- `ioreg -r -c AppleDeviceManagementHIDEventService` 未出现 `BatteryPercent`。
- `system_profiler SPBluetoothDataType -json` 只有地址、类型、服务，没有 battery 字段。
- 因此：**不能承诺所有第三方 BLE 键鼠都能读电量**；v1 必须显示诚实空状态，M4 再尝试 GATT。

复现命令：

```bash
ioreg -r -c AppleDeviceManagementHIDEventService -l | grep -iE 'Product|Battery|Transport'
system_profiler SPBluetoothDataType -json | grep -iE 'battery|device_'
```

### 10.3 数据模型与合并

```swift
PeripheralBattery {
  id: String          // 稳定哈希/序列号，不展示
  name: String
  kind: PeripheralKind
  level: Double?      // 0...1；nil = 未知
  state: BatteryState // charging/discharging/full/unknown
  source: BatterySource
  isConnected: Bool
  lastUpdated: Date
}
```

规则：

- 未知电量不覆盖已知；多来源取“有电量且最新”。
- 过期 > 120 秒标记 stale，UI 提示但保留最后值。
- 低电量仅对放电/未知状态生效，充电中不判低。
- 不持久化设备标识；只在内存中保留最近一次结果。

### 10.4 权限与隐私

- IORegistry / GameController：无额外权限。
- CoreBluetooth：需要 `NSBluetoothAlwaysUsageDescription`，首次使用弹窗；仅 M4 实验功能。
- 通知：`UNUserNotificationCenter` 授权；仅 M5。
- 不读取文件、不访问网络、不上传设备信息。

### 10.5 验证设备清单（建议）

- Apple Magic Mouse / Keyboard / Trackpad 各一。
- Xbox Series 手柄、DualSense 各一。
- AULA F87ProV2D-1、HECATE G5M Pro（本机已有，用于验证“读不到”的降级）。
- AirPods Pro 2、Beats（M4）。
- iPad + USB 线（M4）。

---

## 11. UI 设计规范

### 11.1 布局

- 面板 360 × 648 pt；水平 padding 13；卡片间距 10；卡片圆角 18；卡片内 padding 13。
- 结构：Header → 系统脉搏（2×2 指标）→ 内置存储 → 网络 → 外设电量 → Footer。
- 默认 3 台外设不滚动；超过 3 台列表内部滚动，卡片最大高度约 200 pt。
- 紧凑模式 360 × 560，padding 10，隐藏网络卡片或压缩为一行（二选一，保持一致）。

### 11.2 设计令牌

- 背景：`#16171C → #0B0C0F` 线性渐变 + 左上青色 12% 径向光。
- 卡片：白色 6.5% → 2.8% 渐变 + 白 7% 描边 + 黑色 22% 阴影。
- 强调色：CPU `#4FD3E0`、内存 `#B18CFF`、GPU `#FF6A9C`、温度 `#FFB25C`、磁盘 `#FF9E45`、网络 `#4DDB89`、电量 `#67E8B9`、警告 `#FF6B5E`。
- 文字：主 94% 白、次 56%、三级 32%。
- 字体：数字 26 pt rounded semibold + monospacedDigit；标题 16 pt；正文 12 pt；标签 10.5 pt；说明 9 pt。

### 11.3 状态语义

- 正常：强调色；低电量：警告色 + “低”文字；充电：绿色 + 闪电；未知：三级灰 + “—”。
- 不可用指标：`—`，进度条为空，tooltip 说明原因。
- 过期：保留数值 + “可能过期”提示，不闪红。
- 空状态：图标 + 一句主文案 + 一句解释，不显示假数据。

### 11.4 可访问性

- 对比度：正文 ≥ 4.5:1，大字号 ≥ 3:1。
- 不只靠颜色传达状态。
- VoiceOver：每个设备行合并朗读；按钮有标签；图表有摘要。
- 减少动态效果：关闭脉冲、数字滚动、Popover 动画。
- 键盘：Tab 遍历、Esc 关闭、⌘, 设置。

### 11.5 视觉 QA

- 深浅色各截一张；紧凑模式一张；空状态一张；低电量一张；5 台设备一张。
- 360 pt 宽下所有文本不截断（设备名除外，省略号）。
- 菜单栏在深色/浅色菜单栏、刘海屏、外接显示器下都可读。
- 100% / 125% 缩放（如系统支持）不糊。

---

## 12. 架构与代码约定

- 依赖方向：`PulseBar` → `PulseBarCore`；Core 不依赖 SwiftUI/AppKit。
- UI 状态：`@MainActor` 的 `DashboardStore` / `PeripheralBatteryMonitor`；Core 的采样器通过协议注入。
- 采样：同步、轻量；M1 移到串行后台上下文，结果回主线程。
- 电量：`BatteryProviding` 协议 + `BatteryMerger`；新增来源只加 Provider，不改 UI。
- 设置：`AppPreferences` 是唯一 UserDefaults 入口；键名 `pulsebar.*`。
- 私有 API：独立文件 + `#if`/运行时检查 + 开关 + 文档；禁止在 View 中调用。
- 快照：`--snapshot` 使用 Demo 数据与 `isSnapshot` 环境值；不引入 AppKit 控件。
- 无第三方依赖；不新增网络权限。
- 提交信息：`feat: ...` / `fix: ...` / `docs: ...` / `test: ...`。

---

## 13. 测试计划

### 单元测试（必须）

- `MetricFormatter`：百分比、字节、速率、温度、电量、边界。
- `CPUTickAccumulator`：正常增量、回绕、全 0。
- `RateCalculator`：首样本、正常、回绕、重置、睡眠跨度。
- `HIDBatteryProvider.decode`：Apple/第三方/无电量/重复服务/状态字符串与数字。
- `BatteryMerger`：去重、优先级、未知不覆盖、过期、排序。
- `GameController` 映射纯函数。

### 快照测试（M2）

- 深色默认 / 浅色 / 紧凑 / 空状态 / 低电量 / 5 台设备。
- 像素容差 1%；基准图放 `docs/images/`。

### 手动测试（每个里程碑）

- 设备矩阵（第 10.5 节）。
- 睡眠/唤醒、VPN、外置盘插拔、登录项、通知授权。
- 多显示器/刘海屏、深浅色、减少动态效果。

### 性能测试

- 空闲 10 分钟 CPU、内存；1 秒刷新；面板展开/关闭 50 次。
- 电量轮询 30 秒一次，单次 < 50 ms。

### 兼容性

- macOS 14 / 15 / 26 / 27；Apple Silicon 必测，Intel 至少构建通过。

---

## 14. 发布清单

- [ ] `swift test` 全绿；`./build.sh` 成功；`codesign --verify` 通过。
- [ ] 版本号、`Info.plist`、`CHANGELOG.md` 一致。
- [ ] Universal 2（arm64 + x86_64）验证。
- [ ] Developer ID 签名 + 公证 + staple；`spctl --assess` 通过。
- [ ] DMG 安装、首次启动、登录项、通知。
- [ ] README 截图与支持矩阵更新。
- [ ] 隐私说明：无账户、无网络、无遥测。
- [ ] 许可证与第三方致谢（Pulse 灵感、若移植代码的 MIT 声明）。
- [ ] 回滚方案：保留上一版 DMG 与校验和。

---

## 15. 风险与开放问题

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| CPU 温度私有 API 失效 | 温度不可用 | 运行时检查 + `nil` 降级 + 开关 |
| 第三方 BLE 不暴露电量 | 用户预期落差 | 文案诚实 + 空状态 + M4 GATT 研究 |
| AirPods 私有 API 不稳定 | 崩溃/审核风险 | 默认关闭、隔离、失败返回空 |
| CoreBluetooth 与 HID 冲突 | 连接失败 | 超时、错误提示、不重试风暴 |
| 菜单栏空间不足 | 标签被截断 | 限制宽度、仅图标兜底 |
| macOS 27 SDK 与 14 部署差异 | API 可用性 | CI 多版本；`@available` 检查 |
| 通知打扰 | 用户反感 | 默认关闭、阈值可配、每周期一次 |
| 名称冲突（PulseBar） | 品牌/域名 | 发布前检索；可改 bundle id 与显示名 |

### 开放问题

1. 最终产品名是否就用 PulseBar？（当前工作名，bundle id `com.dvnlandon.pulsebar`）
2. 分发渠道：GitHub Releases 直发，还是同时上 Homebrew？
3. M4 是否值得投入？取决于 GATT spike 能否覆盖本机第三方键鼠。
4. 低电量通知默认开还是关？（PRD 暂定默认关）
5. 是否需要英文优先的国际化，还是中文优先？
6. 是否支持菜单栏多语言/多显示器独立面板？

---

## 16. 完成定义（DoD）

一个任务只有同时满足以下条件才算完成：

- [ ] 代码编译通过，`swift test` 全绿，无新增警告（尽量）。
- [ ] 有对应测试，或写明无法自动测试的原因与手动步骤。
- [ ] UI 在深/浅色、默认/紧凑、空/满状态下验证过（涉及 UI 时）。
- [ ] 性能在预算内（涉及刷新/轮询时）。
- [ ] 读不到的硬件显示“—/未知”，没有伪造或默认 0。
- [ ] 私有 API 有降级、开关、文档标注。
- [ ] `roadmap.md` 勾选、`CHANGELOG.md` 更新、README/文档同步。
- [ ] 提交信息清晰，单个 commit 可回滚。

---

## 17. 建议的迭代顺序（给 Cursor）

1. **M1.1 → M1.3 → M1.7**：先把采样、CPU、内存、网络做扎实。
2. **M1.5 → M1.6**：温度与外置盘，补齐 Pulse 的能力。
3. **M3.1 → M3.4 → M3.6**：电量 v1 稳定后再动 UI 大改。
4. **M2**：UI/主题/紧凑/曲线；此时数据与电量都稳定，返工少。
5. **M4 spike**：先做 GATT，再评估音频/移动设备。
6. **M5 → M6**：提醒、历史、CI、签名、发布。

> 如果时间有限，优先保证 M1 + M3 + M6：指标准确、电量诚实、能签名发布。UI 的浅色/紧凑/曲线可以后补。
