import Foundation
import SwiftUI

enum AppSkin: String, CaseIterable, Codable, Equatable, Sendable {
    case auroraGlow
    case warmBotanical
    case neonPulse

    static let defaultSkin = AppSkin.warmBotanical

    var nameLocalizationKey: String {
        switch self {
        case .auroraGlow: "settings.appearance.skin.auroraGlow"
        case .warmBotanical: "settings.appearance.skin.warmBotanical"
        case .neonPulse: "settings.appearance.skin.neonPulse"
        }
    }

    var descriptionLocalizationKey: String {
        switch self {
        case .auroraGlow: "settings.appearance.skin.auroraGlow.description"
        case .warmBotanical: "settings.appearance.skin.warmBotanical.description"
        case .neonPulse: "settings.appearance.skin.neonPulse.description"
        }
    }

    var localizedNameKey: LocalizedStringKey {
        LocalizedStringKey(nameLocalizationKey)
    }

    var localizedDescriptionKey: LocalizedStringKey {
        LocalizedStringKey(descriptionLocalizationKey)
    }

    var symbolName: String {
        switch self {
        case .auroraGlow: "wind"
        case .warmBotanical: "leaf"
        case .neonPulse: "sparkles"
        }
    }

    var backgroundAssetName: String {
        switch self {
        case .auroraGlow: "AuroraGlowBackground"
        case .warmBotanical: "WarmBotanicalBackground"
        case .neonPulse: "NeonPulseBackground"
        }
    }
}

struct MindBudgetTheme: Sendable {
    let skin: AppSkin

    static let fallback = MindBudgetTheme(skin: .defaultSkin)

    var preferredColorScheme: ColorScheme {
        skin == .warmBotanical ? .light : .dark
    }

