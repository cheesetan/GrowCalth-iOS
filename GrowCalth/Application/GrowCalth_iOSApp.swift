//
//  GrowCalth_iOSApp.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {

    let gcmMessageIDKey = "gcm.message_id"

    @ObservedObject var apnManager: ApplicationPushNotificationsManager = .shared

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        // Setting up Cloud Messaging
        Messaging.messaging().delegate = self

        // Setting up Notifications
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]

            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { _, _ in }
            )
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(
                types: [.alert, .badge, .sound],
                categories: nil
            )
            application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()

        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {

        // Do something with message data here
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }

        // Print full message.
        print(userInfo)

        return UIBackgroundFetchResult.newData
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Set the device token for FCM
        Messaging.messaging().apnsToken = deviceToken
    }
}

// Cloud Messaging
extension AppDelegate: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let dataDict: [String: String] = ["token": fcmToken ?? ""]

        Task { @MainActor in
            apnManager.setSelfFCMToken(fcmToken: fcmToken ?? "")
            do {
                try await apnManager.updateFCMTokenInFirebase(fcmToken: fcmToken ?? "")
            } catch {
                print("Failed to update FCM token in Firebase: \(error)")
            }
        }

        print(dataDict)
    }
}

// User Notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)

        // Print full message.
        print(userInfo)

        // Change this to your preferred presentation option
        return [.banner, .badge, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)

        // Print full message.
        print(userInfo)
    }
}

// Global constants
let GLOBAL_STEPS_PER_POINT: Int = 5000
let GLOBAL_GROWCALTH_START_DATE: Date = .init(timeIntervalSince1970: TimeInterval(1744128000))
let GLOBAL_ADMIN_EMAILS: [String] = [
    "admin@growcalth.com",
    "chay_yu_hung@s2021.ssts.edu.sg",
    "han_jeong_seu_caleb@s2021.ssts.edu.sg"
]

import Firebase
import FirebaseFirestore

@main
struct GrowCalth_iOSApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
//            PoseCameraView()
        }
    }
}

//
//  PoseWorkout_OneAtATime_WithGuides.swift
//  iOS 16+ (SwiftUI + AVFoundation + Vision)
//

import SwiftUI
import AVFoundation
import Vision
import UIKit

// MARK: - Math Helpers

struct PoseMath {
    static func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
    static func dot(_ a: CGPoint, _ b: CGPoint) -> CGFloat { a.x * b.x + a.y * b.y }
    /// Angle ∠ABC in radians
    static func angle(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        let ab = CGPoint(x: a.x - b.x, y: a.y - b.y)
        let cb = CGPoint(x: c.x - b.x, y: c.y - b.y)
        let denom = (hypot(ab.x, ab.y) * hypot(cb.x, cb.y))
        guard denom > 0 else { return .pi }
        let cosv = max(-1, min(1, dot(ab, cb) / denom))
        return acos(cosv)
    }
}
@inline(__always)
private func ringAppend(_ arr: inout [CGFloat], _ value: CGFloat, limit: Int) {
    arr.append(value)
    if arr.count > limit { _ = arr.removeFirst() }
}
private func avg(_ xs: [CGFloat]) -> CGFloat { xs.isEmpty ? .nan : xs.reduce(0, +) / CGFloat(xs.count) }

// MARK: - Workout Protocols/Models

struct DetectedRep {
    let workout: WorkoutKind
    let timestamp: TimeInterval
}

enum WorkoutKind: String, CaseIterable, Hashable, Identifiable {
    case jumpingJack     = "Jumping Jacks"
    case pushUp          = "Push-ups"
    case squat           = "Squats"
    case highKnees       = "High Knees"
    case armRaises       = "Lateral Raises"     // T-pose

    // New forward-facing exercises
    case frontRaises     = "Front Raises"
    case overheadPress   = "Overhead Press"
    case sideSteps       = "Side Steps"
    case crossCrunch     = "Cross Knee-to-Elbow"
    case standingTwists  = "Standing Twists"

    var id: String { rawValue }
}

protocol WorkoutDetector {
    var kind: WorkoutKind { get }
    var count: Int { get }
    var phaseDescription: String { get }
    var formHint: String? { get }
    mutating func reset()
    mutating func update(joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
                         time: TimeInterval) -> [DetectedRep]
}

// MARK: - Jumping Jacks (arms + legs)

struct JumpingJackDetector: WorkoutDetector {
    enum Phase { case unknown, down, up }
    let kind: WorkoutKind = .jumpingJack
    private(set) var count: Int = 0
    private(set) var phase: Phase = .unknown
    private(set) var formHint: String? = nil

    // Tunables
    var armsUpHeadYMargin: CGFloat = 0.05
    var legsApartFactor: CGFloat = 1.12 // slightly easier than 1.15
    var legsTogetherFactor: CGFloat = 0.88
    var smoothWindow = 5

    // Histories
    private var shoulderW: [CGFloat] = []
    private var ankleGap: [CGFloat] = []
    private var headY: [CGFloat] = []
    private var lwY: [CGFloat] = []
    private var rwY: [CGFloat] = []

    var phaseDescription: String {
        switch phase { case .unknown: return "—"; case .down: return "DOWN"; case .up: return "UP" }
    }

    mutating func reset() {
        count = 0; phase = .unknown; formHint = nil
        shoulderW.removeAll(); ankleGap.removeAll(); headY.removeAll(); lwY.removeAll(); rwY.removeAll()
    }

    mutating func update(joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
                         time: TimeInterval) -> [DetectedRep] {
        guard let ls = joints[.leftShoulder], let rs = joints[.rightShoulder],
              let la = joints[.leftAnkle], let ra = joints[.rightAnkle],
              let nose = joints[.nose] ?? joints[.neck],
              let lw = joints[.leftWrist], let rw = joints[.rightWrist] else { formHint = "Stand centered in frame"; return [] }

        ringAppend(&shoulderW, PoseMath.dist(ls, rs), limit: smoothWindow)
        ringAppend(&ankleGap,  PoseMath.dist(la, ra), limit: smoothWindow)
        ringAppend(&headY,     nose.y,               limit: smoothWindow)
        ringAppend(&lwY,       lw.y,                 limit: smoothWindow)
        ringAppend(&rwY,       rw.y,                 limit: smoothWindow)

        let sw = avg(shoulderW), ag = avg(ankleGap), hY = avg(headY)
        let LwY = avg(lwY), RwY = avg(rwY)
        guard sw.isFinite, ag.isFinite, hY.isFinite, LwY.isFinite, RwY.isFinite else { formHint = "Step back a little"; return [] }

        let armsUp = (LwY < hY - armsUpHeadYMargin) && (RwY < hY - armsUpHeadYMargin)
        let legsApart  = ag > legsApartFactor * sw
        let legsTogether = ag < legsTogetherFactor * sw

        // Form tips
        if phase == .down {
            if !armsUp { formHint = "Raise arms higher (above head band)" }
            else if !legsApart { formHint = "Step feet wider (past guides)" }
            else { formHint = nil }
        } else if phase == .up {
            let armsDown = (LwY > hY) && (RwY > hY)
            if !armsDown { formHint = "Lower arms fully" }
            else if !legsTogether { formHint = "Bring feet together" }
            else { formHint = nil }
        } else { formHint = nil }

        switch phase {
        case .unknown:
            phase = (armsUp && legsApart) ? .up : .down
        case .down:
            if armsUp && legsApart { phase = .up }
        case .up:
            let armsDown = (LwY > hY) && (RwY > hY)
            if armsDown && legsTogether {
                count += 1
                phase = .down
                return [DetectedRep(workout: kind, timestamp: time)]
            }
        }
        return []
    }
}

