//
//  TaskList.swift
//  LazyAI
//
//  Created by ALcohol_可豪 on 2024/12/4.
//

import SwiftUI

struct TaskList: View {
	// 展示主页面上方的 Task
	@EnvironmentObject var taskManager: TaskManager

	var body: some View {
		ScrollView {
			LazyVStack(alignment: .leading, spacing: 16) {
				ForEach(taskManager.tasks) { task in
					TaskCard(task: task)
				}
			}
			.padding()
		}
	}
}
