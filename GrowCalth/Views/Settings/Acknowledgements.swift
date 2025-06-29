//
//  About.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct Acknowledgements: View {

    @State private var showingScoobert = false
    @State private var scoobertAngle = 0.0
    @State private var tapCount = 0

    var body: some View {
        ZStack {
            List {
                Section {
                    Text(LocalizedStringKey("GrowCalth is a one stop platform that allows SST Students to participate in house challenges and further fosters house spirit among their house members. Through the app, students are able to be notified of house announcements and events, which encourages house participation and involvement."))
                } header: {
                    Label("About GrowCalth", systemImage: "questionmark.circle.fill")
                }

                Section {
                    acknowledgement(title: "Han Jeong Seu, **Caleb** - Lead Developer of GrowCalth", description: "Class of 2024", image: "person.bust.fill")
                    acknowledgement(title: "Chay Yu Hung **Tristan** - Lead Developer of GrowCalth (iOS)", description: "Class of 2024", image: "hammer.fill")
                    acknowledgement(title: "**Felix** Forbes Dimjati - User Experience (UX) Specialist of GrowCalth", description: "Class of 2024", image: "hammer.fill")
                    acknowledgement(title: "Bellam Nandakumar **Aravind** - GrowCalth's Marketing and Communications IC", description: "Class of 2024", image: "text.bubble.fill")
                    acknowledgement(title: "**Darryan** Lim Yuan Sheng - GrowCalth's Designer", description: "Class of 2024", image: "paintbrush.pointed.fill")
                    acknowledgement(title: "**Scoobert** - GrowCalth's Mascot", description: "Loves to exercise. Will do a backflip if you tap him 5 times.", image: "scoobert")
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
                            handleTap()
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
                handleTap()
            }
        }
    }

    @MainActor
    private func handleTap() {
        tapCount += 1

        // Reset tap count after a delay if not enough taps
        Task {
            let currentTapCount = tapCount
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            if tapCount == currentTapCount && tapCount < 5 {
                tapCount = 0
            }
        }

        // Trigger animation after 5 taps
        if tapCount >= 5 {
            tapCount = 0
            triggerScoobertAnimation()
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
