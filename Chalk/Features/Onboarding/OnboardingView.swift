// OnboardingView.swift
// Chalk — First-launch onboarding flow

import SwiftUI

// MARK: - Container

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var showGoalSetup = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                OnboardingPage1View()
                    .tag(0)
                OnboardingPage2View()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { i in
                        Capsule()
                            .fill(currentPage == i ? Color.primary : Color.primary.opacity(0.25))
                            .frame(width: currentPage == i ? 20 : 8, height: 8)
                    }
                }
                .animation(.spring(duration: 0.3), value: currentPage)

                Text(currentPage == 0 ? "Set goals" : "Track your progress")
                    .font(.system(size: 28, weight: .regular))
                    .multilineTextAlignment(.center)
                    .id(currentPage)
                    .transition(.opacity)

                // Always rendered so the text above sits at the same Y on both pages.
                // Invisible and non-interactive on page 1.
                Button {
                    showGoalSetup = true
                } label: {
                    Text("Get started")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(.regularMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .opacity(currentPage == 1 ? 1 : 0)
                .disabled(currentPage == 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 52)
            .animation(.easeInOut(duration: 0.35), value: currentPage)
        }
        .chalkBackground()
        .fullScreenCover(isPresented: $showGoalSetup) {
            GoalSetupView(mode: .onboarding)
                .environmentObject(appState)
        }
    }
}

// MARK: - Page 1: Floating Goal Cards

private struct OnboardingPage1View: View {

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .topLeading) {
                Text("Chalk")
                    .font(.system(size: 34, weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                TimelineView(.animation) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate

                    ZStack {
                        OnboardingGoalCard(
                            icon: "figure.yoga", name: "Yoga",
                            color: Color(uiColor: .systemPink), count: 2, total: 3
                        )
                        .position(
                            x: w * 0.24 + CGFloat(cos(t * 0.37 + 0.5)) * 4,
                            y: h * 0.32 + CGFloat(sin(t * 0.62))        * 9
                        )

                        OnboardingGoalCard(
                            icon: "figure.tennis", name: "Padel",
                            color: Color(uiColor: .systemPurple), count: 1, total: 3
                        )
                        .position(
                            x: w * 0.79 + CGFloat(cos(t * 0.41 + 2.1)) * 5,
                            y: h * 0.49 + CGFloat(sin(t * 0.50 + 1.4)) * 11
                        )

                        OnboardingGoalCard(
                            icon: "figure.indoor.rowing", name: "Rowing",
                            color: Color(uiColor: .systemIndigo), count: 3, total: 4
                        )
                        .position(
                            x: w * 0.08 + CGFloat(cos(t * 0.35 + 4.2)) * 4,
                            y: h * 0.58 + CGFloat(sin(t * 0.55 + 2.7)) * 8
                        )
                    }
                }
            }
        }
        .clipped()
    }
}

// MARK: - Goal Card (Page 1)

private struct OnboardingGoalCard: View {
    let icon: String
    let name: String
    let color: Color
    let count: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 14)

            Spacer()

            ZStack {
                Canvas { ctx, size in
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    let r = min(size.width, size.height) / 2 - 8
                    let start = Angle.degrees(-90)
                    let progress = Double(count) / Double(total)

                    var track = Path()
                    track.addArc(center: c, radius: r, startAngle: start,
                                 endAngle: .degrees(270), clockwise: false)
                    ctx.stroke(track, with: .color(.gray.opacity(0.2)),
                               style: StrokeStyle(lineWidth: 8, lineCap: .round))

                    var arc = Path()
                    arc.addArc(center: c, radius: r, startAngle: start,
                               endAngle: .degrees(-90 + 360 * progress), clockwise: false)
                    ctx.stroke(arc, with: .color(color),
                               style: StrokeStyle(lineWidth: 8, lineCap: .round))
                }
                .frame(width: 88, height: 88)

                VStack(spacing: 1) {
                    Text("\(count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("of \(total)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)
        }
        .frame(width: 152, height: 152)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 20, y: 8)
    }
}

// MARK: - Page 2: Floating Weekly Cards

