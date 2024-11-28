import SwiftUI

struct UserView: View {
    // TODO 用户登陆之后应该要拿到获取数据的 token
    @State private var isLogin: Bool = false
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {

        VStack {
            Text("Lazy")
                .font(.custom("Zapfino", size: 36))
                .padding(.horizontal)
            if isLogin {
                // 已登录状态
                LoggedView
            } else {
                // 未登录状态
                LoginView
            }
        }
        .padding()
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif

    var LoggedView: some View {
        VStack() {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("Welcome back, \(username)")

            Button(action: {
                isLogin = false 
                username = ""
                password = ""
            }) {
                Text("Logout")
                    .foregroundColor(.white)
                    .frame(width: 200, height: 40)
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
    }

    var LoginView: some View {
        VStack(spacing: 20) {
            // Image(systemName: "person.circle")
            //     .resizable()
            //     .frame(width: 100, height: 100)
            //     .foregroundColor(.gray)
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 280)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 280)
            
            Button(action: {
                // 登录操作
                if !username.isEmpty && !password.isEmpty {
                    isLogin = true
                }
            }) {
                Text("Login")
                    .foregroundColor(.white)
                    .frame(width: 200, height: 40)
                    .background(Color.blue)
                    .cornerRadius(8)
            }   
        }
    }
}

#Preview {
    UserView()
}
