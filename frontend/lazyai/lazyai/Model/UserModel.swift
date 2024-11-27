import Foundation

struct UserModel: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let password: String
    
    // 将 user_id 映射为 id
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name
        case email
        case password
    }
}