private struct OnboardingPage2View: View {

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Text("Chalk")
                    .font(.system(size: 34, weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                TimelineView(.animation) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    VStack(spacing: 20) {
                        OnboardingWeeklyCard(days: week1Days)
                            .offset(y: CGFloat(sin(t * 0.58)) * 7)
                        OnboardingWeeklyCard(days: week2Days)
                            .offset(y: CGFloat(sin(t * 0.44 + 1.9)) * 9)
                    }
                    .frame(width: geo.size.width - 32)
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.42)
            }
        }
        .clipped()
    }
}

// MARK: - Weekly Card Data

private struct OnboardingDay {
    let letter: String
    let dateNumber: Int
    let workouts: [(icon: String, color: Color)]
}

// Week 1: running, empty, yoga, empty, padel+running, yoga, empty
private let week1Days: [OnboardingDay] = [
    OnboardingDay(letter: "M", dateNumber: 28, workouts: [
        ("figure.run",    Color(uiColor: .systemOrange))
    ]),
    OnboardingDay(letter: "T", dateNumber: 29, workouts: []),
    OnboardingDay(letter: "W", dateNumber: 30, workouts: [
        ("figure.yoga",   Color(uiColor: .systemPink))
    ]),
    OnboardingDay(letter: "T", dateNumber: 1,  workouts: []),
    OnboardingDay(letter: "F", dateNumber: 2,  workouts: [
        ("figure.tennis", Color(uiColor: .systemPurple)),
        ("figure.run",    Color(uiColor: .systemOrange))
    ]),
    OnboardingDay(letter: "S", dateNumber: 3,  workouts: [
        ("figure.yoga",   Color(uiColor: .systemPink))
    ]),
    OnboardingDay(letter: "S", dateNumber: 4,  workouts: []),
]

// Week 2: empty, strength, hiit, empty, running, strength, empty
private let week2Days: [OnboardingDay] = [
    OnboardingDay(letter: "M", dateNumber: 5,  workouts: []),
    OnboardingDay(letter: "T", dateNumber: 6,  workouts: [
        ("figure.strengthtraining.traditional",   Color(uiColor: .systemCyan))
    ]),
    OnboardingDay(letter: "W", dateNumber: 7,  workouts: [
        ("figure.highintensity.intervaltraining", Color(uiColor: .systemYellow))
    ]),
    OnboardingDay(letter: "T", dateNumber: 8,  workouts: []),
    OnboardingDay(letter: "F", dateNumber: 9,  workouts: [
        ("figure.run",    Color(uiColor: .systemOrange))
    ]),
    OnboardingDay(letter: "S", dateNumber: 10, workouts: [
        ("figure.strengthtraining.traditional",   Color(uiColor: .systemCyan))
    ]),
    OnboardingDay(letter: "S", dateNumber: 11, workouts: []),
]

// MARK: - Weekly Card View

private struct OnboardingWeeklyCard: View {
    let days: [OnboardingDay]

    private let iconSize: CGFloat = 34

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(days.indices, id: \.self) { i in
                VStack(spacing: 8) {
                    iconArea(for: days[i])
                    Text(days[i].letter)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "#898989"))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
    }

    @ViewBuilder
    private func iconArea(for day: OnboardingDay) -> some View {
        if day.workouts.isEmpty {
            Text("\(day.dateNumber)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#D6D6D6"))
                .frame(width: iconSize, height: iconSize)
        } else if day.workouts.count == 1 {
            circleIcon(icon: day.workouts[0].icon, color: day.workouts[0].color)
        } else {
            // Two icons stacked with overlap, matching WeeklyActivityStrip layout.
            // Background circle plugs the gap between the two overlapping icons.
            VStack(spacing: -12) {
                circleIcon(icon: day.workouts[0].icon, color: day.workouts[0].color)
                ZStack {
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: iconSize - 6, height: iconSize - 6)
                    circleIcon(icon: day.workouts[1].icon, color: day.workouts[1].color)
                }
            }
        }
    }

    private func circleIcon(icon: String, color: Color) -> some View {
        ZStack {
            Circle().fill(color)
            Image(systemName: icon)
                .font(.system(size: iconSize * 0.44, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: iconSize, height: iconSize)
    }
}
