import SwiftUI

struct UserView: View {
    // TODO 用户登陆之后应该要拿到获取数据的 token
    @State private var isLogin: Bool = false
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Lazy")
                .font(.custom("Zapfino", size: 42))
                .foregroundColor(.primary)
                .shadow(radius: 2)
                .padding(.top, 40)
            
            if isLogin {
                LoggedView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                LoginView
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .padding()
        .animation(.spring(response: 0.3), value: isLogin)
        .background(
            Color(.systemBackground)
                .ignoresSafeArea()
        )
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif

    var LoggedView: some View {
        VStack(spacing: 25) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 120, height: 120)
                .foregroundStyle(.linearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(radius: 5)
            
            Text("Welcome back,")
                .font(.title2)
                .foregroundColor(.secondary)
            Text(username)
                .font(.title.bold())
                .foregroundColor(.primary)

            Button(action: {
                withAnimation {
                    isLogin = false 
                    username = ""
                    password = ""
                }
            }) {
                Text("Logout")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 45)
                    .background(
                        LinearGradient(colors: [.red, .red.opacity(0.8)], 
                                     startPoint: .leading, 
                                     endPoint: .trailing)
                    )
                    .cornerRadius(12)
                    .shadow(radius: 3)
            }
        }
        .padding(.horizontal)
    }

    var LoginView: some View {
        VStack(spacing: 25) {
            VStack(spacing: 16) {
                TextField("Username", text: $username)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .frame(width: 300)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .frame(width: 300)
            }
            
            Button(action: {
                if !username.isEmpty && !password.isEmpty {
                    withAnimation {
                        isLogin = true
                    }
                }
            }) {
                Text("Login")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 300, height: 45)
                    .background(
                        LinearGradient(colors: [.blue, .blue.opacity(0.8)], 
                                     startPoint: .leading, 
                                     endPoint: .trailing)
                    )
                    .cornerRadius(12)
                    .shadow(radius: 3)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    UserView()
}
