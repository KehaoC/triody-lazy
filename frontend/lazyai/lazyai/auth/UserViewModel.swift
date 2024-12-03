import Foundation

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
        print("Sign in")
        if isFormValid(email: email, password: password) {
            self.user = try await AuthManager.shared.signInWithEmail(email: email, password: password)
        } else {
            print("Form is not valid")
            throw NSError()
        }
    }
    
    func signUpWithEmail() async throws {
        print("Sign up")
        if isFormValid(email: email, password: password) {
            self.user = try await AuthManager.shared.signUpWithEmail(name: name, email: email, password: password)
        } else {
            print("Form is not valid")
            throw NSError()
        }
    }

    func signOut() async throws {
        print("Sign out")
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
