import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct UserView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var showSignUp = false

    var body: some View {
        if userViewModel.isAuthenticated {
            userProfile
        } else {
            if showSignUp {
                signUp
            } else {
                signIn
            }
        }
    }

    var signIn: some View {
        VStack(spacing: 32) {
            logo
            VStack(spacing: 4) {
                Text("Hi 👋")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Please enter your details to sign in.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            GoogleSignInButton(action: handleGoogleSignIn)
                .frame(height: 50)
                .padding(.horizontal, 32)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("E-Mail Address")
                    .font(.subheadline)
                    .fontWeight(.bold)
                TextField("Enter your email...", text: $userViewModel.email)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.bold)
                SecureField("6 bits or more", text: $userViewModel.password)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            .padding(.horizontal, 32)
            
            if !userViewModel.errorMessage.isEmpty {
                Text(userViewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: handleSignIn) {
                if userViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign in")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(userViewModel.isLoading)
            
            HStack {
                Text("Don't have an account yet?")
                    .foregroundStyle(.gray)
                Button("Sign up") {
                    showSignUp = true
                }
                    .foregroundStyle(.black)
                    .fontWeight(.bold)
            }
        }
    }

    var logo: some View {
        Text("LazyAI")
            .font(.custom("Zapfino", size: 42))
            .foregroundColor(.primary)
            .shadow(radius: 2)
            
    }

    var signUp: some View {
        VStack(spacing: 32) {
            logo
            VStack(spacing: 4) {
                Text("Create Account")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Please fill in your details")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.subheadline)
                    .fontWeight(.bold)
                TextField("Enter your name...", text: $userViewModel.name)
                    .textFieldStyle(CustomTextFieldStyle())
                
                Text("E-Mail Address")
                    .font(.subheadline)
                    .fontWeight(.bold)
                TextField("Enter your email...", text: $userViewModel.email)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.bold)
                SecureField("6 bits or more", text: $userViewModel.password)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            .padding(.horizontal, 32)
            
            if !userViewModel.errorMessage.isEmpty {
                Text(userViewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: handleSignUp) {
                if userViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create Account")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(userViewModel.isLoading)
            
            HStack {
                Text("Already have an account?")
                    .foregroundStyle(.gray)
                Button("Sign in") {
                    showSignUp = false
                }
                .foregroundStyle(.black)
                .fontWeight(.bold)
            }
        }
    }
    
    // Helper functions
    private func handleSignIn() {
        Task {
            do {
                try await userViewModel.signIn()
            } catch {
                // Error is already handled in ViewModel
            }
        }
    }
    
    private func handleSignUp() {
        Task {
            do {
                try await userViewModel.signUp()
            } catch {
                // Error is already handled in ViewModel
            }
        }
    }
    
    private func handleGoogleSignIn() {
        Task {
            do {
                try await userViewModel.signInWithGoogle()
            } catch {
                // Error is already handled in ViewModel
            }
        }
    }

    var userProfile: some View {
        VStack(spacing: 24) {
            // Profile Header
            VStack(spacing: 16) {
                if let imageUrl = userViewModel.user?.profileImageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
                
                Text(userViewModel.user?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 16) {
                InfoRow(title: "Email", value: userViewModel.user?.email ?? "")
                Divider()
                InfoRow(title: "User ID", value: userViewModel.user?.id ?? "")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            // Sign Out Button
            Button(action: handleSignOut) {
                Text("Sign Out")
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
            }
            .padding()
        }
        .padding(.top, 32)
    }

    // Add this helper view for info rows
    private struct InfoRow: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
            }
        }
    }

    // Add sign out handler
    private func handleSignOut() {
        // TODO: 添加退出登录的逻辑
        print("Sign out")
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

// Custom styles
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? Color.gray : Color.black)
            .cornerRadius(8)
            .padding(.horizontal, 32)
    }
}