// MARK: - Push-ups (elbow angle + form hints)

struct PushUpDetector: WorkoutDetector {
    enum Phase { case unknown, top, lowering, bottom, rising }
    let kind: WorkoutKind = .pushUp
    private(set) var count = 0
    private(set) var phase: Phase = .unknown
    private(set) var formHint: String? = nil

    // Tunables
    var elbowTopAngleMin: CGFloat = 2.2     // ~126°+
    var elbowBottomAngleMax: CGFloat = 1.6  // ~92°
    var elbowBottomTarget: CGFloat = 1.5    // ~86°
    var smoothWindow = 5

    private var lElbowAngles: [CGFloat] = []
    private var rElbowAngles: [CGFloat] = []
    private var prevAngle: CGFloat = .nan

    var phaseDescription: String {
        switch phase {
        case .unknown: return "—"
        case .top: return "TOP"
        case .lowering: return "LOWERING"
        case .bottom: return "BOTTOM"
        case .rising: return "RISING"
        }
    }

    mutating func reset() {
        count = 0; phase = .unknown; formHint = nil; prevAngle = .nan
        lElbowAngles.removeAll(); rElbowAngles.removeAll()
    }

    mutating func update(joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
                         time: TimeInterval) -> [DetectedRep] {
        guard let ls = joints[.leftShoulder], let le = joints[.leftElbow], let lw = joints[.leftWrist],
              let rs = joints[.rightShoulder], let re = joints[.rightElbow], let rw = joints[.rightWrist]
        else { formHint = "Keep full upper body in view"; return [] }

        let leftAng  = PoseMath.angle(a: ls, b: le, c: lw)
        let rightAng = PoseMath.angle(a: rs, b: re, c: rw)
        ringAppend(&lElbowAngles, leftAng,  limit: smoothWindow)
        ringAppend(&rElbowAngles, rightAng, limit: smoothWindow)

        let elbowAngle = avg([avg(lElbowAngles), avg(rElbowAngles)].compactMap { $0.isFinite ? $0 : nil })
        guard elbowAngle.isFinite else { formHint = nil; return [] }

        let descending = prevAngle.isFinite ? (elbowAngle < prevAngle - 0.01) : false
        let ascending  = prevAngle.isFinite ? (elbowAngle > prevAngle + 0.01) : false
        prevAngle = elbowAngle

        switch phase {
        case .unknown:
            phase = (elbowAngle > elbowTopAngleMin) ? .top : .lowering
        case .top:
            if descending { phase = .lowering }
        case .lowering:
            if elbowAngle < elbowBottomAngleMax { phase = .bottom }
        case .bottom:
            if ascending { phase = .rising }
        case .rising:
            if elbowAngle > elbowTopAngleMin {
                count += 1
                phase = .top
                return [DetectedRep(workout: kind, timestamp: time)]
            }
        }

        // Form hints
        switch phase {
        case .lowering:
            formHint = (elbowAngle > elbowBottomTarget) ? "Lower chest — bend elbows to ~90°" : nil
        case .rising:
            formHint = (elbowAngle < elbowTopAngleMin - 0.1) ? "Fully extend at the top" : nil
        default:
            formHint = nil
        }
        return []
    }
}

// MARK: - Squats (combined knee angle + hip-below-knee depth)

struct SquatDetector: WorkoutDetector {
    enum Phase { case unknown, up, lowering, down, rising }
    let kind: WorkoutKind = .squat
    private(set) var count = 0
    private(set) var phase: Phase = .unknown
    private(set) var formHint: String? = nil

    // Tunables
    var downMaxKneeAngle: CGFloat = 1.95   // <= ~112°
    var downTargetAngle: CGFloat  = 1.75   // ~100°
    var upMinKneeAngle: CGFloat   = 2.55   // >= ~146°
    var depthHipBelowKneeMargin: CGFloat = 0.01 // hip.y must be > knee.y + margin (lower than knee)
    var smoothWindow = 7                   // stronger smoothing

    private var lKneeAngles: [CGFloat] = []
    private var rKneeAngles: [CGFloat] = []
    private var hipY: [CGFloat] = []
    private var kneeY: [CGFloat] = []
    private var prevAngle: CGFloat = .nan

    var phaseDescription: String {
        switch phase {
        case .unknown: return "—"
        case .up: return "UP"
        case .lowering: return "LOWERING"
        case .down: return "DOWN"
        case .rising: return "RISING"
        }
    }

    mutating func reset() {
        count = 0; phase = .unknown; formHint = nil; prevAngle = .nan
        lKneeAngles.removeAll(); rKneeAngles.removeAll(); hipY.removeAll(); kneeY.removeAll()
    }

