//
//  NiumaHouseView.swift
//  LazyAI
//
//  Created by ALcohol_可豪 on 2024/12/1.
//


import SwiftUI

// MARK: - 主页面下方的空闲 niuma
struct NiumaHouseView: View {
	// TODO: 牛马屋
	// 牛马屋的牛马们可以被拖拽到任务卡上
	// 用户可以骂牛马, 从而改进牛马
	// 用户可以雇佣和升级更好的牛马
	// 用户可以解雇牛马
	// 用户可以查看牛马的属性
	@EnvironmentObject var niumaManager: NiumaManager

	var body: some View {
		ScrollView(.horizontal, showsIndicators: true) {
			HStack(spacing: 12) {
				ForEach(niumaManager.niumasInHome, id: \.id) { niuma in
					LazyNiuma(niuma: niuma)
				}
			}
		}
		.padding()
	}
}

struct LazyNiuma: View {
	// LazyNiuma 是在牛马屋中休息的牛马，没有任何事情做
	let niuma: NiumaInHome
	@State private var showNiumaDetail: Bool = false

	init(niuma: NiumaInHome) {
		self.niuma = niuma
	}

	var body: some View {
		HStack {
			niumaName
			niumaAvatar
		}
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(
					LinearGradient(
						colors: [Color.blue.opacity(0.2), Color.indigo.opacity(0.2)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 12)
				.stroke(Color.gray.opacity(0.5), lineWidth: 2)
		)
		.clipShape(RoundedRectangle(cornerRadius: 12))
		.shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
		.onTapGesture {
			// 点击后显示牛马的详细信息
			showNiumaDetail = true
		}
		.popover(isPresented: $showNiumaDetail) {
			LazyNiumaDetail(niuma: niuma)
		}
		.enableInjection()
	}

	var niumaName: some View {
		Text(niuma.name)
			.font(.system(size: 16, weight: .bold, design: .monospaced))
	}

	var niumaAvatar: some View {
		// 根据牛马的名字显示不同的头像
		if niuma.name == "coder" {
			Image(systemName: "laptopcomputer")
				.foregroundStyle(.secondary)
		} else if niuma.name == "searcher" {
			Image(systemName: "magnifyingglass")
				.foregroundStyle(.secondary)
		} else if niuma.name == "writer" {
			Image(systemName: "pencil")
				.foregroundStyle(.secondary)
		} else {
			Image(systemName: "person.fill")
				.foregroundStyle(.secondary)
		}
	}
}
struct NiumaAvatar: View {
	var name: String

	var body: some View {
		if name == "coder" {
			Image(systemName: "laptopcomputer")
				.foregroundStyle(.secondary)
		} else if name == "searcher" {
			Image(systemName: "magnifyingglass")
				.foregroundStyle(.secondary)
		} else if name == "writer" {
			Image(systemName: "pencil")
				.foregroundStyle(.secondary)
		} else {
			Image(systemName: "person.fill")
				.foregroundStyle(.secondary)
		}
	}
}

// MARK: - TODO 还没有想好要怎么设计
// 这里觉得可以放一些静态的数据，比如牛马类型介绍之类的
struct LazyNiumaDetail: View {
	let niuma: NiumaInHome

	var body: some View {
		VStack {
			Text(niuma.name)
		}
		.padding()
	}
}