    var canvas: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.012, green: 0.075, blue: 0.090)
        case .warmBotanical: Color(red: 0.984, green: 0.965, blue: 0.925)
        case .neonPulse: Color(red: 0.018, green: 0.018, blue: 0.105)
        }
    }

    var surface: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.035, green: 0.145, blue: 0.155)
        case .warmBotanical: Color(red: 1.000, green: 0.992, blue: 0.972)
        case .neonPulse: Color(red: 0.060, green: 0.055, blue: 0.215)
        }
    }

    var ink: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.950, green: 1.000, blue: 0.990)
        case .warmBotanical: Color(red: 0.235, green: 0.180, blue: 0.145)
        case .neonPulse: Color(red: 0.975, green: 0.965, blue: 1.000)
        }
    }

    var inkSecondary: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.710, green: 0.825, blue: 0.805)
        case .warmBotanical: Color(red: 0.490, green: 0.420, blue: 0.365)
        case .neonPulse: Color(red: 0.710, green: 0.680, blue: 0.860)
        }
    }

    var inkTertiary: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.545, green: 0.665, blue: 0.650)
        case .warmBotanical: Color(red: 0.455, green: 0.405, blue: 0.365)
        case .neonPulse: Color(red: 0.560, green: 0.525, blue: 0.725)
        }
    }

    var inkQuaternary: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.390, green: 0.500, blue: 0.490)
        case .warmBotanical: Color(red: 0.650, green: 0.600, blue: 0.550)
        case .neonPulse: Color(red: 0.390, green: 0.360, blue: 0.545)
        }
    }

    var hairline: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.110, green: 0.285, blue: 0.290)
        case .warmBotanical: Color(red: 0.905, green: 0.865, blue: 0.810)
        case .neonPulse: Color(red: 0.190, green: 0.160, blue: 0.405)
        }
    }

    var hairlineStrong: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.205, green: 0.440, blue: 0.435)
        case .warmBotanical: Color(red: 0.835, green: 0.785, blue: 0.720)
        case .neonPulse: Color(red: 0.405, green: 0.285, blue: 0.685)
        }
    }

    var track: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.105, green: 0.220, blue: 0.230)
        case .warmBotanical: Color(red: 0.930, green: 0.905, blue: 0.855)
        case .neonPulse: Color(red: 0.135, green: 0.120, blue: 0.310)
        }
    }

    var accent: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.425, green: 0.900, blue: 0.820)
        case .warmBotanical: Color(red: 0.450, green: 0.610, blue: 0.455)
        case .neonPulse: Color(red: 0.605, green: 0.355, blue: 1.000)
        }
    }

    var accentSoft: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.070, green: 0.245, blue: 0.235)
        case .warmBotanical: Color(red: 0.895, green: 0.935, blue: 0.875)
        case .neonPulse: Color(red: 0.145, green: 0.090, blue: 0.310)
        }
    }

    var accentDeep: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.285, green: 0.765, blue: 0.705)
        case .warmBotanical: Color(red: 0.315, green: 0.455, blue: 0.330)
        case .neonPulse: Color(red: 0.315, green: 0.785, blue: 1.000)
        }
    }

    var attention: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.920, green: 0.715, blue: 0.355)
        case .warmBotanical: Color(red: 0.800, green: 0.590, blue: 0.300)
        case .neonPulse: Color(red: 0.325, green: 0.850, blue: 1.000)
        }
    }

    var attentionSoft: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.235, green: 0.190, blue: 0.105)
        case .warmBotanical: Color(red: 0.975, green: 0.925, blue: 0.820)
        case .neonPulse: Color(red: 0.075, green: 0.210, blue: 0.340)
        }
    }

    /// Categorical scale for chart segments, in draw order. The category chart shows at most six
    /// segments — six real categories, or five plus a combined remainder — so six entries cover it
    /// without repeating a colour inside one chart. Each skin keeps its own family so a chart reads
    /// as part of the screen instead of as system colours dropped onto it, and neighbouring entries
    /// alternate warm and cool rather than sitting next to a confusable partner such as red beside
    /// green. Colour is never the only channel: the key repeats every category name.
    var categoricalChart: [Color] {
        switch skin {
        case .warmBotanical: [
            Color(red: 0.361, green: 0.522, blue: 0.376),
            Color(red: 0.800, green: 0.510, blue: 0.360),
            Color(red: 0.310, green: 0.545, blue: 0.545),
            Color(red: 0.545, green: 0.400, blue: 0.545),
            Color(red: 0.780, green: 0.640, blue: 0.310),
            Color(red: 0.400, green: 0.490, blue: 0.660),
        ]
        case .auroraGlow: [
            Color(red: 0.425, green: 0.900, blue: 0.820),
            Color(red: 0.920, green: 0.760, blue: 0.420),
            Color(red: 0.450, green: 0.720, blue: 0.960),
            Color(red: 0.960, green: 0.560, blue: 0.480),
            Color(red: 0.720, green: 0.620, blue: 0.960),
            Color(red: 0.680, green: 0.880, blue: 0.500),
        ]
        case .neonPulse: [
            Color(red: 0.605, green: 0.355, blue: 1.000),
            Color(red: 0.325, green: 0.850, blue: 1.000),
            Color(red: 1.000, green: 0.420, blue: 0.780),
            Color(red: 0.640, green: 0.950, blue: 0.420),
            Color(red: 1.000, green: 0.740, blue: 0.360),
            Color(red: 0.400, green: 0.560, blue: 1.000),
        ]
        }
    }

    var attentionBorder: Color { attention.opacity(0.52) }
    var attentionText: Color { skin == .warmBotanical ? Color(red: 0.490, green: 0.335, blue: 0.120) : attention }
    var destructive: Color { Color(red: 0.780, green: 0.220, blue: 0.220) }
    var dark: Color { skin == .warmBotanical ? Color(red: 0.090, green: 0.105, blue: 0.095) : canvas }
    var onDark: Color { Color(red: 0.970, green: 0.980, blue: 0.975) }
    var accentOnDark: Color { skin == .neonPulse ? Color(red: 0.420, green: 0.830, blue: 1.000) : Color(red: 0.635, green: 0.880, blue: 0.690) }
    var attentionOnDark: Color { skin == .neonPulse ? Color(red: 0.750, green: 0.490, blue: 1.000) : Color(red: 0.950, green: 0.750, blue: 0.370) }

    var accentGradient: LinearGradient {
        switch skin {
        case .auroraGlow:
            LinearGradient(colors: [accent, Color(red: 0.330, green: 0.800, blue: 0.690)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .warmBotanical:
            LinearGradient(colors: [Color(red: 0.560, green: 0.690, blue: 0.525), accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neonPulse:
            LinearGradient(colors: [Color(red: 0.720, green: 0.250, blue: 1.000), Color(red: 0.210, green: 0.780, blue: 1.000)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var backgroundReadabilityScrim: Color {
        switch skin {
        case .auroraGlow: Color.black.opacity(0.08)
        case .warmBotanical: Color.white.opacity(0.04)
        case .neonPulse: Color(red: 0.010, green: 0.010, blue: 0.060).opacity(0.12)
        }
    }
}

private struct MindBudgetThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = MindBudgetTheme.fallback
}

extension EnvironmentValues {
    var mindBudgetTheme: MindBudgetTheme {
        get { self[MindBudgetThemeEnvironmentKey.self] }
        set { self[MindBudgetThemeEnvironmentKey.self] = newValue }
    }
}

struct MindBudgetThemeBackground: View {
    @Environment(\.mindBudgetTheme) private var theme

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                theme.canvas

                Image(theme.skin.backgroundAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                theme.backgroundReadabilityScrim
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct MindBudgetLaunchAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mindBudgetTheme) private var theme

    let holdsForUITesting: Bool
    let completion: @MainActor () -> Void

    @State private var contentOpacity = 0.0
    @State private var contentScale = 0.96
    @State private var spentProgress: CGFloat = 0.18
    @State private var markerProgress: CGFloat = 0.24

    var body: some View {
        ZStack {
            MindBudgetThemeBackground()
            theme.canvas.opacity(0.22)

            VStack(spacing: 24) {
                budgetTrackMark

                VStack(spacing: 8) {
                    Text("brand.productName")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.ink)
                        .accessibilityIdentifier("launch.brandName")

                    Text("brand.subtitle")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("launch.brandSubtitle")
                }
            }
            .padding(.horizontal, 28)
            .opacity(contentOpacity)
            .scaleEffect(contentScale)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("launch.animation")
        .accessibilityHidden(!holdsForUITesting)
        .task {
            await runAnimation()
        }
    }

    private var budgetTrackMark: some View {
        let trackWidth: CGFloat = 190
        let markerWidth: CGFloat = 12

        return ZStack(alignment: .leading) {
            Capsule()
                .fill(theme.track)
                .frame(width: trackWidth, height: 18)

            Capsule()
                .fill(theme.accentGradient)
                .frame(width: trackWidth * spentProgress, height: 18)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(theme.attention)
                .frame(width: markerWidth, height: 72)
                .offset(x: (trackWidth - markerWidth) * markerProgress)
                .shadow(color: theme.attention.opacity(0.24), radius: 8, y: 3)
        }
        .frame(width: trackWidth, height: 72)
        .accessibilityHidden(true)
    }

    @MainActor
    private func runAnimation() async {
        if holdsForUITesting {
            contentOpacity = 1
            contentScale = 1
            spentProgress = 0.58
            markerProgress = 0.68
            return
        }

        if reduceMotion {
            contentScale = 1
            spentProgress = 0.58
            markerProgress = 0.68
            withAnimation(.easeOut(duration: 0.16)) {
                contentOpacity = 1
            }
            guard await wait(for: .milliseconds(430)) else { return }
            withAnimation(.easeIn(duration: 0.16)) {
                contentOpacity = 0
            }
            guard await wait(for: .milliseconds(170)) else { return }
        } else {
            withAnimation(.spring(duration: 0.42, bounce: 0.12)) {
                contentOpacity = 1
                contentScale = 1
            }
            withAnimation(.easeInOut(duration: 0.62)) {
                spentProgress = 0.58
                markerProgress = 0.68
            }
            guard await wait(for: .milliseconds(680)) else { return }
            withAnimation(.easeIn(duration: 0.22)) {
                contentOpacity = 0
                contentScale = 1.015
            }
            guard await wait(for: .milliseconds(230)) else { return }
        }

        completion()
    }

    private func wait(for duration: Duration) async -> Bool {
        do {
            try await Task.sleep(for: duration)
            return true
        } catch {
            return false
        }
    }
}