    mutating func update(joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
                         time: TimeInterval) -> [DetectedRep] {
        guard let lh = joints[.leftHip], let lk = joints[.leftKnee], let la = joints[.leftAnkle],
              let rh = joints[.rightHip], let rk = joints[.rightKnee], let ra = joints[.rightAnkle]
        else { formHint = "Keep lower body in view"; return [] }

        let lAng = PoseMath.angle(a: lh, b: lk, c: la) // hip–knee–ankle
        let rAng = PoseMath.angle(a: rh, b: rk, c: ra)
        ringAppend(&lKneeAngles, lAng, limit: smoothWindow)
        ringAppend(&rKneeAngles, rAng, limit: smoothWindow)

        // Track average hip/knee Y for depth check
        let meanHipY = (lh.y + rh.y) / 2
        let meanKneeY = (lk.y + rk.y) / 2
        ringAppend(&hipY, meanHipY, limit: smoothWindow)
        ringAppend(&kneeY, meanKneeY, limit: smoothWindow)

        let kneeAngle = avg([avg(lKneeAngles), avg(rKneeAngles)].compactMap { $0.isFinite ? $0 : nil })
        let hipYAvg = avg(hipY)
        let kneeYAvg = avg(kneeY)
        guard kneeAngle.isFinite, hipYAvg.isFinite, kneeYAvg.isFinite else { formHint = nil; return [] }

        let descending = prevAngle.isFinite ? (kneeAngle < prevAngle - 0.01) : false
        let ascending  = prevAngle.isFinite ? (kneeAngle > prevAngle + 0.01) : false
        prevAngle = kneeAngle

        let hipBelowKnee = hipYAvg > (kneeYAvg + depthHipBelowKneeMargin)

        switch phase {
        case .unknown:
            phase = (kneeAngle > upMinKneeAngle && !hipBelowKnee) ? .up : .lowering
        case .up:
            if descending { phase = .lowering }
        case .lowering:
            // Require BOTH a bent knee AND hip below knee for a clean "down"
            if kneeAngle < downMaxKneeAngle && hipBelowKnee { phase = .down }
        case .down:
            if ascending { phase = .rising }
        case .rising:
            if kneeAngle > upMinKneeAngle && !hipBelowKnee {
                count += 1
                phase = .up
                return [DetectedRep(workout: kind, timestamp: time)]
            }
        }

        // Form hints
        switch phase {
        case .lowering:
            if !hipBelowKnee { formHint = "Go deeper — hips to/below knee line" }
            else if kneeAngle > downTargetAngle { formHint = "Bend more at knees & hips" }
            else { formHint = nil }
        case .rising:
            if kneeAngle < upMinKneeAngle - 0.1 { formHint = "Stand tall — lock out at top" } else { formHint = nil }
        default:
            formHint = nil
        }
        return []
    }
}

// MARK: - High Knees

struct HighKneesDetector: WorkoutDetector {
    let kind: WorkoutKind = .highKnees
    private(set) var count = 0
    private(set) var formHint: String? = nil
    var phaseDescription: String { "—" }

    // Tunables
    var kneeAboveHipMargin: CGFloat = 0.03
    var cooldown: TimeInterval = 0.35
    var smoothWindow = 3
    private var lKneeY: [CGFloat] = []
    private var rKneeY: [CGFloat] = []
    private var lHipY:  [CGFloat] = []
    private var rHipY:  [CGFloat] = []
    private var lastHitLeft: TimeInterval = 0
    private var lastHitRight: TimeInterval = 0

    mutating func reset() {
        count = 0; lastHitLeft = 0; lastHitRight = 0; formHint = nil
        lKneeY.removeAll(); rKneeY.removeAll(); lHipY.removeAll(); rHipY.removeAll()
    }

    mutating func update(joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
                         time: TimeInterval) -> [DetectedRep] {
        guard let lk = joints[.leftKnee], let rk = joints[.rightKnee],
              let lh = joints[.leftHip], let rh = joints[.rightHip] else { formHint = "Keep hips and knees visible"; return [] }

        ringAppend(&lKneeY, lk.y, limit: smoothWindow)
        ringAppend(&rKneeY, rk.y, limit: smoothWindow)
        ringAppend(&lHipY,  lh.y, limit: smoothWindow)
        ringAppend(&rHipY,  rh.y, limit: smoothWindow)

        let lK = avg(lKneeY), rK = avg(rKneeY), lH = avg(lHipY), rH = avg(rHipY)
        guard [lK, rK, lH, rH].allSatisfy({ $0.isFinite }) else { formHint = nil; return [] }

        var events: [DetectedRep] = []

        if lK < (lH - kneeAboveHipMargin) {
            if time - lastHitLeft > cooldown { count += 1; lastHitLeft = time; events.append(DetectedRep(workout: kind, timestamp: time)) }
            formHint = nil
        } else if rK < (rH - kneeAboveHipMargin) {
            if time - lastHitRight > cooldown { count += 1; lastHitRight = time; events.append(DetectedRep(workout: kind, timestamp: time)) }
            formHint = nil
        } else {
            let leftGap  = (lH - kneeAboveHipMargin) - lK
            let rightGap = (rH - kneeAboveHipMargin) - rK
            formHint = leftGap > rightGap ? "Lift LEFT knee higher (to line)" : "Lift RIGHT knee higher (to line)"
        }
        return events
    }
}

// MARK: - Lateral Raises (T-pose) — FIXED with elbow straightness + robust lateral

struct ArmRaisesDetector: WorkoutDetector {
    enum Phase { case unknown, down, up }
    let kind: WorkoutKind = .armRaises
    private(set) var count = 0
    private(set) var phase: Phase = .unknown
    private(set) var formHint: String? = nil

    // Tunables
    var shoulderHeightBand: CGFloat = 0.045    // more forgiving
    var lateralMinFactor: CGFloat = 0.50       // wrists this far beyond shoulders (× shoulder width)
    var straightAngleMin: CGFloat = 2.7        // shoulder angle (elbow–shoulder–wrist) near straight line
    var smoothWindow = 7

    private var lwY: [CGFloat] = []
    private var rwY: [CGFloat] = []
    private var lsY: [CGFloat] = []
    private var rsY: [CGFloat] = []
    private var lShoulderAngles: [CGFloat] = []
    private var rShoulderAngles: [CGFloat] = []

    var phaseDescription: String {
        switch phase { case .unknown: return "—"; case .down: return "DOWN"; case .up: return "UP" }
    }

    mutating func reset() {
        count = 0; phase = .unknown; formHint = nil
        lwY.removeAll(); rwY.removeAll(); lsY.removeAll(); rsY.removeAll()
        lShoulderAngles.removeAll(); rShoulderAngles.removeAll()
    }

