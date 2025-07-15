//
//  HomeView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import HealthKitUI

struct HomeView: View {

    @EnvironmentObject var hkManager: HealthKitManager
    @EnvironmentObject var goalsManager: GoalsManager
    @EnvironmentObject var pointsManager: PointsManager
    @EnvironmentObject var adminManager: AdminManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var lbManager: LeaderboardsManager

    @State private var showingAlumnusAppreciationAlert = false
    @State private var showingGoalsSetting = false

    @Environment(\.colorScheme) var colorScheme

    @Namespace private var namespace

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                main
            }
        } else {
            NavigationView {
                main
            }
            .navigationViewStyle(.stack)
        }
    }

    var main: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            GeometryReader { geometry in
                VStack(spacing: geometry.size.height * 0.15 / 3) {
                    housePointsProgress
                        .frame(height: geometry.size.height * 0.07)

                    HStack {
                        steps
                        distance
                    }
                    .frame(height: geometry.size.height * 0.35)

                    leaderboardPreview
                        .frame(height: geometry.size.height * 0.35)

                    goals
                        .frame(height: geometry.size.height * 0.08)
                }
                .frame(maxHeight: geometry.size.height)
            }
            .padding()
        }
        .navigationTitle("Home")
        .onAppear {
            Task {
                await hkManager.fetchAllDatas()
                try await adminManager.checkIfUnderMaintenance()
                try await adminManager.checkIfAppForcesUpdates()
                try await pointsManager.checkAndAddPoints()
            }

            if authManager.accountType == .alumnus {
                self.showingAlumnusAppreciationAlert = true
            }
        }
        .alert("Thank you.", isPresented: $showingAlumnusAppreciationAlert) {

        } message: {
            Text("As an alumnus, you're able to view the contents of the app, but are unable to contribute to the leaderboard. We really appreciate your previous support as a student!")
        }
    }

    var housePointsProgress: some View {
        VStack {
            let housePointsEarnedToday = Int(floor(Double((hkManager.steps ?? 0) / GLOBAL_STEPS_PER_POINT)))
            HStack {
                HStack(spacing: 0) {
                    if authManager.accountType.canAddPoints {
                        Text("You have earned ")
                        Text("^[\(housePointsEarnedToday) points](inflect: true)")
                            .fontWeight(.bold)
                            .foregroundStyle(.accent)
                        Text(" today.")
                    } else {
                        Text("You are unable to earn GrowCalth points.")
                    }
                }
            }
            .font(.title3.weight(.medium))
            .lineLimit(1)
            .minimumScaleFactor(0.1)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .mask(Capsule())
        .background {
            Capsule()
                .fill(.shadow(.inner(color: .white.opacity(0.25), radius: 13, x: 0, y: 0)))
                .foregroundStyle(Color.background)
        }
        .overlay {
            Capsule()
                .stroke(Color.outline, lineWidth: 2)
        }
        .shadow(color: Color.shadow, radius: 35, x: 0, y: 5)
    }

    var steps: some View {
        activitySquare {
            activityInformation(
                data: Double(hkManager.steps ?? 0),
                goal: Double(goalsManager.stepsGoal ?? 0),
                unit: "steps",
                describer: "Steps"
            )
        }
    }

    var distance: some View {
        activitySquare {
            activityInformation(
                data: hkManager.distance ?? 0.00,
                goal: Double(goalsManager.distanceGoal ?? 0),
                unit: "km",
                describer: "Distance"
            )
        }
    }

    @ViewBuilder
    func activityInformation(data: Double, goal: Double, unit: String, describer: String) -> some View {
        VStack {
            Gauge(
                value: min(data, goal),
                in: 0...goal
            ) {
                Image(systemName: "gauge.medium")
            } currentValueLabel: {
                Group {
                    if unit == "steps" {
                        Text("\(String(Int(data)))")
                            .font(.system(size: 26, weight: .bold))
                    } else {
                        Text("\(data, specifier: "%.2f")")
                            .font(.system(size: 28, weight: .bold))
                    }
                }
                .contentTransition(.numericText())
                .foregroundStyle(.accent)
                .minimumScaleFactor(0.1)
                .lineLimit(1)

                Text("\(unit)")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
            }
            .gaugeStyle(ActivityGaugeStyle())
            .labelStyle(.titleOnly)

            Group {
                if unit == "steps" {
                    Text("\(String(Int(max(goal - data, 0)))) \(unit) left")
                } else {
                    Text("\(max(goal - data, 0), specifier: "%.2f") \(unit) left")
                }
            }
            .contentTransition(.numericText())
            .font(.system(size: 14))
            .lineLimit(1)
            .padding(4)
            .frame(maxWidth: .infinity)
            .mask(Capsule())
            .background {
                Capsule()
                    .fill(.shadow(.inner(color: Color.activityLeftShadow, radius: 13, x: 0, y: 0)))
                    .foregroundStyle(Color.background)
            }
        }
    }

    @ViewBuilder
    func activitySquare<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        VStack {
            content()
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            .shadow(.inner(color: .white.opacity(0.25), radius: 13, x: 0, y: 0))
                            .shadow(.inner(color: Color.activityInnerShadow, radius: 10, x: 0, y: 0))
                        )
                        .foregroundStyle(Color.background)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(colorScheme == .dark ? AnyShapeStyle(Color.clear) : AnyShapeStyle(Color.outline), lineWidth: 2)
                        .foregroundStyle(Color.clear)
                }
                .shadow(color: Color.activityOuterShadow, radius: 35, x: 0, y: 4)
        }
    }

    var leaderboardPreview: some View {
        NavigationLink {
            LeaderboardView()
        } label: {
            GeometryReader { geometry in
                VStack(spacing: 5) {
                    VStack(spacing: 15) {
                        let tallHeight: Double = abs(Double((geometry.size.height - 50) / 7 * 3))
                        let normalHeight: Double = abs(Double((geometry.size.height - 50) / 7 * 2))
                        let data = sortDictionary(for: lbManager.leaderboard)

                        ForEach(data.prefix(3), id: \.key) { house in
                            let placing: Int = data.firstIndex(where: { $0.key == house.key }) ?? -1
                            if let houses = Houses.init(rawValue: house.key) {
                                leaderboardPreviewRow(
                                    placing: Houses.getPlacingFrom(int: placing + 1),
                                    house: houses,
                                    points: house.value,
                                    height: placing == 0 ? tallHeight : normalHeight,
                                    placingBubbleWidth: tallHeight
                                )
                            }
                        }
                    }
                    HStack {
                        Spacer()
                        Text("view more >")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.1)
                    }
                    .padding(.horizontal, 5)
                    .frame(height: 15)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func sortDictionary(for dictionary: [String : Int]) -> Array<(key: String, value: Int)> {
        return dictionary.sorted { $0.value > $1.value }.sorted { first, second in
            if first.value == second.value {
                first.key < second.key
            } else {
                first.key == second.key
            }
        }
    }

    @ViewBuilder
    func leaderboardPreviewRow(
        placing: String,
        house: Houses,
        points: Int,
        height: CGFloat,
        placingBubbleWidth: CGFloat
    ) -> some View {
        Capsule()
            .frame(maxHeight: height)
            .foregroundStyle(Color.lbCapsuleBackground)
            .overlay {
                HStack(spacing: 30) {
                    Capsule()
                        .frame(width: placingBubbleWidth*1.2)
                        .foregroundStyle(Color.lbPlacingBackground)
                        .background {
                            Capsule()
                                .fill(.shadow(.inner(color: .white.opacity(0.25), radius: 13, x: 0, y: 0)))
                                .foregroundStyle(Color.lbPlacingBackground)
                        }
                        .overlay {
                            Text(placing)
                                .font(.title2.weight(.black).italic())
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                                .padding(.horizontal)
                        }
                        .overlay {
                            Capsule()
                                .stroke(Color.outline, lineWidth: 2)
                        }
                        .shadow(color: Color.shadow, radius: 35, x: 0, y: 5)
                    Capsule()
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(
                            LinearGradient(
                                stops: [
                                    .init(color: house.color, location: 0.7),
                                    .init(color: Color.lbHouseColorToFadeTo, location: 1.2)
                                ],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                        .background {
                            Capsule()
                                .fill(.shadow(.inner(color: .white.opacity(0.25), radius: 13, x: 0, y: 0)))
                                .foregroundStyle(
                                    LinearGradient(
                                        stops: [
                                            .init(color: house.color, location: 0.7),
                                            .init(color: Color.lbHouseColorToFadeTo, location: 1.2)
                                        ],
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                        }
                        .overlay {
                            Text("\(points) POINTS")
                                .padding(5)
                                .font(.title.weight(.black).italic())
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                                .foregroundColor(.white)
                        }
                        .overlay {
                            Capsule()
                                .stroke(Color.outline, lineWidth: 2)
                        }
                        .shadow(color: Color.shadow, radius: 35, x: 0, y: 5)
                }
            }
    }

    var goals: some View {
        Button {
            showingGoalsSetting.toggle()
        } label: {
            goalsButtonLabel
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingGoalsSetting) {
            GoalsView()
                .presentationDetents([.height(300)])
        }
    }

    var goalsButtonLabel: some View {
        HStack {
            Text("What's your next goal?")
                .font(.headline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
            Spacer()
            Image(systemName: "plus")
                .font(.title3.weight(.semibold))
        }
        .foregroundStyle(.white)
        .lineLimit(1)
        .padding(.horizontal, 30)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .mask(Capsule())
        .background {
            Capsule()
                .fill(.shadow(.inner(color: .white.opacity(0.25), radius: 13, x: 0, y: 0)))
                .foregroundStyle(Color.goalsBackground)
        }
        .overlay {
            Capsule()
                .stroke(Color.outline, lineWidth: 2)
        }
        .shadow(color: Color.shadow, radius: 35, x: 0, y: 5)
    }
}

extension UIColor {
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}

extension Color {
    static let background = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(red: 0.92, green: 0.92, blue: 0.95, alpha: 1),
            dark: UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        )
    )

    static let outline = LinearGradient(
        colors: [.white.opacity(0.8), .white.opacity(0.05), .white.opacity(0.8)],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )

    static let shadow = Color(
        uiColor: UIColor(hex: 0x2B2B2E)
    ).opacity(0.2)


    static let activityInnerShadow = Color(
        uiColor: UIColor(hex: 0xF4F4F6)
    ).opacity(0.1)

    static let activityOuterShadow = Color(
        uiColor: UIColor(hex: 0x14141F)
    ).opacity(0.1)

    static let activityLeftShadow = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(hex: 0x2B2B2E).withAlphaComponent(0.2),
            dark: UIColor(hex: 0x0C0C0D).withAlphaComponent(0.6)
        )
    )

    static let lbCapsuleBackground = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(hex: 0xD4D4D9),
            dark: UIColor(hex: 0x4E4E56)
        )
    )

    static let lbPlacingBackground = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(hex: 0xDFDFE5),
            dark: UIColor(hex: 0x3A3A40)
        )
    )

    static let lbHouseColorToFadeTo = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(hex: 0xDFDFE5),
            dark: UIColor(hex: 0x4F4F52)
        )
    )

    static let goalsBackground = Color(hex: 0xDB5461, alpha: 0.8)
}

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        let rotationAdjustment = Angle.degrees(90)
        let modifiedStart = startAngle - rotationAdjustment
        let modifiedEnd = endAngle - rotationAdjustment

        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: modifiedStart, endAngle: modifiedEnd, clockwise: !clockwise)

        return path
    }
}

struct ActivityGaugeStyle: GaugeStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(135))

            Circle()
                .trim(from: 0, to: 0.75 * configuration.value)
                .stroke(.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(135))

            VStack {
                configuration.currentValueLabel
            }
        }
    }

}

#Preview {
    HomeView()
}
