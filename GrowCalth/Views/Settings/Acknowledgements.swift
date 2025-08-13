//
//  About.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct Acknowledgements: View {

    @State private var showingScoobert = false
    @State private var showingPibble = false
    @State private var scoobertAngle = 0.0
    @State private var scoobertTapCount = 0
    @State private var pibblesTapCount = 0

    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            List {
                Section {
                    Text(LocalizedStringKey("GrowCalth is a one stop platform that allows SST Students to participate in house challenges and further fosters house spirit among their house members. Through the app, students are able to be notified of house announcements and events, which encourages house participation and involvement."))
                } header: {
                    Label("About GrowCalth", systemImage: "questionmark.circle.fill")
                }

                Section {
                    acknowledgement(title: "Han Jeong Seu, **Caleb** - CEO of GrowCalth / Lead Android Developer at GrowCalth", description: "Class of 2024", image: "person.bust.fill")
                    acknowledgement(title: "Chay Yu Hung **Tristan** - Lead iOS Developer at GrowCalth", description: "Class of 2024", image: "hammer.fill")
                    acknowledgement(title: "**Felix** Forbes Dimjati - Social Entrepreneurship Lead at GrowCalth", description: "Class of 2024", image: "person.3.fill")
                    acknowledgement(title: "Bellam Nandakumar **Aravind** - Communications Lead at GrowCalth", description: "Class of 2024", image: "text.bubble.fill")
                    acknowledgement(title: "**Darryan** Lim Yuan Sheng - Marketing and Design Lead at GrowCalth", description: "Class of 2024", image: "paintbrush.pointed.fill")
                    acknowledgement(title: "**Aathithya** Jegatheesan - Outreach and Relational Lead at GrowCalth", description: "Class of 2024", image: "person.line.dotted.person.fill")
                    acknowledgement(title: "**Ayaan** Jain - Financial Lead at GrowCalth", description: "Class of 2024", image: "dollarsign.circle.fill")
                    acknowledgement(title: "**Scoobert** - GrowCalth's Mascot", description: "Loves to exercise. Will do a backflip if you tap him 5 times.", image: "scoobert")
                    acknowledgement(title: "**Washington** - GrowCalth's Mascot", description: "Tiny little pibble. Will demand you to wash his bellayyyy if you tap him 5 times.", image: "washington")
                } header: {
                    Label("Development Team", systemImage: "person.3.fill")
                }

                Section {
                    acknowledgement(title: "Ms **Adele** Lim", description: "Sports and Wellness Department", image: "figure.run")
                    acknowledgement(title: "Mr Ng **Jun Wei**", description: "Sports and Wellness Department", image: "figure.run")
                    acknowledgement(title: "Mr **Wade** Wang", description: "Sports and Wellness Department", image: "figure.run")
                } header: {
                    Label("Special Thanks", systemImage: "star.fill")
                }

                Section {
                    acknowledgement(title: "Aurelius Intelligence", description: "Developed by GrowCalth.", image: "brain.fill")
                    Link(destination: URL(string: "https://github.com/firebase/firebase-ios-sdk")!) {
                        acknowledgement(title: "Firebase iOS SDK", description: "Developed by Google. Licensed under the Apache License 2.0.", image: "server.rack")
                    }
                } header: {
                    Label("Packages & Libraries", systemImage: "shippingbox.fill")
                }
            }
            .scrollContentBackground(.hidden)

            GeometryReader { geometry in
                if showingScoobert {
                    Image("scoobert")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width - 50)
                        .rotationEffect(.degrees(scoobertAngle))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }

            GeometryReader { geometry in
                if showingPibble {
                    Image("washington")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width - 50)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Acknowledgements")
    }

    @ViewBuilder
    func acknowledgement(title: LocalizedStringKey, description: String, image: String) -> some View {
        HStack {
            Group {
                if image == "scoobert" {
                    Image(image)
                        .resizable()
                        .accessibilityAction(named: "Scoobert") {
                            handleScoobertTap()
                        }
                } else if image == "washington" {
                    Image(image)
                        .resizable()
                        .accessibilityAction(named: "Scoobert") {
                            handlePibblesTap()
                        }
                } else {
                    Image(systemName: image)
                        .resizable()
                        .foregroundGradient(colors: title == "Aurelius Intelligence" ? [
                            .init(color: Color(hex: 0x58B2FB), location: 0.25),
                            .init(color: Color(hex: 0x986FF1), location: 0.40),
                            .init(color: Color(hex: 0xB46CC3), location: 0.60),
                            .init(color: Color(hex: 0xF0675E), location: 0.8),
                            .init(color: Color(hex: 0xFDA701), location: 1),
                        ] : [.init(color: .accentColor, location: 1)])
                }
            }
            .scaledToFit()
            .frame(width: 20)
            .padding(.trailing, 5)

            VStack(alignment: .leading) {
                Text(title)
                    .foregroundGradient(colors: title == "Aurelius Intelligence" ? [
                        .init(color: Color(hex: 0x58B2FB), location: 0.1),
                        .init(color: Color(hex: 0x986FF1), location: 0.3),
                        .init(color: Color(hex: 0xB46CC3), location: 0.4),
                        .init(color: Color(hex: 0xF0675E), location: 0.6),
                        .init(color: Color(hex: 0xFDA701), location: 1),
                    ] : [.init(color: .primary, location: 1)])
                    .font(.body.weight(title == "Aurelius Intelligence" ? .bold : .regular))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            if image == "scoobert" {
                handleScoobertTap()
            } else if image == "washington" {
                handlePibblesTap()
            }
        }
    }

    @MainActor
    private func handleScoobertTap() {
        scoobertTapCount += 1

        // Reset tap count after a delay if not enough taps
        Task {
            let currentTapCount = scoobertTapCount
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            if scoobertTapCount == currentTapCount && scoobertTapCount < 5 {
                scoobertTapCount = 0
            }
        }

        // Trigger animation after 5 taps
        if scoobertTapCount >= 5 {
            scoobertTapCount = 0
            triggerScoobertAnimation()
        }
    }

    @MainActor
    private func handlePibblesTap() {
        pibblesTapCount += 1

        // Reset tap count after a delay if not enough taps
        Task {
            let currentTapCount = pibblesTapCount
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            if pibblesTapCount == currentTapCount && pibblesTapCount < 5 {
                pibblesTapCount = 0
            }
        }

        // Trigger animation after 5 taps
        if pibblesTapCount >= 5 {
            pibblesTapCount = 0
            audioManager.playSound(named: "washmybellayyyy")
            triggerPibbleAnimation()
        }
    }

    @MainActor
    private func triggerScoobertAnimation() {
        withAnimation {
            showingScoobert = true
        }

        Task {
            // Wait 0.5 seconds before starting rotation
            try await Task.sleep(nanoseconds: 500_000_000)

            await MainActor.run {
                withAnimation(.easeOut(duration: 1)) {
                    scoobertAngle = 360
                }
            }

            // Wait 1.5 seconds then reset
            try await Task.sleep(nanoseconds: 1_500_000_000)

            await MainActor.run {
                scoobertAngle = 0
                withAnimation {
                    showingScoobert = false
                }
            }
        }
    }

    @MainActor
    private func triggerPibbleAnimation() {
        withAnimation {
            showingPibble = true
        }

        Task {
            try await Task.sleep(nanoseconds: 6_000_000_000)
            await MainActor.run {
                withAnimation {
                    showingPibble = false
                }
            }
        }
    }
}

extension View {
    public func foregroundGradient(colors: [Gradient.Stop]) -> some View {
        self.overlay(
            LinearGradient(
                stops: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .mask(self)
    }
}

#Preview {
    Acknowledgements()
}