    mutating func update(joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
                         time: TimeInterval) -> [DetectedRep] {
        guard let lw = joints[.leftWrist], let rw = joints[.rightWrist],
              let ls = joints[.leftShoulder], let rs = joints[.rightShoulder],
              let le = joints[.leftElbow], let re = joints[.rightElbow] else {
            formHint = "Keep shoulders, elbows, and wrists visible"; return []
        }

        ringAppend(&lwY, lw.y, limit: smoothWindow)
        ringAppend(&rwY, rw.y, limit: smoothWindow)
        ringAppend(&lsY, ls.y, limit: smoothWindow)
        ringAppend(&rsY, rs.y, limit: smoothWindow)

        // Shoulder straightness angles
        let lSA = PoseMath.angle(a: le, b: ls, c: lw)
        let rSA = PoseMath.angle(a: re, b: rs, c: rw)
        ringAppend(&lShoulderAngles, lSA, limit: smoothWindow)
        ringAppend(&rShoulderAngles, rSA, limit: smoothWindow)

        let LwY = avg(lwY), RwY = avg(rwY), LsY = avg(lsY), RsY = avg(rsY)
        let leftSA = avg(lShoulderAngles), rightSA = avg(rShoulderAngles)
        guard [LwY, RwY, LsY, RsY, leftSA, rightSA].allSatisfy({ $0.isFinite }) else { formHint = nil; return [] }

        let sw = abs(rs.x - ls.x)

        // Horizontal distance: wrists must be outside the shoulders by a margin
        let leftLateral  = (ls.x - lw.x)             // > 0 when wrist is left of left shoulder
        let rightLateral = (rw.x - rs.x)             // > 0 when wrist is right of right shoulder
        let lateralOK  = (leftLateral  > lateralMinFactor * sw) && (rightLateral > lateralMinFactor * sw)

        // Height band around shoulder level
        let levelLeft  = abs(LwY - LsY) <= shoulderHeightBand
        let levelRight = abs(RwY - RsY) <= shoulderHeightBand
        let heightOK   = levelLeft && levelRight

        // Arms should be close to straight out from the shoulder
        let straightOK = (leftSA >= straightAngleMin) && (rightSA >= straightAngleMin)

        let tPose = lateralOK && heightOK && straightOK
        let armsDown = (LwY > LsY + 0.06) && (RwY > RsY + 0.06)

        // Form hints
        if !lateralOK {
            formHint = "Move arms out to the sides (past shoulder lines)"
        } else if !heightOK {
            formHint = "Keep wrists at shoulder height (on band)"
        } else if !straightOK {
            formHint = "Straighten elbows (no bending)"
        } else {
            formHint = nil
        }

        switch phase {
        case .unknown:
            phase = tPose ? .up : .down
        case .down:
            if tPose { phase = .up }
        case .up:
            if armsDown {
                count += 1
                phase = .down
                return [DetectedRep(workout: kind, timestamp: time)]
            }
        }
        return []
    }
}

// MARK: - NEW DETECTORS

// Front Raises: wrists lift straight forward to shoulder height (centered), then lower
struct FrontRaisesDetector: WorkoutDetector {
    enum Phase { case unknown, down, up }
    let kind: WorkoutKind = .frontRaises
    private(set) var count = 0
    private(set) var phase: Phase = .unknown
    private(set) var formHint: String? = nil

    var shoulderBand: CGFloat = 0.04
    var downMargin: CGFloat = 0.10
    var centerFactor: CGFloat = 0.80 // wrists should be within center zone between shoulders
    var smoothWindow = 5

    private var lwY: [CGFloat] = [], rwY: [CGFloat] = [], lsY: [CGFloat] = [], rsY: [CGFloat] = []

    var phaseDescription: String { phase == .up ? "UP" : (phase == .down ? "DOWN" : "—") }

    mutating func reset() { count = 0; phase = .unknown; formHint = nil; lwY.removeAll(); rwY.removeAll(); lsY.removeAll(); rsY.removeAll() }

    mutating func update(joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
                         time: TimeInterval) -> [DetectedRep] {
        guard let lw = joints[.leftWrist], let rw = joints[.rightWrist],
              let ls = joints[.leftShoulder], let rs = joints[.rightShoulder] else { formHint = "Show shoulders & wrists"; return [] }

        ringAppend(&lwY, lw.y, limit: smoothWindow)
        ringAppend(&rwY, rw.y, limit: smoothWindow)
        ringAppend(&lsY, ls.y, limit: smoothWindow)
        ringAppend(&rsY, rs.y, limit: smoothWindow)

        let LwY = avg(lwY), RwY = avg(rwY), LsY = avg(lsY), RsY = avg(rsY)
        guard [LwY, RwY, LsY, RsY].allSatisfy({ $0.isFinite }) else { return [] }

        let shoulderY = (LsY + RsY) / 2
        let sw = abs(rs.x - ls.x)
        let centerX0 = min(ls.x, rs.x) + (1 - centerFactor) * sw / 2
        let centerX1 = max(ls.x, rs.x) - (1 - centerFactor) * sw / 2
        let centered = (lw.x > centerX0 && lw.x < centerX1 && rw.x > centerX0 && rw.x < centerX1)
        let atShoulder = abs(LwY - shoulderY) <= shoulderBand && abs(RwY - shoulderY) <= shoulderBand
        let armsDown = (LwY > shoulderY + downMargin) && (RwY > shoulderY + downMargin)

        // Hints
        if !centered { formHint = "Raise arms in front (centered over chest)" }
        else if !atShoulder && phase == .down { formHint = "Lift to shoulder height band" }
        else { formHint = nil }

        switch phase {
        case .unknown: phase = armsDown ? .down : (atShoulder && centered ? .up : .down)
        case .down: if atShoulder && centered { phase = .up }
        case .up:
            if armsDown {
                count += 1
                phase = .down
                return [DetectedRep(workout: kind, timestamp: time)]
            }
        }
        return []
    }
}

// Overhead Press: wrists start at shoulder height, press to above-head band, return to shoulder
struct OverheadPressDetector: WorkoutDetector {
    enum Phase { case unknown, down, up }
    let kind: WorkoutKind = .overheadPress
    private(set) var count = 0
    private(set) var phase: Phase = .unknown
    private(set) var formHint: String? = nil

    var shoulderBand: CGFloat = 0.04
    var headMargin: CGFloat = 0.05
    var smoothWindow = 5

    private var lwY: [CGFloat] = [], rwY: [CGFloat] = [], lsY: [CGFloat] = [], rsY: [CGFloat] = [], headY: [CGFloat] = []

    var phaseDescription: String { phase == .up ? "UP" : (phase == .down ? "DOWN" : "—") }

    mutating func reset() { count = 0; phase = .unknown; formHint = nil; lwY.removeAll(); rwY.removeAll(); lsY.removeAll(); rsY.removeAll(); headY.removeAll() }

    mutating func update(joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
                         time: TimeInterval) -> [DetectedRep] {
        guard let lw = joints[.leftWrist], let rw = joints[.rightWrist],
              let ls = joints[.leftShoulder], let rs = joints[.rightShoulder],
              let nose = joints[.nose] ?? joints[.neck] else { formHint = "Show shoulders, wrists, head"; return [] }

        ringAppend(&lwY, lw.y, limit: smoothWindow)
        ringAppend(&rwY, rw.y, limit: smoothWindow)
        ringAppend(&lsY, ls.y, limit: smoothWindow)
        ringAppend(&rsY, rs.y, limit: smoothWindow)
        ringAppend(&headY, nose.y, limit: smoothWindow)

        let LwY = avg(lwY), RwY = avg(rwY), LsY = avg(lsY), RsY = avg(rsY), hY = avg(headY)
        guard [LwY, RwY, LsY, RsY, hY].allSatisfy({ $0.isFinite }) else { return [] }

        let shoulderY = (LsY + RsY) / 2
        let atShoulder = abs(LwY - shoulderY) <= shoulderBand && abs(RwY - shoulderY) <= shoulderBand
        let aboveHead  = (LwY < hY - headMargin) && (RwY < hY - headMargin)

        // Hints
        if phase == .down && !aboveHead { formHint = "Press straight up (wrists above head band)" }
        else if phase == .up && !atShoulder { formHint = "Return to shoulder band" }
        else { formHint = nil }

        switch phase {
        case .unknown: phase = atShoulder ? .down : (aboveHead ? .up : .down)
        case .down: if aboveHead { phase = .up }
        case .up:
            if atShoulder {
                count += 1
                phase = .down
                return [DetectedRep(workout: kind, timestamp: time)]
            }
        }
        return []
    }
}

