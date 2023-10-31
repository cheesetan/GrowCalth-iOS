//
//  OnboardingView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 30/10/23.
//

import SwiftUI

struct OnboardingView: View {
    
    @Binding var onboardingView: Bool
    
    @State var tabSelection = 0
    @State var bounceEffect = 0
    @State var doneButtonShowing = false
    
    var body: some View {
        NavigationStack {
            TabView(selection: $tabSelection) {
                onboardingPage(text: "HealthKit Integration", 
                               description: "GrowCalth iOS integrates with Apple's Health App, allowing you to track steps and gains points on your iPhone or Apple Watch even when the app is not opened.",
                               imageString: "heart.text.square.fill",
                               renderingMode: .palette,
                               primaryColor: .red,
                               secondaryColor: .white)
                    .tag(0)
                onboardingPage(text: "Motivational Quotes", 
                               description: "Having a positive mindset will help with your daily mental health!",
                               imageString: "quote.opening",
                               primaryColor: .gray)
                    .tag(1)
                onboardingPage(text: "Set your Goals",
                               description: "Set and achieve your daily steps and distance goals for a healthier lifestyle!",
                               imageString: "chart.bar.fill",
                               primaryColor: .red)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    previousButton
                }
                ToolbarItem(placement: .bottomBar) {
                    if doneButtonShowing {
                        doneButton
                    } else {
                        nextButton
                    }
                }
            }
            .onChange(of: tabSelection) { _ in
                bounceEffect += 1
                if tabSelection == 2 {
                    withAnimation {
                        doneButtonShowing = true
                    }
                } else {
                    withAnimation {
                        doneButtonShowing = false
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                bounceEffect += 1
            }
        }
    }
    
    @ViewBuilder
    func onboardingPage(text: String, description: String, imageString: String, renderingMode: SymbolRenderingMode = .monochrome, primaryColor: Color = .accentColor, secondaryColor: Color = .accentColor) -> some View {
        VStack {
            Spacer()
            if #available(iOS 17.0, *) {
                Image(systemName: imageString)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96)
                    .symbolRenderingMode(renderingMode)
                    .foregroundStyle(primaryColor, secondaryColor)
                    .symbolEffect(.bounce, value: bounceEffect)
                    .shadow(color: .black.opacity(0.5), radius: 5)
            } else {
                Image(systemName: imageString)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96)
                    .symbolRenderingMode(renderingMode)
                    .foregroundStyle(primaryColor, secondaryColor)
                    .shadow(color: .black, radius: 5)
            }
            VStack(spacing: 5) {
                Text(text)
                    .minimumScaleFactor(0.1)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text(description)
                    .minimumScaleFactor(0.1)
                    .font(.subheadline)
                    .fontWeight(.none)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 45)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    var previousButton: some View {
        Button {
            withAnimation {
                tabSelection -= 1
            }
        } label: {
            Image(systemName: "arrowshape.left.fill")
        }
        .buttonStyle(.plain)
        .disabled(tabSelection < 1)
        .animation(.default, value: tabSelection)
    }
    
    var nextButton: some View {
        Button {
            withAnimation {
                tabSelection += 1
            }
        } label: {
            Image(systemName: "arrowshape.right.fill")
        }
        .buttonStyle(.plain)
        .disabled(tabSelection > 1)
        .animation(.default, value: tabSelection)
    }
    
    var doneButton: some View {
        Button {
            withAnimation {
                onboardingView = false
            }
        } label: {
            Text("Done")
        }
        .buttonStyle(.plain)
        .disabled(tabSelection != 2)
        .animation(.default, value: tabSelection)
        .animation(.default, value: doneButtonShowing)
    }
}

//#Preview {
//    OnboardingView()
//}
