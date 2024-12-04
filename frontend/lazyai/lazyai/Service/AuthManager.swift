import Supabase
import Foundation

class AuthManager{
    static let shared = AuthManager()

    private init() {}

    let client = SupabaseClient(supabaseURL: URL(string: "https://eraslmtrxqzkjsdrsnjh.supabase.co")!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVyYXNsbXRyeHF6a2pzZHJzbmpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMyNzk3NjIsImV4cCI6MjA0ODg1NTc2Mn0.E6lxRJcSAr4Ro3mAjvlNAQvKs-p-eHtTzDfqeEo52Z8")

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
