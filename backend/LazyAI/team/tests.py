from django.test import TestCase
from team.models import Task, Subtask, User
from team.agents import Agent, Team
from team.prompts import *
from team.database import Database

class TestFullProcess(TestCase):
    def setUp(self):
        # Create mock users
        self.mock_user1 = User.objects.create(
            name='testuser1',
            email='test1@example.com',
            password='testpass123'
        )
        
        self.mock_user2 = User.objects.create(
            name='testuser2',
            email='test2@example.com',
            password='testpass456'
        )

        # Create some mock tasks
        self.mock_task1 = Task.objects.create(
            title="Mock Task 1",
            description="This is a mock task 1",
            user=self.mock_user1,
            is_finished=True
        )
        
        self.mock_task2 = Task.objects.create(
            title="Mock Task 2", 
            description="This is a mock task 2",
            user=self.mock_user2,
            is_finished=False
        )

        # Create some mock subtasks
        Subtask.objects.create(
            task=self.mock_task1,
            description="Mock subtask 1",
            agent_name="Writer",
            result="Mock result 1",
            is_lazied=True
        )

        Subtask.objects.create(
            task=self.mock_task1,
            description="Mock subtask 2", 
            agent_name="Searcher",
            result="Mock result 2",
            is_lazied=True
        )

        Subtask.objects.create(
            task=self.mock_task2,
            description="Mock subtask 3",
            agent_name="Coder", 
            result="Mock result 3",
            is_lazied=False
        )

        # Initialize test agents
        self.test_agents = [
            Agent("Outline_Writer", outline_writer_system_prompt), 
            Agent("Searcher", searcher_system_prompt),
            Agent("Coder", coder_system_prompt)
        ]
        
        # Create a Task instance in the database
        self.test_task = Task.objects.create(
            title = "New Task",  # Default title, modify as needed
            description =  "告诉我阿里巴巴2024年ESG报告的重点",
            user_id = 1,
        )
        
        # Initialize team
        self.team = Team(self.test_agents, self.test_task)

    def test_full_process(self):
        # 1. Verify initialization results
        self.assertEqual(Task.objects.count(), 3)  # 2 mock tasks + 1 new task
        created_task = Task.objects.last()  # Get the most recently created task
        self.assertEqual(created_task.description, self.test_task.description)

        # 2. Verify task decomposition
        self.team.decompose_task()
        self.assertNotEqual(self.team.subtasks, [])

        # 3. Verify task execution
        self.team.run()
        self.assertGreater(Subtask.objects.count(), 3)  # More than the initial mock subtasks


