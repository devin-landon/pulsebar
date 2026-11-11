# 外设电量调研（PulseBar）

- 日期：2026-11-11
- 机器：MacBook Pro 14-inch（M6），macOS 27.0（26A8425），蓝牙芯片 Apple N1
- 目的：确定 macOS 上可稳定读取哪些外设电量，以及 v1 的边界
- 相关：`roadmap.md` M3/M4、`Sources/PulseBarCore/Battery/`

## 1. 结论先行

1. **v1 只承诺系统能读到的电量**：
   - Apple HID（妙控系列）走 IORegistry 的 `BatteryPercent`；
   - 游戏手柄走 `GameController` 的 `GCDeviceBattery`。
2. **第三方 BLE 键鼠不保证**。开发机上的 AULA F87ProV2D-1（键盘）与 HECATE G5M Pro（鼠标）虽然已连接，但 macOS 没有暴露 `BatteryPercent`，`system_profiler` 也没有 battery 字段。
3. **AirPods / iPhone / iPad 电量**需要私有框架或额外权限，放入 M4 研究，默认关闭；v1 不显示半成品入口。
4. 任何读不到的情况都显示“—”/未知，不伪造 0%。

## 2. 本机探测记录

### 2.1 设备

| 设备 | 类型 | 连接 | 备注 |
| --- | --- | --- | --- |
| AULA F87ProV2D-1 | 键盘 | BLE HID | 已连接 |
| HECATE G5M Pro | 鼠标 | BLE HID | 已连接 |
| Devin's iPad Air 3 | 平板 | 未连接 | 仅用于后续 M4 |
| Galaxy Buds2 Pro | 耳机 | 未连接 | 非 Apple 音频 |

### 2.2 命令与结果

```bash
ioreg -r -c AppleDeviceManagementHIDEventService -l | grep -iE 'Product|Battery|Transport'
```

结果：只有内建键盘/触控板服务，`Product = "Apple Internal Keyboard / Trackpad"`、`Transport = "FIFO"`，**没有 `BatteryPercent` / `BatteryStatus`**。

```bash
ioreg -l -w0 | grep -iE 'battery(percent|status|level)'
```

结果：无匹配。

```bash
system_profiler SPBluetoothDataType -json | grep -iE 'battery|device_'
```

结果：`device_connected` 中 AULA/HECATE 只有 `device_address`、`device_minorType`、`device_productID`、`device_services`、`device_vendorID`，**没有 battery 字段**。

```bash
system_profiler SPBluetoothDataType
```

结果：已连接设备显示 Minor Type: Keyboard / Mouse、Services: `0x400020 < HID BLE >`，没有电量。

### 2.3 解释

可能原因（按可能性排序）：

1. 设备通过厂商私有协议（如 Logitech HID++、Keychron 私有报文）上报电量，macOS 不解析。
2. 设备实现的是 HID Battery Strength（Usage Page 0x06 / Usage 0x20）但 macOS 只对部分 Apple 设备发布 `BatteryPercent`。
3. 设备支持 GATT Battery Service（0x180F），但 macOS 的 HID 栈不与 CoreBluetooth 共享该属性。

这解释了为什么“蓝牙设置里能看到设备，但系统不显示电量”。PulseBar 不能凭空读取，只能尝试 GATT/厂商协议。

## 3. 能力矩阵

| 设备类型 | 首选 | 备选 | 权限 | 现状 | 计划 |
| --- | --- | --- | --- | --- | --- |
| 妙控鼠标/键盘/触控板 | IORegistry `AppleDeviceManagementHIDEventService.BatteryPercent` | `IOHIDDevice`、`system_profiler` | 无 | 代码已实现，待实机验证 | M3.1 |
| Xbox/DualSense/DualShock | `GameController.GCDeviceBattery` | IOKit | 无 | 代码已实现，待实机验证 | M3.3 |
| 第三方 BLE HID | 同上 | CoreBluetooth GATT 0x180F/0x2A19 | 蓝牙 | 本机读不到 | M4.1 |
| AirPods/Beats | 私有 IOBluetooth / GATT | `system_profiler` | 蓝牙 | 未验证 | M4.2 |
| iPhone/iPad | MobileDevice 私有 / libimobiledevice | USB 系统报告 | USB 信任 | 未验证 | M4.3（可选） |
| Logitech 等厂商私有 | HID++ / 厂商 SDK | — | 视厂商 | 不支持 | 评估后决定 |

