//
//  NewAnnouncementView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 2/11/23.
//

import SwiftUI

struct NewAnnouncementView: View {
    
    @State var title = ""
    @State var description = ""
    
    @State var eventDate = Date()
    @State var eventVenue = ""
    
    @State var showingAlert = false
    @State var alertTitle = ""
    @State var alertDescription = ""
    
    @State var postType: AnnouncementType
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var announcementManager: AnnouncementManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                picker
                    .padding(.top, -15)
                    .padding([.bottom, .horizontal])
                
                TextField("\(postType == .announcements ? "Announcement" : "Event") Title", text: $title)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                
                if postType == .events {
                    eventItems
                }
                
                Divider()
                    .padding(.vertical, 10)
                
                TextField("\(postType == .announcements ? "Announcement" : "Event") Description", text: $description, axis: .vertical)
                
                Spacer()
                
                createButton
            }
            .animation(.default, value: postType)
            .navigationTitle("Create a Post")
            .navigationBarTitleDisplayMode(.inline)
            .padding(.top)
            .padding(.horizontal, 30)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss.callAsFunction()
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertDescription)
        }
        .onChange(of: eventDate) { _ in
            let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
            eventDate = calendar.startOfDay(for: eventDate)
        }
        .onAppear {
            let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
            eventDate = calendar.startOfDay(for: eventDate)
        }
    }
    
    var picker: some View {
        VStack {
            Picker("Post Type", selection: $postType) {
                ForEach(AnnouncementType.allCases, id: \.hashValue) { type in
                    Text(type.rawValue == "Events" ? "Event" : "Announcement")
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    var eventItems: some View {
        VStack {
            DatePicker(selection: $eventDate, in: Date()..., displayedComponents: .date) {
                Label("Event Date", systemImage: "calendar")
                    .foregroundColor(.secondary)
            }
            
            TextField(LocalizedStringKey("\(Image(systemName: "mappin.and.ellipse")) Event Venue(s)"), text: $eventVenue)
        }
    }
    
    var createButton: some View {
        Button {
            if let email = authManager.email, adminManager.approvedEmails.contains(email) || email.contains("@sst.edu.sg") {
                switch postType {
                case .announcements:
                    createAnnouncement()
                case .events:
                    createEvent()
                }
            }
        } label: {
            Text("Create \(postType == .announcements ? "Announcement" : "Event")")
                .minimumScaleFactor(0.1)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.white)
                .background(.blue)
                .cornerRadius(16)
                .fontWeight(.bold)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 30)
        .disabled(title.isEmpty)
        .disabled(description.isEmpty)
        .disabled(postType == .events ? eventVenue.isEmpty : false)
    }
    
    func createAnnouncement() {
        adminManager.postAnnouncement(title: title, description: description) { result in
            switch result {
            case .success(_):
                successfullyCreatedPost()
            case .failure(let failure):
                alertTitle = "Error"
                alertDescription = failure.localizedDescription
                showingAlert = true
            }
        }
    }
    
    func createEvent() {
        adminManager.postEvent(title: title, description: description, eventDate: eventDate, eventVenues: eventVenue) { result in
            switch result {
            case .success(_):
                successfullyCreatedPost()
            case .failure(let failure):
                alertTitle = "Error"
                alertDescription = failure.localizedDescription
                showingAlert = true
            }
        }
    }
    
    func successfullyCreatedPost() {
        sendPushNotification(title: "New \(postType == .announcements ? "Announcement" : "Event")", subtitle: title, body: description)
        title = ""
        description = ""
        eventDate = Date()
        eventVenue = ""
        dismiss.callAsFunction()
        announcementManager.retrieveAllPosts() {}
    }
    
    func sendPushNotification(title: String, subtitle: String, body: String) {
        // Replace "YOUR_SERVER_KEY" with your actual FCM server key
        let serverKey = "AAAAkfMRk04:APA91bHVMbF_30AYZEvQ1WtCSIbB7WNPPSP8lJ54Ti0nHcr0Wfv2qu6AQxcLR5ZxxemZcP-KPNs0EYOw2ZXttD611k6yKHMNrDk72LrpCfy_XLNkQxGIdTz-UfGmEh_ku9ufcccr_dur"
        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        
        let notificationData: [String: Any] = [
            "to": "f-kZ3MStgk5av59seFeBg_:APA91bFPYjVr-iaHZXbroArgYgv6ZyB_1j5DABWIVo60Rwr07yrlZf6PUx5JhWiP6QQkQc01KxyGbE4RsfILc7M4T6s0-2SAEIfxA9RNGPhpVEEaRurLqFXWwgW8NTx-4I4--Z5Y2yxh",
            "notification": [
                "title": title,
                "subtitle": subtitle,
                "body": body
            ],
            "data": [
                "additionalDataKey": "additionalDataValue"
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: notificationData, options: [])
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                } else if let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Response: \(responseString ?? "")")
                }
            }
            
            task.resume()
        } catch {
            print("Error serializing JSON: \(error)")
        }
    }
}

//#Preview {
//    NewAnnouncementView()
//}
