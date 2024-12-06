from colorama import init, Fore, Style
import json
from typing import Dict, List

def beautyprint(processes: List[Dict]):
    init()
    
    print(f"\n{Fore.CYAN}=== Task Execution Results ==={Style.RESET_ALL}\n")
    
    for process in processes:
        print(f"{Fore.GREEN}[Subtask {process['subtask_id']}]{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}Description:{Style.RESET_ALL} {process['subtask_content']}")
        print(f"{Fore.YELLOW}Executor:{Style.RESET_ALL} {process['excutor']}")
        
        try:
            result = json.loads(process['excute_result'])
            if isinstance(result, dict) and 'result' in result:
                print(f"{Fore.YELLOW}Result:{Style.RESET_ALL} {result['result']}")
            else:
                print(f"{Fore.YELLOW}Result:{Style.RESET_ALL} {result}")
        except json.JSONDecodeError:
            print(f"{Fore.YELLOW}Result:{Style.RESET_ALL} {process['excute_result']}")
            
        print(f"\n{Fore.BLUE}{'='*50}{Style.RESET_ALL}\n")