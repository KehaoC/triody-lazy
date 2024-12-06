from typing import Optional, Dict, Any
from django.http import JsonResponse

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