import Foundation

struct UserModel {
    let id: UUID
    let email: String
    let name: String
    let accessToken: String
    
    init(id: UUID, email: String, name: String, accessToken: String) {
        self.id = id
        self.email = email
        self.name = name
        self.accessToken = accessToken
    }
}
