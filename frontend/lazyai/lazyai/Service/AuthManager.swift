import Supabase
import Foundation

class AuthManager{
    static let shared = AuthManager()

    private init() {}

    let client = SupabaseClient(supabaseURL: URL(string: "https://rwouxkvsjqcrnlfhplxq.supabase.co")!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3b3V4a3ZzanFjcm5sZmhwbHhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIwMTk2MDEsImV4cCI6MjA0NzU5NTYwMX0.UmQ89tJXM1rX-rsGwq7cv9NY9QJPxmm4zwctmaPxOK8")

    func signUpWithEmail(name: String, email: String, password: String) async throws -> UserModel {
        let signUpAuthResponse = try await client.auth.signUp(email: email, password: password)
        guard let session = signUpAuthResponse.session else {
            throw NSError()
        }
        print("Sign up with email: \(signUpAuthResponse)")

        return UserModel(
            id: signUpAuthResponse.user.id, 
            email: signUpAuthResponse.user.email ?? "", 
            name: name, 
            accessToken: session.accessToken
        )
    }

    func signInWithEmail(email: String, password: String) async throws -> UserModel {
        let session = try await client.auth.signIn(email: email, password: password)
        print("Sign in with email: \(session)")

        return UserModel(
            id: session.user.id, 
            email: session.user.email ?? "", 
            name: session.user.email ?? "", 
            accessToken: session.accessToken
        )
    }

    func signOut() async throws{
        print("Sign out")
        do {
            try await client.auth.signOut()
        } catch {
            print("Sign out error: \(error)")
            throw error
        }
    }
}
