import Foundation
import SwiftUI
@MainActor
class UserViewModel: ObservableObject {
    // 输入值
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    
    // 状态
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isAuthenticated = false

    // 用户信息
    @Published var accessToken: String?  // TODO: 添加 accessToken 的逻辑
    @Published var user: UserModel?
    
    func signInWithEmail() async throws {
        isLoading = true 
        defer { isLoading = false }

        if isFormValid(email: email, password: password) {
            self.user = try await AuthManager.shared.signInWithEmail(email: email, password: password)
            print("Sign in success")
            isAuthenticated = true
        } else {
            print("Form is not valid")
            throw NSError()
        }
    }
    
    // TODO: 注册的时候能直接拿到 token 吗
    func signUpWithEmail() async throws {
        isLoading = true 
        defer { isLoading = false }
        if isFormValid(email: email, password: password) {
            self.user = try await AuthManager.shared.signUpWithEmail(name: name, email: email, password: password)
            print("Sign up success")
        } else {
            print("Form is not valid")
            throw NSError()
        }
    }

    func signOut() async throws {
        try await AuthManager.shared.signOut()
        isAuthenticated = false
    }

    // TODO: 丰富表单验证逻辑
    func isFormValid(email: String, password: String) -> Bool {
        guard email.isValidEmail() else {
            return false
        }
        return true
    }
}

extension String {
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}