## 4. v1 实现（已完成的部分）

### 4.1 HID Provider

`Sources/PulseBarCore/Battery/HIDBatteryProvider.swift`

- 匹配 `AppleDeviceManagementHIDEventService`；
- 读取属性字典中的 `BatteryPercent`（0–100）、`BatteryStatus`、`Product`、`SerialNumber`、`PrimaryUsagePage`、`PrimaryUsage`；
- 无 `BatteryPercent` 直接跳过；内建设备（名称含 `Internal`）跳过；
- 按序列号或名称生成稳定 ID；
- 纯解码函数 `decode(properties:)` 可单测。

待验证：真实妙控设备上 `BatteryStatus` 的取值形式（字符串还是数字）与 `BatteryPercent` 的范围。

### 4.2 GameController Provider

`Sources/PulseBarCore/Battery/GameControllerBatteryProvider.swift`

- `GCController.controllers()` → `controller.battery`；
- `batteryLevel < 0` → `nil`；
- `batteryState` 映射 charging/discharging/full/unknown；
- 多手柄用 vendor + productCategory + index 区分。

待验证：Xbox Series、DualSense 在蓝牙/USB 下的 `batteryLevel` 精度与连接事件。

### 4.3 合并与展示

- `BatteryMerger`：按 ID 去重，未知不覆盖已知；
- 低电量 ≤20%，充电中不判低；
- 未知显示“—”，空状态说明“部分第三方设备不公开电量”。

## 5. M4 研究计划

### 5.1 CoreBluetooth GATT（优先级最高）

目标：验证第三方 BLE 键鼠是否暴露 Battery Service。

步骤：

1. 增加 `NSBluetoothAlwaysUsageDescription`；
2. 实验开关默认关闭；
3. `CBCentralManager` 扫描 `CBUUID(string: "180F")`；
4. 连接后 `discoverServices([0x180F])`，再 `discoverCharacteristics([0x2A19])`；
5. `readValue(for:)`，按 `UInt8` 解析 0–100；
6. 5 秒超时、失败重试 1 次、完成后断开；结果缓存 5 分钟；
7. 与 HID 结果按设备名/地址哈希合并，避免重复行。

代码草图（仅示意）：

```swift
let batteryService = CBUUID(string: "180F")
let batteryLevel = CBUUID(string: "2A19")

central.scanForPeripherals(withServices: [batteryService], options: nil)

func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let service = peripheral.services?.first(where: { $0.uuid == batteryService }) else { return }
    peripheral.discoverCharacteristics([batteryLevel], for: service)
}

func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard let characteristic = service.characteristics?.first(where: { $0.uuid == batteryLevel }) else { return }
    peripheral.readValue(for: characteristic)
}
```

风险：

- 系统已把 BLE HID 设备作为 HID 连接，CoreBluetooth 可能无法同时连接；
- 设备可能不广播 0x180F，扫描不到；
- 首次授权弹窗会打断用户；必须由用户主动开启实验功能。

验收：本机 AULA/HECATE 至少一个能读到；若都不能，记录“设备不暴露 GATT 电量”的结论，关闭该实验功能。

### 5.2 蓝牙音频（AirPods / Beats）

候选路径：

1. **CoreBluetooth GATT**：AirPods 是否暴露 0x180F？需要实测；即使暴露，左右耳/充电盒可能不在标准服务里。
2. **`system_profiler SPBluetoothDataType -json`**：部分设备/系统版本可能出现 battery 字段；本机 HID 键鼠没有。可做只读 fallback，但解析要容错。
3. **私有 `IOBluetoothDevice`**：通过 Objective-C runtime 检查 `batteryPercent` 等 selector；不同 macOS 版本差异大。只在存在 selector 时调用，失败返回空。

