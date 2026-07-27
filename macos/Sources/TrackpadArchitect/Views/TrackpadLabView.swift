import SwiftUI

struct TrackpadLabView: View {
    @State private var fingers: [MTFingerSample] = []
    @State private var timer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Trackpad Lab")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("A live instrument panel for your trackpad.")
                    .foregroundStyle(.secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(red: 0.985, green: 0.98, blue: 0.94))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.primary.opacity(0.18), lineWidth: 1.5)
                    }
                ForEach(fingers, id: \.id) { finger in
                    Circle()
                        .fill(Color(red: 0.37, green: 0.30, blue: 0.88).opacity(0.78))
                        .frame(
                            width: max(18, finger.majorAxis * 5),
                            height: max(18, finger.minorAxis * 5)
                        )
                        .position(
                            x: 30 + finger.position.x * 620,
                            y: 280 - finger.position.y * 230
                        )
                        .overlay {
                            Text("\(finger.id)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.white)
                        }
                }
            }
            .frame(width: 680, height: 310)
            .accessibilityLabel("Live trackpad touch surface")

            HStack(spacing: 24) {
                Metric(title: "Touches", value: "\(fingers.count)")
                Metric(
                    title: "Average force",
                    value: fingers.isEmpty
                        ? "—"
                        : String(format: "%.2f", fingers.map(\.size).reduce(0, +) / Double(fingers.count))
                )
                Metric(
                    title: "Raw multitouch",
                    value: MultitouchReader.shared.isAvailable ? "Available" : "Fallback"
                )
            }

            Text("Tip: touch with one finger to draw immediately. Two fingers pan and pinch the canvas.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(minWidth: 740, minHeight: 480)
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1 / 30, repeats: true) { _ in
                fingers = MultitouchReader.shared.fingers
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

private struct Metric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospaced().weight(.semibold))
        }
    }
}
