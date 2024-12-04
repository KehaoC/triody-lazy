import SwiftUI

struct ProfileView: View {
	@EnvironmentObject var userViewModel: UserViewModel
	@State private var showSignOutAlert = false
	
	var body: some View {
		VStack(spacing: 32) {
			VStack(spacing: 4) {
				Text("Profile")
					.font(.title)
					.fontWeight(.bold)
				Text("Welcome back!")
					.font(.subheadline)
					.foregroundColor(.gray)
			}
			
			VStack(alignment: .leading, spacing: 16) {
				VStack(alignment: .leading, spacing: 8) {
					Text("Name")
						.font(.subheadline)
						.foregroundColor(.gray)
					Text(userViewModel.user?.name ?? "")
						.font(.headline)
				}
				
				VStack(alignment: .leading, spacing: 8) {
					Text("Email")
						.font(.subheadline)
						.foregroundColor(.gray)
					Text(userViewModel.user?.email ?? "")
						.font(.headline)
				}
			}
			.padding(.horizontal, 32)
			
			Button(action: {
				showSignOutAlert = true
			}) {
				Text("Sign out")
					.foregroundColor(.red)
					.fontWeight(.semibold)
			}
			.padding(.top, 16)
			.alert("Sign Out", isPresented: $showSignOutAlert) {
				Button("Cancel", role: .cancel) { }
				Button("Sign Out", role: .destructive) {
					Task {
						try await userViewModel.signOut()
					}
				}
			} message: {
				Text("Are you sure you want to sign out?")
			}
		}
		.padding(.vertical, 32)
	}
}
