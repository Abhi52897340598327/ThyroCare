import SwiftUI

enum ThyroUI {
    static let teal = Color(red: 0.05, green: 0.58, blue: 0.58)
    static let mint = Color(red: 0.83, green: 0.96, blue: 0.93)
    static let navy = Color(red: 0.02, green: 0.12, blue: 0.22)
    static let coral = Color(red: 0.93, green: 0.36, blue: 0.31)
    static let amber = Color(red: 0.95, green: 0.68, blue: 0.23)
    static let violet = Color(red: 0.45, green: 0.33, blue: 0.82)
    static let ink = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let softGray = Color.gray.opacity(0.12)
}

struct ThyroPageScaffold<Content: View>: View {
    let title: String?
    private let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.white, ThyroUI.mint.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let title {
                        Text(title)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(ThyroUI.navy)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    content
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
    }
}

struct ThyroCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: ThyroUI.navy.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}

struct ThyroSectionTitle: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(ThyroUI.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ThyroChoicePill: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(isSelected ? .white : ThyroUI.navy)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? ThyroUI.teal : ThyroUI.softGray)
            .clipShape(Capsule())
    }
}

struct ThyroidVectorArt: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(ThyroUI.teal.opacity(0.18), lineWidth: 12)
                .frame(width: 190, height: 190)
                .scaleEffect(pulse ? 1.06 : 0.94)

            HStack(spacing: -18) {
                Ellipse()
                    .fill(ThyroUI.teal.gradient)
                    .frame(width: 78, height: 124)
                    .rotationEffect(.degrees(-18))
                Capsule()
                    .fill(ThyroUI.amber.gradient)
                    .frame(width: 30, height: 96)
                Ellipse()
                    .fill(ThyroUI.violet.gradient)
                    .frame(width: 78, height: 124)
                    .rotationEffect(.degrees(18))
            }
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: 96, y: 68))
                    path.addCurve(to: CGPoint(x: 96, y: 126), control1: CGPoint(x: 84, y: 86), control2: CGPoint(x: 108, y: 108))
                }
                .stroke(.white.opacity(0.75), lineWidth: 4)
            }
        }
        .frame(height: 220)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct LabVectorArt: View {
    @State private var fillLevel = false

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 12)
                .stroke(ThyroUI.navy.opacity(0.25), lineWidth: 5)
                .frame(width: 82, height: 160)

            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [ThyroUI.teal, ThyroUI.mint], startPoint: .bottom, endPoint: .top))
                .frame(width: 68, height: fillLevel ? 112 : 20)
                .padding(.bottom, 7)

            VStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .fill(ThyroUI.navy.opacity(0.28))
                        .frame(width: 24, height: 3)
                }
            }
            .offset(x: 34, y: -16)
        }
        .frame(height: 180)
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
                fillLevel = true
            }
        }
    }
}

struct PlateVectorArt: View {
    @State private var rotate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 164, height: 164)
                .shadow(color: ThyroUI.navy.opacity(0.12), radius: 12, x: 0, y: 8)
            Circle()
                .stroke(ThyroUI.softGray, lineWidth: 14)
                .frame(width: 130, height: 130)

            DonutSegmentChart(
                values: [28, 34, 18, 20],
                colors: [ThyroUI.teal, ThyroUI.amber, ThyroUI.coral, ThyroUI.violet],
                lineWidth: 28
            )
            .frame(width: 100, height: 100)
            .rotationEffect(.degrees(rotate ? 360 : 0))
        }
        .frame(height: 184)
        .onAppear {
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                rotate = true
            }
        }
    }
}

struct AnimatedMetricRing: View {
    let title: String
    let value: Double
    let color: Color
    var suffix: String = "%"

    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(ThyroUI.softGray, lineWidth: 12)
            Circle()
                .trim(from: 0, to: animate ? value : 0)
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text("\(Int(value * 100))\(suffix)")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(ThyroUI.navy)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(14)
        }
        .frame(width: 116, height: 116)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animate = true
            }
        }
    }
}

struct AnimatedBarChart: View {
    let values: [Double]
    let labels: [String]
    let color: Color
    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                VStack(spacing: 8) {
                    GeometryReader { proxy in
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 5)
                                .fill(color.gradient)
                                .frame(height: max(12, proxy.size.height * CGFloat(animate ? value : 0.08)))
                        }
                    }
                    .frame(height: 140)

                    Text(labels[index])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.78)) {
                animate = true
            }
        }
    }
}

struct DonutSegmentChart: View {
    let values: [Double]
    let colors: [Color]
    var lineWidth: CGFloat = 26

    private var total: Double {
        max(values.reduce(0, +), 1)
    }

    var body: some View {
        ZStack {
            ForEach(values.indices, id: \.self) { index in
                Circle()
                    .trim(from: start(for: index), to: end(for: index))
                    .stroke(colors[index % colors.count], style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
        }
    }

    private func start(for index: Int) -> Double {
        values.prefix(index).reduce(0, +) / total
    }

    private func end(for index: Int) -> Double {
        values.prefix(index + 1).reduce(0, +) / total
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .foregroundStyle(ThyroUI.ink)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(ThyroUI.navy)
        }
        .font(.subheadline)
    }
}