// Side Steps: feet together -> apart -> together (JJ legs only)
struct SideStepsDetector: WorkoutDetector {
    enum Phase { case unknown, together, apart }
    let kind: WorkoutKind = .sideSteps
    private(set) var count = 0
    private(set) var phase: Phase = .unknown
    private(set) var formHint: String? = nil

    var apartFactor: CGFloat = 1.05
    var togetherFactor: CGFloat = 0.85
    var smoothWindow = 5
    private var shoulderW: [CGFloat] = [], ankleGap: [CGFloat] = []

    var phaseDescription: String { phase == .apart ? "APART" : (phase == .together ? "TOGETHER" : "—") }

    mutating func reset() { count = 0; phase = .unknown; formHint = nil; shoulderW.removeAll(); ankleGap.removeAll() }

    mutating func update(joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
                         time: TimeInterval) -> [DetectedRep] {
        guard let ls = joints[.leftShoulder], let rs = joints[.rightShoulder],
              let la = joints[.leftAnkle], let ra = joints[.rightAnkle]
        else { formHint = "Show shoulders & ankles"; return [] }

        ringAppend(&shoulderW, PoseMath.dist(ls, rs), limit: smoothWindow)
        ringAppend(&ankleGap, PoseMath.dist(la, ra), limit: smoothWindow)

        let sw = avg(shoulderW), ag = avg(ankleGap)
        guard sw.isFinite, ag.isFinite else { return [] }

        let apart = ag > apartFactor * sw
        let together = ag < togetherFactor * sw

        if phase == .together && !apart { formHint = "Step wider (to lines)" }
        else if phase == .apart && !together { formHint = "Step feet together" }
        else { formHint = nil }

        switch phase {
        case .unknown: phase = apart ? .apart : .together
        case .together:
            if apart { phase = .apart }
        case .apart:
            if together {
                count += 1
                phase = .together
                return [DetectedRep(workout: kind, timestamp: time)]
            }
        }
        return []
    }
}

// Cross Knee-to-Elbow: left knee to right elbow OR right knee to left elbow (alternating)
struct CrossCrunchDetector: WorkoutDetector {
    let kind: WorkoutKind = .crossCrunch
    private(set) var count = 0
    private(set) var formHint: String? = nil
    var phaseDescription: String { "—" }

    var hitThresholdFactor: CGFloat = 0.55 // distance threshold × shoulder width
    var cooldown: TimeInterval = 0.35
    var smoothWindow = 3

    private var shoulderW: [CGFloat] = []
    private var lastLeftHit: TimeInterval = 0
    private var lastRightHit: TimeInterval = 0

    mutating func reset() {
        count = 0; formHint = nil
        shoulderW.removeAll()
        lastLeftHit = 0; lastRightHit = 0
    }

    mutating func update(joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
                         time: TimeInterval) -> [DetectedRep] {
        guard let ls = joints[.leftShoulder], let rs = joints[.rightShoulder],
              let lk = joints[.leftKnee], let rk = joints[.rightKnee],
              let le = joints[.leftElbow], let re = joints[.rightElbow] else {
            formHint = "Show shoulders, knees, elbows"; return []
        }
        ringAppend(&shoulderW, PoseMath.dist(ls, rs), limit: smoothWindow)
        let sw = avg(shoulderW)
        guard sw.isFinite else { return [] }

        var events: [DetectedRep] = []
        let leftKneeToRightElbow  = PoseMath.dist(lk, re)
        let rightKneeToLeftElbow  = PoseMath.dist(rk, le)
        let thresh = hitThresholdFactor * sw

        if leftKneeToRightElbow < thresh {
            if time - lastLeftHit > cooldown {
                count += 1; lastLeftHit = time
                events.append(DetectedRep(workout: kind, timestamp: time))
            }
            formHint = nil
        } else if rightKneeToLeftElbow < thresh {
            if time - lastRightHit > cooldown {
                count += 1; lastRightHit = time
                events.append(DetectedRep(workout: kind, timestamp: time))
            }
            formHint = nil
        } else {
            formHint = "Bring knee to opposite elbow (touch inside the X)"
        }
        return events
    }
}

// Standing Twists: both wrists travel together to one side at shoulder height, then to the other side
struct StandingTwistsDetector: WorkoutDetector {
    enum Phase { case unknown, center, leftSide, rightSide }
    let kind: WorkoutKind = .standingTwists
    private(set) var count = 0
    private(set) var phase: Phase = .unknown
    private(set) var formHint: String? = nil

    var shoulderBand: CGFloat = 0.05
    var sideMarginFactor: CGFloat = 0.15 // how far past center to count as a side
    var smoothWindow = 5

    private var lwY: [CGFloat] = [], rwY: [CGFloat] = [], lsY: [CGFloat] = [], rsY: [CGFloat] = []

    var phaseDescription: String {
        switch phase { case .leftSide: return "LEFT"; case .rightSide: return "RIGHT"; case .center: return "CENTER"; case .unknown: return "—" }
    }

    mutating func reset() { count = 0; phase = .unknown; formHint = nil; lwY.removeAll(); rwY.removeAll(); lsY.removeAll(); rsY.removeAll() }

    mutating func update(joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
                         time: TimeInterval) -> [DetectedRep] {
        guard let lw = joints[.leftWrist], let rw = joints[.rightWrist],
              let ls = joints[.leftShoulder], let rs = joints[.rightShoulder] else { formHint = "Show wrists & shoulders"; return [] }

        ringAppend(&lwY, lw.y, limit: smoothWindow)
        ringAppend(&rwY, rw.y, limit: smoothWindow)
        ringAppend(&lsY, ls.y, limit: smoothWindow)
        ringAppend(&rsY, rs.y, limit: smoothWindow)

        let LwY = avg(lwY), RwY = avg(rwY), LsY = avg(lsY), RsY = avg(rsY)
        guard [LwY, RwY, LsY, RsY].allSatisfy({ $0.isFinite }) else { return [] }

        let shoulderY = (LsY + RsY) / 2
        let heightOK = abs(LwY - shoulderY) <= shoulderBand && abs(RwY - shoulderY) <= shoulderBand
        let centerX = (ls.x + rs.x) / 2
        let sw = abs(rs.x - ls.x)
        let margin = sideMarginFactor * sw

        let bothRight = (lw.x > centerX + margin) && (rw.x > centerX + margin)
        let bothLeft  = (lw.x < centerX - margin) && (rw.x < centerX - margin)
        let centered  = (lw.x >= centerX - margin) && (lw.x <= centerX + margin) &&
                        (rw.x >= centerX - margin) && (rw.x <= centerX + margin)

        if !heightOK { formHint = "Keep hands at shoulder height" }
        else { formHint = nil }

        switch phase {
        case .unknown: phase = centered ? .center : (bothLeft ? .leftSide : (bothRight ? .rightSide : .center))
        case .center:
            if bothLeft { phase = .leftSide }
            else if bothRight { phase = .rightSide }
        case .leftSide:
            if bothRight {
                count += 1
                phase = .rightSide
                return [DetectedRep(workout: kind, timestamp: time)]
            } else if centered { phase = .center }
        case .rightSide:
            if bothLeft {
                count += 1
                phase = .leftSide
                return [DetectedRep(workout: kind, timestamp: time)]
            } else if centered { phase = .center }
        }
        return []
    }
}

