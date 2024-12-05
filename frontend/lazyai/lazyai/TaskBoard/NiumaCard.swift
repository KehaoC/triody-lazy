import SwiftUI
struct NiumaInTaskCard: View {
	let niuma: NiumaDetail
	@State private var showPopoverDetail: Bool = false

	init(niuma: NiumaDetail) {
		self.niuma = niuma
	}

	var body: some View {
		niumaInShort
			.onTapGesture {
				showPopoverDetail = true
			}
			.sheet(isPresented: $showPopoverDetail) {
				niumaInLong
			}
	    .enableInjection()
	}

	#if DEBUG
	@ObserveInjection var forceRedraw
	#endif

	func progressBar(for niuma: NiumaDetail) -> some View {
		ProgressView(value: niuma.progress)
			.progressViewStyle(LinearProgressViewStyle())
	}

	var niumaInShort: some View {
		VStack {
			HStack {
				Text(niuma.name)
					.font(.system(size: 16, weight: .bold, design: .rounded))
					.italic()
				NiumaAvatar(name: niuma.name)
				if niuma.progress >= 1.0 {
					Image(systemName: "checkmark.circle.fill")
						.foregroundStyle(.green)
						.symbolEffect(.bounce)
				}
			}
			progressBar(for: niuma)
				.animation(.easeInOut, value: niuma.progress)
				.symbolEffect(.pulse, options: .repeating)
				.contentTransition(.opacity)
		}	
	}

	var niumaInLong: some View {
		VStack(alignment: .leading, spacing: 24) {
			// 头像和名字 和任务
			HStack(spacing: 16) {
				roundedNiumaAvatar
					.frame(width: 40, height: 40)
					.background(
						Circle()
							.fill(.ultraThinMaterial)
							.shadow(color: .black.opacity(0.2), radius: 10)
					)
					.overlay(
						Circle()
							.stroke(.secondary.opacity(0.5), lineWidth: 3)
					)
				niumaName


			}
			.padding(.top, 32)
			.padding(.horizontal)

			// Working status
			VStack(spacing: 16) {

				consistentWorkingFor(time: 10)

				VStack(spacing: 4) {
					dynamicProgressBar(for: niuma)
						.frame(height: 8)
					
					Text("\(Int(niuma.progress * 100))%")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			.padding(.horizontal)

			// Working result
			VStack(alignment: .leading, spacing: 4) {

				// Task
				Text("Searching on the Instgram about the best cafe for team meeting in Guangzhou...")
					.shadow(color: .gray.opacity(0.3), radius: 2, x: 1, y: 1)
					.font(.system(size: 18, weight: .thin, design: .serif))
				
				Spacer()
				
				Text("Working log...")
					.font(.caption)
					.foregroundStyle(.secondary)
				
				ScrollView {
					Text("2024-12-01 10:00")
						.font(.caption)
						.foregroundStyle(.secondary)
					
					
					VStack(alignment: .leading, spacing: 4) {
						HStack {
							Image("cafe1")
								.resizable()
								.scaledToFit()
								.clipShape(RoundedRectangle(cornerRadius: 16))
								.frame(width: 100)
							
							VStack(alignment: .leading, spacing: 4) {
								Text("Lobby coffee looks nice, but a little far from the office. And the price is too expensive.")
									.font(.system(size: 18, weight: .thin, design: .serif))
									.italic()
									.padding(.horizontal, 8)
								HStack {
									Spacer()
									Link(destination: URL(string: "https://www.xiaohongshu.com/explore/66238eb40000000001005051?xsec_token=ABjOetEJs47LdmzBqSofwDgtd6nEzfo2DDTwzQyZIP8L8=&xsec_source=pc_search&source=web_explore_feed")!) {
										Text("From Redbook📕")
											.font(.caption)
										Image(systemName: "link")
											.foregroundStyle(.secondary)
									}
								}
							}
						}
					}
					.padding(.vertical, 8)

					Text("2024-12-01 10:02")
						.font(.caption)
						.foregroundStyle(.secondary)
					
					
					VStack(alignment: .leading, spacing: 4) {
						HStack {
							Image("cafe2")
								.resizable()
								.scaledToFit()
								.clipShape(RoundedRectangle(cornerRadius: 16))
								.frame(width: 100)
							
							VStack(alignment: .leading, spacing: 4) {
								Text("Manner coffee is easy to access, but the quality is not as good as Lobby coffee.")
									.font(.system(size: 18, weight: .thin, design: .serif))
									.italic()
									.padding(.horizontal, 8)
								HStack {
									Spacer()
									Link(destination: URL(string: "https://www.xiaohongshu.com/explore/66dd394f000000001e0191bc?xsec_token=ABXlJnEwkT4ltDd7xjUpTGHNllRcmrf8DTIta3o0udflw%3D&xsec_source=pc_search&source=web_explore_feed")!) {
										Text("From Redbook📕")
											.font(.caption)
										Image(systemName: "link")
											.foregroundStyle(.secondary)
									}
								}
							}
						}
					}
					.padding(.vertical, 8)

										Text("2024-12-01 10:05")
						.font(.caption)
						.foregroundStyle(.secondary)
					
					
					VStack(alignment: .leading, spacing: 4) {
						HStack {
							Image("cafe3")
								.resizable()
								.scaledToFit()
								.clipShape(RoundedRectangle(cornerRadius: 16))
								.frame(width: 100)
							
							VStack(alignment: .leading, spacing: 4) {
								Text("A cafe perfect for introverts, with unique and distinctive flavors that set it apart.")
									.font(.system(size: 18, weight: .thin, design: .serif))
									.italic()
									.padding(.horizontal, 8)
								HStack {
									Spacer()
									Link(destination: URL(string: "https://www.xiaohongshu.com/explore/66e55a65000000001e0180db?xsec_token=ABI4k-y3K4VDQQh8ba2Fuy4SFEnJ_VFonJ3IeUSkDo0U0%3D&xsec_source=pc_search&source=web_explore_feed")!) {
										Text("From Redbook📕")
											.font(.caption)
										Image(systemName: "link")
											.foregroundStyle(.secondary)
									}
								}
							}
						}
					}
					.padding(.vertical, 8)
				}
			}
			.padding(.horizontal)

			Spacer()
		}

	}

	var roundedNiumaAvatar: some View {
		NiumaAvatar(name: niuma.name)
			.symbolEffect(.bounce, value: 1.5)
	}	

	var niumaName: some View {
		Text(niuma.name)
			.font(.system(size: 16, weight: .bold, design: .rounded))
			.italic()
	}

	func consistentWorkingFor(time: Int) -> some View {
		Text("Consistent working for \(time) days")
			.font(.body)
			.foregroundStyle(.secondary)
	}

	func dynamicProgressBar(for niuma: NiumaDetail) -> some View {
		ProgressView(value: niuma.progress)
			.progressViewStyle(LinearProgressViewStyle())
			.animation(.easeInOut, value: niuma.progress)
			.symbolEffect(.pulse, options: .repeating)
			.contentTransition(.opacity)
	}
}

