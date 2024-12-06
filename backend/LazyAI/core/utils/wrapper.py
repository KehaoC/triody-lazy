from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.http import JsonResponse

from functools import wraps
from typing import Optional, Dict, Any
from supabase import create_client, Client


def auth_and_error_handler(methods=None):
    """
    组合装饰器，包含常用的 API 视图装饰器
    @param methods: 允许的 HTTP 方法列表，例如 ["GET"]、["POST"] 等
    """
    def decorator(view_func):
        @csrf_exempt
        @require_http_methods(methods or ["GET"])
        @api_error_handler
        @require_auth
        @wraps(view_func)
        def wrapped_view(*args, **kwargs):
            return view_func(*args, **kwargs)
        return wrapped_view
    return decorator

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
        supabase: Client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_KEY
        )
        
        user = supabase.auth.get_user(token)
        
        if not user or not user.user:
            raise APIError("Invalid token: no user found", status_code=401)
            
        return str(user.user.id)
        
    except Exception as e:
        raise APIError(f"Token verification failed: {str(e)}", status_code=401)


class APIError(Exception):
    """Custom API exception class"""
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
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        try:
            return view_func(request, *args, **kwargs)
        except APIError as e:
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