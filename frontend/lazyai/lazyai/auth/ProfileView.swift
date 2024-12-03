import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var userViewModel: UserViewModel

	var body: some View {
		VStack(spacing: 24) {
			// Profile Header
			VStack(spacing: 16) {
				Image(systemName: "person.circle.fill")
					.resizable()
					.frame(width: 100, height: 100)
					.foregroundColor(.gray)
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
			Button(action: {
				Task {
					try await userViewModel.signOut()
				}
			}) {
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
}
