default_app_config = 'core.apps.CoreConfig'

try:
    from .tasks import *
except ImportError:
    pass