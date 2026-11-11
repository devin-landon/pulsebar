import Foundation

public enum PeripheralKind: String, Sendable, CaseIterable {
    case mouse
    case keyboard
    case trackpad
    case gamepad
    case headphones
    case phone
    case tablet
    case other

    public var displayName: String {
        switch self {
        case .mouse: return "鼠标"
        case .keyboard: return "键盘"
        case .trackpad: return "触控板"
        case .gamepad: return "游戏手柄"
        case .headphones: return "耳机"
        case .phone: return "iPhone"
        case .tablet: return "iPad"
        case .other: return "外设"
        }
    }

    public var symbolName: String {
        switch self {
        case .mouse: return "computermouse"
        case .keyboard: return "keyboard"
        case .trackpad: return "hand.point.up.left"
        case .gamepad: return "gamecontroller"
        case .headphones: return "headphones"
        case .phone: return "iphone"
        case .tablet: return "ipad"
        case .other: return "dot.radiowaves.left.and.right"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .mouse: return 0
        case .keyboard: return 1
        case .trackpad: return 2
        case .gamepad: return 3
        case .headphones: return 4
        case .phone: return 5
        case .tablet: return 6
        case .other: return 7
        }
    }
}

public enum BatteryState: String, Sendable {
    case charging
    case discharging
    case full
    case unknown

    public var displayName: String {
        switch self {
        case .charging: return "充电中"
        case .discharging: return "使用中"
        case .full: return "已充满"
        case .unknown: return "状态未知"
        }
    }
}

public enum BatterySource: String, Sendable {
    case hid
    case gameController
    case bluetoothAudio
    case systemProfiler
    case mobileDevice

    public var displayName: String {
        switch self {
        case .hid: return "HID"
        case .gameController: return "手柄"
        case .bluetoothAudio: return "蓝牙音频"
        case .systemProfiler: return "系统报告"
        case .mobileDevice: return "移动设备"
        }
    }
}

/// A peripheral that can report its battery level.
///
/// `level == nil` means the device is visible but macOS does not expose a
/// battery reading. The UI must show it as unknown instead of inventing 0%.
public struct PeripheralBattery: Identifiable, Sendable, Equatable {
    public let id: String
    public var name: String
    public var kind: PeripheralKind
    public var level: Double?
    public var state: BatteryState
    public var source: BatterySource
    public var isConnected: Bool
    public var lastUpdated: Date

    public init(
        id: String,
        name: String,
        kind: PeripheralKind,
        level: Double?,
        state: BatteryState = .unknown,
        source: BatterySource,
        isConnected: Bool = true,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.level = level.map { min(max($0, 0), 1) }
        self.state = state
        self.source = source
        self.isConnected = isConnected
        self.lastUpdated = lastUpdated
    }

    public var isLow: Bool {
        guard let level, state != .charging, state != .full else { return false }
        return level <= 0.2
    }

    public var isCritical: Bool {
        guard let level, state != .charging, state != .full else { return false }
        return level <= 0.1
    }
}
