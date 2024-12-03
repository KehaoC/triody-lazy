import Foundation
import GoogleSignIn

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
    @Published var user: UserModel?
    @Published var accessToken: String?  // TODO: 添加 accessToken 的逻辑
    
    func signIn() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement actual sign in logic
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            throw AuthError.invalidInput
        }
    }
    
    func signUp() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement actual sign up logic
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            errorMessage = "Please fill in all fields"
            throw AuthError.invalidInput
        }
    }
    
    func signInWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement Google sign in
    }
    
    func checkPreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            // TODO：将Google 的 UserModel 转换为自定义的 UserModel
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            if let googleUser = user {
                // self.user = user
                print("Google User login!")
                self.user = UserModel(
                    id: googleUser.userID ?? "",
                    email: googleUser.profile?.email ?? "",
                    name: googleUser.profile?.name ?? "",
                    profileImageUrl: googleUser.profile?.imageURL(withDimension: 100)?.absoluteString
                )

                self.isAuthenticated = true
            }
        }
    }
    
    func handleSignInURL(_ url: URL) {
        GIDSignIn.sharedInstance.handle(url)
    }
}

enum AuthError: Error {
    case invalidInput
    case authenticationFailed
}