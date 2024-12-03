import Foundation

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
    
    func signIn() async throws {
        print("Sign in")
    }
    
    func signUp() async throws {
        print("Sign up")
    }

    func signOut() async throws {
        print("Sign out")
    }
}

