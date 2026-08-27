import SwiftUI
import UIKit

enum ReceiptCameraFlashMode: CaseIterable, Equatable, Sendable {
    case automatic
    case on
    case off

    var localizedKey: LocalizedStringKey {
        switch self {
        case .automatic: "receipt.camera.flash.auto"
        case .on: "receipt.camera.flash.on"
        case .off: "receipt.camera.flash.off"
        }
    }

    var systemImage: String {
        switch self {
        case .automatic: "bolt.badge.a.fill"
        case .on: "bolt.fill"
        case .off: "bolt.slash.fill"
        }
    }

    mutating func advance() {
        self = switch self {
        case .automatic: .on
        case .on: .off
        case .off: .automatic
        }
    }
}

struct ReceiptCaptureOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var flashMode: ReceiptCameraFlashMode
    let isCapturing: Bool
    let capture: () -> Void
    let choosePhoto: () -> Void
    let cancel: () -> Void

    @State private var breathes = false
    @State private var localCaptureFeedback = false
    @State private var flashOpacity = 0.0

    private var controlsDisabled: Bool { isCapturing || localCaptureFeedback }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ReceiptCameraVignette()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ReceiptCornerBrackets()
                    .stroke(
                        Color.white.opacity(reduceMotion ? 0.92 : (breathes ? 0.62 : 0.92)),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .frame(
                        width: max(200, proxy.size.width - 68),
                        height: min(344, max(250, proxy.size.height * 0.43))
                    )
                    .position(x: proxy.size.width / 2, y: min(322, proxy.size.height * 0.39))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    topControls
                        .padding(.horizontal, 16)
                        .padding(.top, 6)

                    Spacer()

                    guide
                        .padding(.horizontal, 28)
                        .padding(.bottom, 26)

                    bottomControls
                        .padding(.horizontal, 28)
                        .padding(.bottom, 34)
                }
                .opacity(controlsDisabled ? 0.35 : 1)
                .allowsHitTesting(!controlsDisabled)

                Color.white
                    .opacity(flashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    breathes = true
                }
            }
            .onChange(of: isCapturing) { _, capturing in
                if !capturing {
                    localCaptureFeedback = false
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topControls: some View {
        HStack(alignment: .top) {
            glassIconButton(
                systemImage: "xmark",
                accessibilityLabel: "common.close",
                action: cancel
            )

            Spacer(minLength: 10)

            Label("receipt.localOnly.title", systemImage: "lock.shield.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .frame(minHeight: 32)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1) }
                .accessibilityIdentifier("receipt.camera.localOnly")

            Spacer(minLength: 10)

            Button {
                flashMode.advance()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: flashMode.systemImage)
                        .font(.system(size: 16, weight: .semibold))
                    Text(flashMode.localizedKey)
                        .font(.system(size: 8, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(flashMode == .on ? Color.black.opacity(0.78) : .white)
                .frame(width: 44, height: 44)
                .background {
                    if flashMode == .on {
                        Circle().fill(Color.white.opacity(0.92))
                    } else {
                        Circle().fill(.ultraThinMaterial)
                    }
                }
                .overlay { Circle().stroke(Color.white.opacity(0.16), lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(flashMode.localizedKey)
            .accessibilityIdentifier("receipt.camera.flash")
        }
    }

    private var guide: some View {
        VStack(spacing: 8) {
            Text(isCapturing ? "receipt.camera.capturing" : "receipt.camera.guide.searching")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1) }

            if !isCapturing {
                Text("receipt.camera.guide.searching.detail")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(
            isCapturing
                ? Text("receipt.camera.capturing")
                : Text("receipt.camera.guide.searching")
        )
        .accessibilityIdentifier("receipt.camera.guide")
    }

    @ViewBuilder
    private var bottomControls: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 16) {
                shutterButton
                HStack(spacing: 56) {
                    photosButton
                    longReceiptPlaceholder
                }
            }
        } else {
            HStack {
                photosButton
                Spacer()
                shutterButton
                Spacer()
                longReceiptPlaceholder
            }
        }
    }

    private var photosButton: some View {
        Button(action: choosePhoto) {
            VStack(spacing: 5) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 21, weight: .semibold))
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                    }
                Text("receipt.camera.library")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(minWidth: 60, minHeight: 70)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("receipt.camera.photos")
    }

    private var shutterButton: some View {
        Button(action: triggerCapture) {
            Circle()
                .fill(Color.white)
                .frame(width: 60, height: 60)
                .padding(6)
                .overlay { Circle().stroke(Color.white, lineWidth: 3.5) }
                .shadow(color: Color.black.opacity(0.35), radius: 12, y: 2)
                .scaleEffect(localCaptureFeedback && !reduceMotion ? 0.9 : 1)
                .frame(width: 72, height: 72)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("receipt.camera.capture")
        .accessibilityIdentifier("receipt.camera.capture")
    }

    /// Section stitching has no reviewed interaction design yet. Keep the visual slot so the
    /// camera hierarchy is stable, but do not expose a false capture affordance.
    private var longReceiptPlaceholder: some View {
        VStack(spacing: 5) {
            Image(systemName: "rectangle.split.2x1")
                .font(.system(size: 21, weight: .semibold))
                .frame(width: 52, height: 52)
                .background(.ultraThinMaterial, in: Circle())
                .overlay { Circle().stroke(Color.white.opacity(0.16), lineWidth: 1) }
            Text("receipt.camera.long")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Color.white.opacity(0.48))
        .frame(minWidth: 60, minHeight: 70)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("receipt.camera.long")
        .accessibilityHint("receipt.camera.long.unavailable")
        .accessibilityAddTraits(.isStaticText)
        .accessibilityIdentifier("receipt.camera.long")
    }

    private func glassIconButton(
        systemImage: String,
        accessibilityLabel: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay { Circle().stroke(Color.white.opacity(0.16), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func triggerCapture() {
        guard !controlsDisabled else { return }
        localCaptureFeedback = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if reduceMotion {
            flashOpacity = 0.16
            withAnimation(.easeOut(duration: 0.08)) { flashOpacity = 0 }
        } else {
            withAnimation(.easeOut(duration: 0.12)) {
                flashOpacity = 0.55
            }
            withAnimation(.easeOut(duration: 0.12).delay(0.02)) {
                flashOpacity = 0
            }
            withAnimation(.spring(duration: 0.12, bounce: 0)) {
                localCaptureFeedback = true
            }
        }
        capture()
    }
}

private struct ReceiptCameraVignette: View {
    var body: some View {
        RadialGradient(
            colors: [.clear, Color.black.opacity(0.12), Color.black.opacity(0.78)],
            center: UnitPoint(x: 0.5, y: 0.46),
            startRadius: 80,
            endRadius: 520
        )
    }
}

private struct ReceiptCornerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(34, min(rect.width, rect.height) * 0.16)
        let radius: CGFloat = 8
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        return path
    }
}
