# AGENTS.md — PulseBar 开发约定

本文件面向接手开发的 AI/工程师。开始任何任务前，先读本文件与 `roadmap.md` 的当前里程碑。

## 1. 项目一句话

PulseBar 是常驻 macOS 菜单栏的「系统状态 + 外设电量」面板；SwiftUI + AppKit，无第三方依赖，所有读数只在本机。

当前阶段：**M0 框架完成**，后续按 `roadmap.md` 推进。

## 2. 构建与测试

```bash
swift build
swift test
./build.sh                 # 生成 PulseBar.app（ad hoc 签名）
open PulseBar.app
PULSEBAR_DEMO=1 swift run PulseBar
swift run PulseBar --snapshot docs/images/dashboard.png
```

受限环境（容器/CI）中 SwiftPM 自身沙盒或模块缓存不可写时：

```bash
PULSEBAR_LOCAL_CACHES=1 PULSEBAR_DISABLE_SANDBOX=1 ./build.sh
```

要求：macOS 14+，Xcode 16+（或匹配的 CLT + macOS SDK）。

## 3. 目录与边界

```text
Sources/PulseBarCore/      纯逻辑：模型、采样、电量、格式化
Sources/PulseBar/          AppKit 菜单栏 + SwiftUI UI
Tests/PulseBarCoreTests/   Core 单元测试
docs/                      架构、电量调研、截图
```

依赖方向：`PulseBar` → `PulseBarCore`。**Core 不允许 import SwiftUI/AppKit**。

| 层 | 职责 | 不应该做 |
| --- | --- | --- |
| Core | 采样、解析、合并、格式化 | 弹窗、读 UserDefaults、操作 NSStatusItem |
| App | 菜单栏、窗口、主题、交互 | 直接解析 IORegistry 原始字典 |
| Docs | 决策与验收记录 | 过期但未标注 |

## 4. 代码约定

- Swift 5 语言模式（`Package.swift` 中 `swiftLanguageModes: [.v5]`），工具链 Swift 6。
- UI/Store/Monitor 用 `@MainActor`；Core 采样器保持同步、可注入。
- 新增数据源：实现 `BatteryProviding`，在 `AppDelegate` 注入，不要改 UI。
- 新增指标：扩展 `SystemSnapshot` + `SystemMetricsProvider`，UI 只读快照。
- 设置只通过 `AppPreferences` 读写 `UserDefaults`，键名 `pulsebar.*`。
- 不引入第三方依赖；不新增网络请求/遥测。
- 命名：类型 PascalCase，方法/属性 camelCase；中文仅用于用户可见文案。
- 提交信息：`feat:` / `fix:` / `docs:` / `test:` / `chore:`，一条 commit 做一件事。

## 5. 产品底线

1. **不伪造数据**：读不到 → `nil` / “—”，不能显示 0%。
2. **设备电量未知 ≠ 0%**；充电中不判低电量。
3. **私有 API 必须**：独立文件、运行时检查、功能开关、失败降级、文档标注。
4. **默认无权限**：IORegistry/GameController 不需要权限；CoreBluetooth/通知仅在对应实验功能开启时请求。
5. **隐私**：不持久化序列号/MAC/UDID；不发起网络请求。

## 6. 私有 API 政策

- CPU 温度、AirPods 电量等可能需要私有符号。允许使用，但必须：
  - 放在单独文件（如 `TemperatureSampler.swift`），UI 不直接调用；
  - 用 `dlopen`/`dlsym` 或 Objective-C runtime，符号缺失返回 `nil`；
  - 设置中提供关闭开关；
  - 文件头注明来源与 MIT/许可；
  - 在 `docs/battery-research.md` 记录系统版本与失效风险。
- 不使用私有 API 实现 App Store 版本；本项目仅直接分发。

## 7. 每个任务的流程

1. 在 `roadmap.md` 找到当前里程碑第一个未勾选任务。
2. 列出 3–6 步计划（改哪些文件、加哪些测试）。
3. 能测的先写失败测试（`swift test` 红）。
4. 实现，保持小步；必要时加 `#if DEBUG` 的演示数据。
5. `swift build` + `swift test` + `./build.sh`。
6. 涉及 UI：用 `--snapshot` 生成截图，检查深色/默认/空状态。
7. 更新 `roadmap.md` 复选框、`CHANGELOG.md`、相关文档。
8. 提交；不要顺手做其他里程碑。

## 8. 测试要求

- Core 逻辑必须有单测：格式化、tick/速率计算、HID 解码、合并/过期/排序。
- 硬件相关无法自动测时，在 `docs/battery-research.md` 记录手动步骤与结果。
- 快照测试（M2 起）：默认/浅色/紧凑/空/低电量/多设备，容差 1%。
- 性能预算：空闲 CPU < 0.5%，常驻内存 < 100 MB，面板打开 < 100 ms。

## 9. 已知环境问题

- 在受限沙盒中 `swift build` 可能报 `sandbox-exec: sandbox_apply: Operation not permitted` 或模块缓存不可写：使用第 2 节的 `PULSEBAR_*` 环境变量，或手动 `swift build --disable-sandbox` + 本地缓存。
- `PULSEBAR_DEMO=1` 仅用于 UI 开发；不要把它当作真实数据来源。
- 菜单栏 App 用 `swift run` 启动后没有 Dock 图标，右键菜单退出。

## 10. 当前技术债（按 roadmap 处理）

- 采样在主线程（M1.1）。
- CPU 温度占位（M1.5）。
- 无外置磁盘（M1.6）。
- 32 位网络计数（M1.7）。
- 仅深色主题、无本地化（M2）。
- 第三方 BLE / AirPods / iPhone 未支持（M3/M4）。
- 无 CI/公证（M6）。

## 11. 不要做

- 不要为了“看起来完整”而伪造温度、GPU、电量读数。
- 不要在 View 里做 IOKit/CoreBluetooth 调用。
- 不要把序列号、MAC、UDID 写进日志或 UserDefaults。
- 不要绕过 `AppPreferences` 直接写 UserDefaults。
- 不要在没有测试/手动验证的情况下宣称某个设备“支持”。

## 12. 完成定义

任务完成需同时满足：编译通过、测试通过、UI 状态验证、性能在预算内、文档/路线图更新、提交可回滚。详见 `roadmap.md` 第 16 节。
