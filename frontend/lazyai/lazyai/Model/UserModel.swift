import Foundation
import GoogleSignIn

struct UserModel {
    let id: String
    let email: String
    let name: String
    let profileImageUrl: String?
    
    init(id: String, email: String, name: String, profileImageUrl: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.profileImageUrl = profileImageUrl
    }
}