// MARK: - Camera ViewModel

final class CameraViewModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let videoOutputQueue = DispatchQueue(label: "videoDataOutputQueue")
    private let videoDataOutput = AVCaptureVideoDataOutput()

    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?

    func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.setupCamera() }
            }
        default:
            print("Camera permission denied")
        }
    }

    private func setupCamera() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                print("Failed to create video input")
                self.session.commitConfiguration()
                return
            }
            if self.session.canAddInput(input) { self.session.addInput(input) }

            self.videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            self.videoDataOutput.setSampleBufferDelegate(self.delegate, queue: self.videoOutputQueue)
            if self.session.canAddOutput(self.videoDataOutput) { self.session.addOutput(self.videoDataOutput) }

            if let connection = self.videoDataOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
                connection.isVideoMirrored = true
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = PreviewContainerView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.connection?.videoOrientation = .portrait
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? PreviewContainerView)?.previewLayer.frame = uiView.bounds
    }
    final class PreviewContainerView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Pose Overlay (skeleton)

struct BodyConnection: Identifiable {
    let id = UUID()
    let from: VNHumanBodyPoseObservation.JointName
    let to: VNHumanBodyPoseObservation.JointName
}

struct PoseOverlayView: View {
    let bodyParts: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let connections: [BodyConnection]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(connections) { c in
                    if let a = bodyParts[c.from], let b = bodyParts[c.to] {
                        Path { p in
                            p.move(to: CGPoint(x: a.x * geo.size.width, y: a.y * geo.size.height))
                            p.addLine(to: CGPoint(x: b.x * geo.size.width, y: b.y * geo.size.height))
                        }
                        .stroke(.green, lineWidth: 3)
                    }
                }
                ForEach(Array(bodyParts.keys), id: \.self) { name in
                    if let pt = bodyParts[name] {
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10)
                            .position(x: pt.x * geo.size.width, y: pt.y * geo.size.height)
                            .overlay(Circle().stroke(.white, lineWidth: 1).frame(width: 12, height: 12))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Guides Overlay (visual targets per workout)

struct GuidesOverlayView: View {
    let workout: WorkoutKind
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]

    private func rectNorm(x0: CGFloat, x1: CGFloat, y0: CGFloat, y1: CGFloat, _ size: CGSize) -> CGRect {
        CGRect(x: x0 * size.width, y: y0 * size.height,
               width: (x1 - x0) * size.width, height: (y1 - y0) * size.height)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch workout {
                case .armRaises:
                    if let ls = joints[.leftShoulder], let rs = joints[.rightShoulder] {
                        let y = (ls.y + rs.y) / 2
                        let sw = abs(rs.x - ls.x)
                        let bandH: CGFloat = 0.045
                        let lateralMin: CGFloat = 0.50 * sw
                        let band = rectNorm(x0: 0, x1: 1, y0: y - bandH/2, y1: y + bandH/2, geo.size)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4])).foregroundColor(.blue))
                            .frame(width: band.width, height: band.height)
                            .position(x: band.midX, y: band.midY)
                        // Lateral zones
                        let leftX1 = max(0, ls.x - lateralMin)
                        let rightX0 = min(1, rs.x + lateralMin)
                        let leftZone = rectNorm(x0: 0, x1: leftX1, y0: y - bandH/2, y1: y + bandH/2, geo.size)
                        let rightZone = rectNorm(x0: rightX0, x1: 1, y0: y - bandH/2, y1: y + bandH/2, geo.size)
                        ForEach([leftZone, rightZone], id: \.self) { r in
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                .foregroundColor(.blue)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.10)))
                                .frame(width: r.width, height: r.height)
                                .position(x: r.midX, y: r.midY)
                        }
                    }

                case .frontRaises:
                    if let ls = joints[.leftShoulder], let rs = joints[.rightShoulder] {
                        let y = (ls.y + rs.y) / 2
                        let bandH: CGFloat = 0.04
                        let band = rectNorm(x0: 0.2, x1: 0.8, y0: y - bandH/2, y1: y + bandH/2, geo.size)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.teal.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4])).foregroundColor(.teal))
                            .frame(width: band.width, height: band.height)
                            .position(x: band.midX, y: band.midY)
                    }

                case .overheadPress, .jumpingJack:
                    if let nose = joints[.nose] ?? joints[.neck] {
                        let headBandY = nose.y - 0.05
                        let bandH: CGFloat = 0.02
                        let headBand = rectNorm(x0: 0.05, x1: 0.95, y0: headBandY - bandH/2, y1: headBandY + bandH/2, geo.size)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.cyan.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4])).foregroundColor(.cyan))
                            .frame(width: headBand.width, height: headBand.height)
                            .position(x: headBand.midX, y: headBand.midY)
                    }
                    // For jumping jacks, we also add foot lines like below
                    if workout == .jumpingJack, let ls = joints[.leftShoulder], let rs = joints[.rightShoulder] {
                        let sw = abs(rs.x - ls.x)
                        let centerX = (ls.x + rs.x)/2
                        let halfReq = (1.12 * sw) / 2
                        let leftX = max(0.05, centerX - halfReq)
                        let rightX = min(0.95, centerX + halfReq)
                        Path { p in
                            p.move(to: CGPoint(x: leftX * geo.size.width, y: 0.1 * geo.size.height))
                            p.addLine(to: CGPoint(x: leftX * geo.size.width, y: 0.9 * geo.size.height))
                        }.stroke(Color.cyan, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        Path { p in
                            p.move(to: CGPoint(x: rightX * geo.size.width, y: 0.1 * geo.size.height))
                            p.addLine(to: CGPoint(x: rightX * geo.size.width, y: 0.9 * geo.size.height))
                        }.stroke(Color.cyan, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    }

                case .sideSteps:
                    if let ls = joints[.leftShoulder], let rs = joints[.rightShoulder] {
                        let sw = abs(rs.x - ls.x)
                        let centerX = (ls.x + rs.x)/2
                        let halfReq = (1.05 * sw) / 2
                        let leftX = max(0.05, centerX - halfReq)
                        let rightX = min(0.95, centerX + halfReq)
                        Path { p in
                            p.move(to: CGPoint(x: leftX * geo.size.width, y: 0.1 * geo.size.height))
                            p.addLine(to: CGPoint(x: leftX * geo.size.width, y: 0.9 * geo.size.height))
                        }.stroke(Color.mint, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        Path { p in
                            p.move(to: CGPoint(x: rightX * geo.size.width, y: 0.1 * geo.size.height))
                            p.addLine(to: CGPoint(x: rightX * geo.size.width, y: 0.9 * geo.size.height))
                        }.stroke(Color.mint, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    }

                case .crossCrunch:
                    // Draw an "X" zone in mid torso to suggest target area
                    if let ls = joints[.leftShoulder], let rs = joints[.rightShoulder],
                       let lh = joints[.leftHip], let rh = joints[.rightHip] {
                        let cx = (ls.x + rs.x + lh.x + rh.x) / 4
                        let cy = (ls.y + rs.y + lh.y + rh.y) / 4
                        let sizeW: CGFloat = 0.18, sizeH: CGFloat = 0.18
                        let rect = rectNorm(x0: cx - sizeW/2, x1: cx + sizeW/2, y0: cy - sizeH/2, y1: cy + sizeH/2, geo.size)
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            .foregroundColor(.purple)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                    }

                case .squat:
                    if let lk = joints[.leftKnee], let rk = joints[.rightKnee] {
                        let y = (lk.y + rk.y) / 2
                        let bandH: CGFloat = 0.02
                        let band = rectNorm(x0: 0.1, x1: 0.9, y0: y - bandH/2, y1: y + bandH/2, geo.size)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4])).foregroundColor(.orange))
                            .frame(width: band.width, height: band.height)
                            .position(x: band.midX, y: band.midY)
                    }

                case .pushUp:
                    if let ls = joints[.leftShoulder], let rs = joints[.rightShoulder] {
                        let y = (ls.y + rs.y) / 2
                        let bandH: CGFloat = 0.01
                        let band = rectNorm(x0: 0.25, x1: 0.75, y0: y - bandH/2, y1: y + bandH/2, geo.size)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.red.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 4])).foregroundColor(.red))
                            .frame(width: band.width, height: band.height)
                            .position(x: band.midX, y: band.midY)
                    }

                case .highKnees, .standingTwists:
                    if let lh = joints[.leftHip], let rh = joints[.rightHip] {
                        let yL = lh.y - 0.03
                        let yR = rh.y - 0.03
                        let bandH: CGFloat = 0.01
                        let leftBand  = rectNorm(x0: 0.05, x1: 0.45, y0: yL - bandH/2, y1: yL + bandH/2, geo.size)
                        let rightBand = rectNorm(x0: 0.55, x1: 0.95, y0: yR - bandH/2, y1: yR + bandH/2, geo.size)
                        ForEach([leftBand, rightBand], id: \.self) { r in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.purple.opacity(0.15))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 4])).foregroundColor(.purple))
                                .frame(width: r.width, height: r.height)
                                .position(x: r.midX, y: r.midY)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Pose Estimation VM

