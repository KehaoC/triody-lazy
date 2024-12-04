import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct NiumaModel: Codable, Identifiable {
    var id: Int
    var name: String
    var avatar: String
    var description: String
    var taskId: Int?
    var progress: Double = 0.0
}