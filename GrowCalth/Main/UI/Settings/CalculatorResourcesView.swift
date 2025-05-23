//
//  CalculatorResourcesView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 8/4/24.
//

import SwiftUI

struct CalculatorResourcesView: View {
    var body: some View {
        List {
            Section("Mass Calculators") {
                resource(
                    "Body Mass Index (BMI)",
                    subtitle: "Singapore Heart Foundation",
                    link: "https://www.myheart.org.sg/tools-resources/bmi-calculator/"
                )
            }
            
            Section("Calorie Calculators") {
                resource(
                    "Basal Metabolic Rate (BMR)",
                    subtitle: "calculator.net",
                    link: "https://www.calculator.net/bmr-calculator.html"
                )
                resource(
                    "Daily Calorie Intake",
                    subtitle: "yourhealthcalculator.com",
                    link: "https://yourhealthcalculator.com/calculate-calories/"
                )
            }
        }
        .navigationTitle("Calculators")
    }
    
    @ViewBuilder
    func resource(_ title: String, subtitle: String, link: String) -> some View {
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
    }
}

#Preview {
    CalculatorResourcesView()
}
