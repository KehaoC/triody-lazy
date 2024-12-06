import Foundation
import SwiftUI

@MainActor
class UserViewModel: ObservableObject {
    
    // 状态
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isAuthenticated = false

    // 用户信息
    @Published var user: UserModel?
    
    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true 
        defer { isLoading = false }

        if isFormValid(email: email, password: password) {
            do {
                self.user = try await AuthManager.shared.signInWithEmail(email: email, password: password)
                print(self.user?.accessToken ?? "no access token")
                if let token = self.user?.accessToken {
                    try KeychainManager.save(token: token)
                }
                isAuthenticated = true
            } catch {
                print("Sign in failed: \(error)")
                throw error
            }
        } else {
            print("Form is not valid")
            throw NSError()
        }
    }
    
    func signUpWithEmail(email: String, password: String) async throws {
        isLoading = true 
        defer { isLoading = false }
        if isFormValid(email: email, password: password) {
            self.user = try await AuthManager.shared.signUpWithEmail(email: email, password: password)
            print("Sign up success")
        } else {
            print("Form is not valid")
            throw NSError()
        }
    }

    func signOut() async throws {
        try await AuthManager.shared.signOut()
        try KeychainManager.deleteToken()
        isAuthenticated = false
    }

    func isFormValid(email: String, password: String) -> Bool {
        guard email.isValidEmail() else {
            return false
        }
        return true
    }

    var accessToken: String? {
        return user?.accessToken
    }
}

extension String {
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}
