//
//  CalculatorResourcesView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 8/4/24.
//

import SwiftUI

struct CalculatorResourcesView: View {
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            List {
                Section {
                    resource(
                        "Body Mass Index (BMI)",
                        accessibilityLabel: "BMI",
                        subtitle: "Singapore Heart Foundation",
                        link: "https://www.myheart.org.sg/tools-resources/bmi-calculator/"
                    )
                } header: {
                    Text("Mass Calculators")
                        .textCase(.none)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.gray)
                }

                Section {
                    resource(
                        "Basal Metabolic Rate (BMR)",
                        accessibilityLabel: "BMR",
                        subtitle: "calculator.net",
                        link: "https://www.calculator.net/bmr-calculator.html"
                    )
                    resource(
                        "Daily Calorie Intake",
                        accessibilityLabel: "Calorie",
                        subtitle: "yourhealthcalculator.com",
                        link: "https://yourhealthcalculator.com/calculate-calories/"
                    )
                } header: {
                    Text("Calorie Calculators")
                        .textCase(.none)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.gray)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Calculators")
    }
    
    @ViewBuilder
    func resource(_ title: String, accessibilityLabel: String, subtitle: String, link: String) -> some View {
        Link(destination: URL(string: link)!) {
            CustomLabeledContent {
                Image(systemName: "arrow.up.forward.square.fill")
            } label: {
                Text(title)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    CalculatorResourcesView()
}
