import AppKit
import CMultitouchShim
import Darwin

struct MTFingerSample {
    let id: Int
    let position: CGPoint
    let size: Double
    let majorAxis: Double
    let minorAxis: Double
}

private var activeReader: MultitouchReader?

private let contactCallback: MTShimContactCallback = { _, touches, count, _, _ in
    var samples: [MTFingerSample] = []
    if count > 0, let touches {
        for index in 0..<Int(count) {
            let touch = touches[index]
            guard touch.size > 0.05 else { continue }
            samples.append(
                MTFingerSample(
                    id: Int(touch.fingerID),
                    position: CGPoint(x: CGFloat(touch.normalized.pos.x), y: CGFloat(touch.normalized.pos.y)),
                    size: Double(touch.size),
                    majorAxis: Double(touch.majorAxis),
                    minorAxis: Double(touch.minorAxis)
                )
            )
        }
    }
    DispatchQueue.main.async { activeReader?.publish(samples) }
    return 0
}

final class MultitouchReader {
    static let shared = MultitouchReader()

    private(set) var isAvailable = false
    private(set) var fingers: [MTFingerSample] = []
    var onFrame: (([MTFingerSample]) -> Void)?

    private var library: UnsafeMutableRawPointer?
    private var device: MTShimDeviceRef?
    private var create: MTShimCreateDefaultFn?
    private var register: MTShimRegisterContactFrameCallbackFn?
    private var startDevice: MTShimDeviceStartFn?
    private var stopDevice: MTShimDeviceStopFn?
    private var releaseDevice: MTShimDeviceReleaseFn?

    private init() {}

    func start() {
        guard device == nil, loadAPI(), let create, let register, let startDevice, let newDevice = create() else { return }
        device = newDevice
        activeReader = self
        register(newDevice, contactCallback)
        startDevice(newDevice, 0)
        isAvailable = true
    }

    func stop() {
        activeReader = nil
        isAvailable = false
        if let device {
            stopDevice?(device)
            releaseDevice?(device)
        }
        device = nil
    }

    fileprivate func publish(_ samples: [MTFingerSample]) {
        fingers = samples
        onFrame?(samples)
    }

    private func loadAPI() -> Bool {
        if library != nil { return create != nil && register != nil && startDevice != nil }
        let path = "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport"
        guard let handle = dlopen(path, RTLD_NOW) else { return false }
        library = handle
        create = symbol("MTDeviceCreateDefault", handle)
        register = symbol("MTRegisterContactFrameCallback", handle)
        startDevice = symbol("MTDeviceStart", handle)
        stopDevice = symbol("MTDeviceStop", handle)
        releaseDevice = symbol("MTDeviceRelease", handle)
        return create != nil && register != nil && startDevice != nil
    }

    private func symbol<T>(_ name: String, _ handle: UnsafeMutableRawPointer) -> T? {
        guard let pointer = dlsym(handle, name) else { return nil }
        return unsafeBitCast(pointer, to: T.self)
    }
}
