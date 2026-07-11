import CoreGraphics

enum WindowLayout: String, CaseIterable, Identifiable {
    case leftThird
    case centerThird
    case rightThird

    case quarter1
    case quarter2
    case quarter3
    case quarter4

    case leftTwoThirds
    case rightTwoThirds

    case leftHalf
    case rightHalf
    case centerHalf

    case twentyFiveFiftyTwentyFiveLeft
    case twentyFiveFiftyTwentyFiveCenter
    case twentyFiveFiftyTwentyFiveRight

    case maximizeVisibleArea

    var id: String { rawValue }

    /// Horizontal span of the layout, expressed as fractions of the usable width.
    var region: LayoutRegion {
        switch self {
        case .leftThird: return LayoutRegion(start: 0, end: 1 / 3)
        case .centerThird: return LayoutRegion(start: 1 / 3, end: 2 / 3)
        case .rightThird: return LayoutRegion(start: 2 / 3, end: 1)
        case .quarter1: return LayoutRegion(start: 0, end: 0.25)
        case .quarter2: return LayoutRegion(start: 0.25, end: 0.5)
        case .quarter3: return LayoutRegion(start: 0.5, end: 0.75)
        case .quarter4: return LayoutRegion(start: 0.75, end: 1)
        case .leftTwoThirds: return LayoutRegion(start: 0, end: 2 / 3)
        case .rightTwoThirds: return LayoutRegion(start: 1 / 3, end: 1)
        case .leftHalf: return LayoutRegion(start: 0, end: 0.5)
        case .rightHalf: return LayoutRegion(start: 0.5, end: 1)
        case .centerHalf: return LayoutRegion(start: 0.25, end: 0.75)
        case .twentyFiveFiftyTwentyFiveLeft: return LayoutRegion(start: 0, end: 0.25)
        case .twentyFiveFiftyTwentyFiveCenter: return LayoutRegion(start: 0.25, end: 0.75)
        case .twentyFiveFiftyTwentyFiveRight: return LayoutRegion(start: 0.75, end: 1)
        case .maximizeVisibleArea: return LayoutRegion(start: 0, end: 1)
        }
    }

    var displayName: String {
        switch self {
        case .leftThird: return "Left Third"
        case .centerThird: return "Centre Third"
        case .rightThird: return "Right Third"
        case .quarter1: return "Quarter 1"
        case .quarter2: return "Quarter 2"
        case .quarter3: return "Quarter 3"
        case .quarter4: return "Quarter 4"
        case .leftTwoThirds: return "Left Two Thirds"
        case .rightTwoThirds: return "Right Two Thirds"
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        case .centerHalf: return "Centre Half"
        case .twentyFiveFiftyTwentyFiveLeft: return "25 / 50 / 25 - Left"
        case .twentyFiveFiftyTwentyFiveCenter: return "25 / 50 / 25 - Centre"
        case .twentyFiveFiftyTwentyFiveRight: return "25 / 50 / 25 - Right"
        case .maximizeVisibleArea: return "Maximize to Visible Area"
        }
    }
}
