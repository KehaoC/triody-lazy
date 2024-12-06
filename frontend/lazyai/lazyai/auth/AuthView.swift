import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var showSignUp = false

    // TODO: 测试用，避免反复测试输入，麻烦
    @State private var inputEmail: String = "caikehao@triody.tech"
    @State private var inputPassword: String = "Ckh@0725"


    var body: some View {
        if userViewModel.isAuthenticated {
            ProfileView()
                .transition(.move(edge: .bottom))
        } else {
            if showSignUp {
                SignUpView(showSignUp: $showSignUp, inputEmail: $inputEmail, inputPassword: $inputPassword)
            } else {
                SignInView(showSignUp: $showSignUp, inputEmail: $inputEmail, inputPassword: $inputPassword)
            }
        }
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

struct SignInView: View {
    @EnvironmentObject var userViewModel: UserViewModel

    @Binding var showSignUp: Bool
    @Binding var inputEmail: String
    @Binding var inputPassword: String

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = "some test message."

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

            inputForm
            signInButton
            signUpTip
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { 
                showAlert = false
            }
        }
    }

    var inputForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("E-Mail Address")
                .font(.subheadline)
                .fontWeight(.bold)
            TextField("Enter your email...", text: $inputEmail)
                .textFieldStyle(CustomTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Text("Password")
                .font(.subheadline)
                .fontWeight(.bold)
            SecureField("6 bits or more", text: $inputPassword)
                .textFieldStyle(CustomTextFieldStyle())
        }
        .padding(.horizontal, 32)
    }

    var signInButton: some View {
        Button(action: {
            Task {
                do {
                    try await userViewModel.signInWithEmail(email: inputEmail, password: inputPassword)
                } catch {
                    alertMessage = "Please check your email and password and try again."
                    showAlert = true
                }
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
    }

    var signUpTip: some View {
        HStack {
            Text("Don't have an account yet?")
                .foregroundStyle(.gray)
            Button("Sign up") {
                withAnimation {
                    showSignUp = true
                }
            }
                .foregroundStyle(.black)
                .fontWeight(.bold)
        }
    }
}

struct SignUpView: View {
    @Binding var showSignUp: Bool
    @EnvironmentObject var userViewModel: UserViewModel

    @Binding var inputEmail: String
    @Binding var inputPassword: String

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
                Text("E-Mail Address")
                    .font(.subheadline)
                    .fontWeight(.bold)
                TextField("Enter your email...", text: $inputEmail)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.bold)
                SecureField("6 bits or more", text: $inputPassword)
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
                    try await userViewModel.signUpWithEmail(email: inputEmail, password: inputPassword)
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
                    withAnimation {
                        showSignUp = false
                    }
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
