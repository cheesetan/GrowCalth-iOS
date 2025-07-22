//
//  CustomContentUnavailableView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 26/3/25.
//

import SwiftUI

struct CustomContentUnavailableView: View {

    let title: String
    let systemImage: String
    let description: String
    let mode: UnavailableMode

    @State private var isLoading = false

    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var adminManager: AdminManager
    @EnvironmentObject private var developerManager: DeveloperManager

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack {
//                if #available(iOS 26.0, *) {
//                    ContentUnavailableView {
//                        Label(title, systemImage: systemImage)
//                    } description: {
//                        Text(description)
//                    } actions: {
//                        switch mode {
//                        case .maintenance:
//                            Button {
//                                isLoading = true
//                                Task {
//                                    try await adminManager.checkIfUnderMaintenance()
//                                    isLoading = false
//                                }
//                            } label: {
//                                if isLoading {
//                                    ProgressView()
//                                } else {
//                                    Label("Check Status", systemImage: "arrow.clockwise")
//                                        .fontWeight(.bold)
//                                }
//                            }
//                            .buttonStyle(.glassProminent)
//
//                            if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) {
//                                Button {
//                                    Task {
//                                        try await developerManager.changeAppIsUnderMaintenanceValue(to: false)
//                                        try await adminManager.checkIfUnderMaintenance()
//                                    }
//                                } label: {
//                                    Text("Turn Off Maintenance Mode FOR EVERYONE")
//                                }
//                                .buttonStyle(.glassProminent)
//                            }
//                        case .update:
//                            Link(destination: URL(string: "https://apps.apple.com/sg/app/growcalth/id6456388202")!) {
//                                Label("Open App Store", systemImage: "arrow.up.forward.app.fill")
//                                    .fontWeight(.bold)
//                            }
//                            .buttonStyle(.glassProminent)
//                        case .network:
//                            EmptyView()
//                        }
//
//                        switch mode {
//                        case .maintenance, .update:
//                            if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) {
//                                Button {
//                                    withAnimation {
//                                        developerManager.bypassed = true
//                                    }
//                                } label: {
//                                    Text("Temporarily Bypass Restrictions (Developer ONLY)")
//                                }
//                                .buttonStyle(.glassProminent)
//                            }
//                        case .network:
//                            EmptyView()
//                        }
//                    }
                /*} else */if #available(iOS 17.0, *) {
                    ContentUnavailableView {
                        Label(title, systemImage: systemImage)
                    } description: {
                        Text(description)
                    } actions: {
                        switch mode {
                        case .maintenance:
                            Button {
                                isLoading = true
                                Task {
                                    try await adminManager.checkIfUnderMaintenance()
                                    isLoading = false
                                }
                            } label: {
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Label("Check Status", systemImage: "arrow.clockwise")
                                        .fontWeight(.bold)
                                }
                            }
                            .buttonStyle(.borderedProminent)

                            if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) {
                                Button {
                                    Task {
                                        try await developerManager.changeAppIsUnderMaintenanceValue(to: false)
                                        try await adminManager.checkIfUnderMaintenance()
                                    }
                                } label: {
                                    Text("Turn Off Maintenance Mode FOR EVERYONE")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        case .update:
                            Link(destination: URL(string: "https://apps.apple.com/sg/app/growcalth/id6456388202")!) {
                                Label("Open App Store", systemImage: "arrow.up.forward.app.fill")
                                    .fontWeight(.bold)
                            }
                            .buttonStyle(.borderedProminent)
                        case .network:
                            EmptyView()
                        }

                        switch mode {
                        case .maintenance, .update:
                            if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) {
                                Button {
                                    withAnimation {
                                        developerManager.bypassed = true
                                    }
                                } label: {
                                    Text("Temporarily Bypass Restrictions (Developer ONLY)")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        case .network:
                            EmptyView()
                        }
                    }
                } else {
                    VStack(spacing: 15) {
                        Spacer()
                        Image(systemName: systemImage)
                            .font(.system(size: 70))
                            .foregroundColor(.secondary)
                        Text(description)
                            .multilineTextAlignment(.center)
                        switch mode {
                        case .maintenance:
                            Button {
                                isLoading = true
                                Task {
                                    try await adminManager.checkIfUnderMaintenance()
                                    isLoading = false
                                }
                            } label: {
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Label("Check Status", systemImage: "arrow.clockwise")
                                        .font(.body.weight(.bold))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        case .update:
                            Link(destination: URL(string: "https://apps.apple.com/sg/app/growcalth/id6456388202")!) {
                                Label("Open App Store", systemImage: "arrow.up.forward.app.fill")
                                    .font(.body.weight(.bold))
                            }
                            .buttonStyle(.borderedProminent)
                        case .network:
                            EmptyView()
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}