final class PoseEstimationViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var detectedBodyParts: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published private(set) var bodyConnections: [BodyConnection] = []
    @Published var selectedWorkout: WorkoutKind = .armRaises {
        didSet { resetSelected() }
    }

    // UI
    @Published private(set) var currentCount: Int = 0
    @Published private(set) var currentPhase: String = "—"
    @Published private(set) var lastRep: DetectedRep? = nil

    // Warnings & form hints
    @Published var trackingWarning: String? = nil
    @Published var proximityWarning: String? = nil
    @Published var formWarning: String? = nil

    // Detectors
    private var jjDetector = JumpingJackDetector()
    private var pushDetector = PushUpDetector()
    private var squatDetector = SquatDetector()
    private var highKneesDetector = HighKneesDetector()
    private var armRaisesDetector = ArmRaisesDetector()

    // New
    private var frontRaisesDetector = FrontRaisesDetector()
    private var overheadPressDetector = OverheadPressDetector()
    private var sideStepsDetector = SideStepsDetector()
    private var crossCrunchDetector = CrossCrunchDetector()
    private var standingTwistsDetector = StandingTwistsDetector()

    private let minConfidence: Float = 0.5
    private let request = VNDetectHumanBodyPoseRequest()
    private var framesSincePose: Int = 0
    private let lostThresholdFrames = 12 // ~0.2s @ 60fps

    override init() {
        super.init()
        setupConnections()
    }

    func resetSelected() {
        switch selectedWorkout {
        case .jumpingJack: jjDetector.reset()
        case .pushUp:      pushDetector.reset()
        case .squat:       squatDetector.reset()
        case .highKnees:   highKneesDetector.reset()
        case .armRaises:   armRaisesDetector.reset()
        case .frontRaises: frontRaisesDetector.reset()
        case .overheadPress: overheadPressDetector.reset()
        case .sideSteps:   sideStepsDetector.reset()
        case .crossCrunch: crossCrunchDetector.reset()
        case .standingTwists: standingTwistsDetector.reset()
        }
        currentCount = 0
        currentPhase = "—"
        lastRep = nil
        trackingWarning = nil
        proximityWarning = nil
        formWarning = nil
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)

        do {
            try handler.perform([request])
            guard let obs = request.results?.first as? VNHumanBodyPoseObservation else {
                framesSincePose += 1
                updateWarningsForMissingPose()
                return
            }
            framesSincePose = 0

            let joints = extractPoints(from: obs)
            let now = CACurrentMediaTime()

            // Proximity (too close) warning
            updateProximityWarning(joints: joints)

            var events: [DetectedRep] = []
            var phase = "—"
            var count = 0
            var formHint: String? = nil

            switch selectedWorkout {
            case .jumpingJack:
                events = jjDetector.update(joints: joints, time: now)
                phase = jjDetector.phaseDescription
                count = jjDetector.count
                formHint = jjDetector.formHint
            case .pushUp:
                events = pushDetector.update(joints: joints, time: now)
                phase = pushDetector.phaseDescription
                count = pushDetector.count
                formHint = pushDetector.formHint
            case .squat:
                events = squatDetector.update(joints: joints, time: now)
                phase = squatDetector.phaseDescription
                count = squatDetector.count
                formHint = squatDetector.formHint
            case .highKnees:
                events = highKneesDetector.update(joints: joints, time: now)
                phase = highKneesDetector.phaseDescription
                count = highKneesDetector.count
                formHint = highKneesDetector.formHint
            case .armRaises:
                events = armRaisesDetector.update(joints: joints, time: now)
                phase = armRaisesDetector.phaseDescription
                count = armRaisesDetector.count
                formHint = armRaisesDetector.formHint

            case .frontRaises:
                events = frontRaisesDetector.update(joints: joints, time: now)
                phase = frontRaisesDetector.phaseDescription
                count = frontRaisesDetector.count
                formHint = frontRaisesDetector.formHint

            case .overheadPress:
                events = overheadPressDetector.update(joints: joints, time: now)
                phase = overheadPressDetector.phaseDescription
                count = overheadPressDetector.count
                formHint = overheadPressDetector.formHint

            case .sideSteps:
                events = sideStepsDetector.update(joints: joints, time: now)
                phase = sideStepsDetector.phaseDescription
                count = sideStepsDetector.count
                formHint = sideStepsDetector.formHint

            case .crossCrunch:
                events = crossCrunchDetector.update(joints: joints, time: now)
                phase = "—"
                count = crossCrunchDetector.count
                formHint = crossCrunchDetector.formHint

            case .standingTwists:
                events = standingTwistsDetector.update(joints: joints, time: now)
                phase = standingTwistsDetector.phaseDescription
                count = standingTwistsDetector.count
                formHint = standingTwistsDetector.formHint
            }

            DispatchQueue.main.async {
                self.detectedBodyParts = joints
                self.currentCount = count
                self.currentPhase = phase
                self.formWarning = formHint
                if let e = events.last { self.lastRep = e }
                self.trackingWarning = nil // got a pose this frame
            }
        } catch {
            // ignore per-frame errors
        }
    }

    private func extractPoints(from observation: VNHumanBodyPoseObservation)
    -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        var dict: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        guard let allPoints = try? observation.recognizedPoints(.all) else { return dict }
        for (name, point) in allPoints {
            if point.confidence >= minConfidence {
                dict[name] = CGPoint(x: CGFloat(point.x), y: 1 - CGFloat(point.y)) // flip to top-left origin
            }
        }
        return dict
    }

    private func updateWarningsForMissingPose() {
        if framesSincePose >= lostThresholdFrames {
            DispatchQueue.main.async {
                self.trackingWarning = "Can’t see your full body. Step back and face the camera."
            }
        }
    }

    private func updateProximityWarning(joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        guard let ls = joints[.leftShoulder], let rs = joints[.rightShoulder] else {
            DispatchQueue.main.async { self.proximityWarning = nil }
            return
        }
        let shoulderW = PoseMath.dist(ls, rs)
        let hipW: CGFloat = {
            if let lh = joints[.leftHip], let rh = joints[.rightHip] { return PoseMath.dist(lh, rh) }
            return 0
        }()
        let ankleGap: CGFloat = {
            if let la = joints[.leftAnkle], let ra = joints[.rightAnkle] { return PoseMath.dist(la, ra) }
            return 0
        }()

        // If any width is very large in normalized space, you're too close
        let tooClose = max(shoulderW, hipW, ankleGap) > 0.55
        DispatchQueue.main.async {
            self.proximityWarning = tooClose ? "Too close for tracking — move back a little." : nil
        }
    }

    private func setupConnections() {
        bodyConnections = [
            BodyConnection(from: .nose, to: .neck),
            BodyConnection(from: .neck, to: .rightShoulder),
            BodyConnection(from: .neck, to: .leftShoulder),
            BodyConnection(from: .rightShoulder, to: .rightHip),
            BodyConnection(from: .leftShoulder, to: .leftHip),
            BodyConnection(from: .rightHip, to: .leftHip),
            BodyConnection(from: .rightShoulder, to: .rightElbow),
            BodyConnection(from: .rightElbow, to: .rightWrist),
            BodyConnection(from: .leftShoulder, to: .leftElbow),
            BodyConnection(from: .leftElbow, to: .leftWrist),
            BodyConnection(from: .rightHip, to: .rightKnee),
            BodyConnection(from: .rightKnee, to: .rightAnkle),
            BodyConnection(from: .leftHip, to: .leftKnee),
            BodyConnection(from: .leftKnee, to: .leftAnkle)
        ]
    }
}

