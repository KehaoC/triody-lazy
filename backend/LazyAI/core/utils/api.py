from typing import Optional, Any, Dict
from django.http import JsonResponse
from functools import wraps

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