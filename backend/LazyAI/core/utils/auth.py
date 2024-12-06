from functools import wraps
from typing import Optional
from supabase import create_client, Client
from django.conf import settings
from .api import APIError

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