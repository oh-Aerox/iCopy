import Carbon
import Foundation

/// Carbon hotkeys work without Accessibility permission, which keeps first-run setup small.
final class HotKeyMonitor {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func register(onPress: @escaping () -> Void) {
        HotKeyRuntime.onPress = onPress

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &spec,
            nil,
            &handlerRef
        )
        guard status == noErr else {
            AppLog.error("hotkey.handler_failed", ["status": String(status)])
            return
        }

        let hotKeyID = EventHotKeyID(signature: HotKeyConfig.carbonSignature, id: 1)
        let registerStatus = RegisterEventHotKey(
            HotKeyConfig.carbonKeyCode,
            HotKeyConfig.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if registerStatus == noErr {
            AppLog.info("hotkey.registered", ["chord": HotKeyConfig.displaySymbol])
        } else {
            AppLog.error("hotkey.register_failed", ["status": String(registerStatus)])
        }
    }
}

private enum HotKeyRuntime {
    nonisolated(unsafe) static var onPress: (() -> Void)?
}

private func hotKeyEventHandler(
    _: EventHandlerCallRef?,
    _: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    DispatchQueue.main.async {
        HotKeyRuntime.onPress?()
    }
    return noErr
}
