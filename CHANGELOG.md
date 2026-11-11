# Changelog

## 0.1.0 — 2026-11-11

首个可运行框架（M0）：

- SwiftPM 工程：`PulseBarCore`（指标 / 电量 / 格式化）+ `PulseBar`（菜单栏 App）。
- 菜单栏常驻、左键面板、右键菜单、设置窗口、登录时启动。
- 真实采样：CPU、内存、内置存储、网络速率；GPU 读取器（按机型可能不可用）。
- 外设电量：HID（IORegistry）与 GameController 两个数据源，合并、去重、30 秒轮询。
- 深色 Dashboard 与设置页设计系统；低电量/充电状态；空状态。
- `--snapshot` 离屏渲染、`PULSEBAR_DEMO=1` 演示模式。
- 13 个单元测试；ad hoc 签名的 `.app` 构建脚本；应用图标。
- 文档：README、PRD、roadmap、架构、外设电量调研、AGENTS。

已知限制：CPU 温度占位；未支持外置卷；AirPods/iPhone 电量未实现；第三方 BLE 设备电量取决于系统是否暴露。