约束：

- 默认关闭，设置中标注“实验性”；
- 独立文件 `AudioBatteryProvider.swift`；
- 不因 KVC/selector 缺失崩溃；
- 至少验证 AirPods Pro 2 与一款 Beats；记录 macOS 版本。

### 5.3 iPhone / iPad（可选）

- 私有 `MobileDevice.framework` 可读 `BatteryCurrentCapacity`，但需要 USB 信任、私有符号、可能受 SIP/公证影响；
- `libimobiledevice` 是外部依赖，违背“无第三方运行库”，只能作为开发期验证工具，不能直接打包；
- 结论：除非有强需求，暂不实现；不留下伪入口。

### 5.4 厂商协议（评估即可）

- Logitech HID++、Razer Synapse、Keychron 等需要厂商协议/SDK；
- 维护成本高，设备覆盖有限；
- 结论：不进入 v1/v2，除非用户明确要求并愿意接受实验性。

## 6. 权限与隐私

| 能力 | 权限 | 说明 |
| --- | --- | --- |
| IORegistry HID | 无 | 只读系统属性 |
| GameController | 无 | 公开框架 |
| CoreBluetooth | `NSBluetoothAlwaysUsageDescription` + 用户授权 | 仅 M4 实验开关开启时 |
| 通知 | `UNUserNotificationCenter` 授权 | 仅 M5 |
| iPhone 电量 | USB 信任 | 仅 M4 可选，不持久化 UDID |

隐私：

- 设备 ID 只在内存中使用；不持久化 MAC/序列号/UDID；
- 不上传设备列表或电量；
- 诊断日志脱敏（M1.9/M5.4）。

## 7. 手动验证记录（待填）

| 日期 | 设备 | 系统 | 结果 | 备注 |
| --- | --- | --- | --- | --- |
| 2026-11-11 | AULA F87ProV2D-1 | macOS 27 | ❌ 无 `BatteryPercent` | 已连接，BLE HID |
| 2026-11-11 | HECATE G5M Pro | macOS 27 | ❌ 无 `BatteryPercent` | 已连接，BLE HID |
| 待测 | Magic Mouse | macOS 14/15 | — | 预期 IORegistry 有值 |
| 待测 | Magic Keyboard | macOS 14/15 | — | 预期 IORegistry 有值 |
| 待测 | Magic Trackpad | macOS 14/15 | — | 预期 IORegistry 有值 |
| 待测 | Xbox Series 手柄 | macOS 14/15 | — | 预期 GameController 有值 |
| 待测 | DualSense | macOS 14/15 | — | 预期 GameController 有值 |
| 待测 | AirPods Pro 2 | macOS 14/15 | — | M4 |
| 待测 | iPad Air 3 | macOS 14/15 | — | M4 可选 |

## 8. 参考

- Pulse（MIT）：<https://github.com/einsy1/pulse> — CPU 温度私有 HID 读取思路、菜单栏交互参考。
- Apple Developer：GameController `GCDeviceBattery`、CoreBluetooth、ServiceManagement。
- Bluetooth SIG：Battery Service `0x180F`、Battery Level `0x2A19`。
- HID Usage Tables：Battery Strength（Usage Page 0x06, Usage 0x20）。
- `system_profiler SPBluetoothDataType` 输出格式随 macOS 版本变化，解析需容错。

## 9. 决策日志

| 日期 | 决策 | 理由 |
| --- | --- | --- |
| 2026-11-11 | v1 只做 HID + GameController | 公开 API、无权限、可测试 |
| 2026-11-11 | 第三方 BLE 空状态明确说明 | 本机实测读不到，不能承诺 |
| 2026-11-11 | AirPods/iPhone 推迟到 M4 | 私有 API/权限风险高，不阻塞 v1 |
| 2026-11-11 | GATT 先于音频私有 API | 公开框架、可控、可关闭 |
