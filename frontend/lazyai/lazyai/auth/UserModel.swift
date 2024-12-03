import Foundation

struct UserModel {
    let id: String
    let email: String
    let name: String
    
    init(id: String, email: String, name: String) {
        self.id = id
        self.email = email
        self.name = name
    }
}