// MARK: - UI

private struct BigCenterCounter: View {
    let count: Int
    var body: some View {
        Text("\(count)")
            .font(.system(size: 120, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .shadow(radius: 8)
            .padding(.vertical, 8)
            .padding(.horizontal, 18)
            .background(.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct WarningBanner: View {
    enum Kind { case danger, warn }
    let text: String
    let kind: Kind
    var body: some View {
        Text(text)
            .font(.callout).bold()
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(kind == .danger ? Color.red.opacity(0.95) : Color.orange.opacity(0.95))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 4)
    }
}

private struct PhaseCapsule: View {
    let phase: String
    var body: some View {
        Text(phase)
            .font(.caption).bold()
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.white.opacity(0.2))
            .clipShape(Capsule())
            .foregroundStyle(.white)
    }
}

struct PoseCameraView: View {
    @StateObject private var cameraVM = CameraViewModel()
    @StateObject private var poseVM = PoseEstimationViewModel()

    var body: some View {
        ZStack {
            CameraPreviewView(session: cameraVM.session).ignoresSafeArea()

            // Guides first so skeleton sits on top
            GuidesOverlayView(workout: poseVM.selectedWorkout, joints: poseVM.detectedBodyParts)
                .ignoresSafeArea()

            PoseOverlayView(bodyParts: poseVM.detectedBodyParts, connections: poseVM.bodyConnections)
                .ignoresSafeArea()

            // Top banners (tracking / proximity / form)
            VStack(spacing: 8) {
                if let warn = poseVM.trackingWarning { WarningBanner(text: warn, kind: .danger) }
                if let near = poseVM.proximityWarning { WarningBanner(text: near, kind: .danger) }
                if let form = poseVM.formWarning { WarningBanner(text: form, kind: .warn) }
                Spacer()
            }
            .padding(.top, 12)

            // Big center counter
            VStack {
                Spacer()
                BigCenterCounter(count: poseVM.currentCount)
                Spacer()
            }

            // Bottom control bar
            VStack {
                Spacer()
                HStack(spacing: 12) {

                    // Menu-style picker (replaces segmented control)
                    Picker("Workout", selection: $poseVM.selectedWorkout) {
                        ForEach(WorkoutKind.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelStyle(.titleOnly)

                    Spacer(minLength: 12)

                    PhaseCapsule(phase: poseVM.currentPhase)

                    Button {
                        poseVM.resetSelected()
                    } label: {
                        Text("Reset").bold()
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundStyle(.white)
                    }
                }
                .padding()
                .background(.black.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
            }
        }
        .onAppear {
            cameraVM.delegate = poseVM
            cameraVM.checkPermissionAndStart()
        }
    }
}
