import SwiftUI

struct UserView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var showSignUp = false

    var body: some View {
        if userViewModel.isAuthenticated {
            ProfileView()
        } else {
            if showSignUp {
                SignUpView(showSignUp: $showSignUp)
            } else {
                SignInView(showSignUp: $showSignUp)
            }
        }
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

struct SignInView: View {
    @Binding var showSignUp: Bool
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        VStack(spacing: 32) {
            Text("LazyAI")
                .font(.custom("Zapfino", size: 42))
                .foregroundColor(.primary)
                .shadow(radius: 2)
            VStack(spacing: 4) {
                Text("Hi 👋")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Please enter your details to sign in.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
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

            Button(action: {
                Task {
                    try await userViewModel.signIn()
                }
            }) {
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
}

struct SignUpView: View {
    @Binding var showSignUp: Bool
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        VStack(spacing: 32) {
            Text("LazyAI")
                .font(.custom("Zapfino", size: 42))
                .foregroundColor(.primary)
                .shadow(radius: 2)
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
            
            Button(action: {
                Task {
                    try await userViewModel.signUp()
                }
            }) {
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
