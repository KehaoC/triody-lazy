from colorama import init, Fore, Style
import json
from functools import wraps
from django.http import JsonResponse
from typing import Optional, Any, Dict, List
from supabase import create_client, Client
from django.conf import settings
def beautyprint(processes: List[Dict]):
    # 初始化 colorama
    init()
    
    print(f"\n{Fore.CYAN}=== Task Execution Results ==={Style.RESET_ALL}\n")
    
    for process in processes:
        # 打印子任务标题
        print(f"{Fore.GREEN}[Subtask {process['subtask_id']}]{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}Description:{Style.RESET_ALL} {process['subtask_content']}")
        print(f"{Fore.YELLOW}Executor:{Style.RESET_ALL} {process['excutor']}")
        
        # 解析并美化输出结果
        try:
            result = json.loads(process['excute_result'])
            if isinstance(result, dict) and 'result' in result:
                print(f"{Fore.YELLOW}Result:{Style.RESET_ALL} {result['result']}")
            else:
                print(f"{Fore.YELLOW}Result:{Style.RESET_ALL} {result}")
        except json.JSONDecodeError:
            print(f"{Fore.YELLOW}Result:{Style.RESET_ALL} {process['excute_result']}")
            
        print(f"\n{Fore.BLUE}{'='*50}{Style.RESET_ALL}\n")



class APIError(Exception):
    """自定义API异常类"""
    def __init__(self, message: str, status_code: int = 400, data: Optional[Dict] = None):
        self.message = message
        self.status_code = status_code
        self.data = data
        super().__init__(message)

def api_response(
    data: Optional[Any] = None, 
    message: str = "Success", 
    status: str = "success", 
    status_code: int = 200
) -> JsonResponse:
    """统一的API响应格式"""
    response = {
        "status": status,
        "message": message,
        "data": data
    }
    return JsonResponse(
        response, 
        status=status_code,
        json_dumps_params={'ensure_ascii': False, 'indent': 4}
    )

def api_error_handler(view_func):
    """统一的错误处理装饰器"""
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        try:
            # 直接执行被捕捉的那个函数
            return view_func(request, *args, **kwargs)
        except APIError as e:
            # 如果抛出了错误，在这里捕获, 返回一个API响应
            return api_response(
                data=e.data,
                message=e.message,
                status="error",
                status_code=e.status_code
            )
        except ValueError as e:
            return api_response(
                message=str(e),
                status="error",
                status_code=400
            )
        except Exception as e:
            return api_response(
                message="An unexpected error occurred",
                status="error",
                status_code=500
            )
    return wrapper

def require_auth(view_func):
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        token = request.headers.get("Authorization")
        
        if not token:
            raise APIError("No Authorization header found", status_code=401)
            
        if token.startswith("Bearer "):
            token = token.split(" ")[1]
        else:
            raise APIError("Invalid token format, Bearer token is required", status_code=401)
        
        request.user_id = get_user_id_by_token(token)
        
        return view_func(request, *args, **kwargs)
    return wrapper

def get_user_id_by_token(token: str) -> Optional[str]:
    try:
        # TODO: 从 settings 中获取
        SUPABASE_URL = "https://eraslmtrxqzkjsdrsnjh.supabase.co"
        SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVyYXNsbXRyeHF6a2pzZHJzbmpoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMzI3OTc2MiwiZXhwIjoyMDQ4ODU1NzYyfQ.jmYb6INqZ331sItH-89EWK3YAZ_OfTGKYedtygYTov4"

        supabase: Client = create_client(
            SUPABASE_URL,
            SUPABASE_KEY
        )
        
        # 获取用户信息
        user = supabase.auth.get_user(token)
        
        if not user or not user.user:
            raise APIError("Invalid token: no user found", status_code=401)
            
        return str(user.user.id)  # 返回用户 UUID
        
    except Exception as e:
        raise APIError(f"Token verification failed: {str(e)}", status_code=401)