"""
Settings file for Django - justinfolvarcik.com
"""

import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Read our injected env vars
# Use an insecure local key for dev but read from injected var for prod
SECRET_KEY = os.environ.get('JF_COM_DJANGO_SECRET_KEY', 'insecure-local-dev-key-do-not-reuse')
DEBUG = True if os.environ.get('JF_COM_DEBUG', 'false').lower() == 'true' else False
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

JF_COM_ENVIRONMENT = os.environ.get('JF_COM_ENVIRONMENT', 'Development')

# This shouldn't happen, but it's nice to have an extra check just in case
if JF_COM_ENVIRONMENT not in ('Development', 'Production'):
    raise ValueError("JF_COM_ENVIRONMENT must be 'Development' or 'Production'")

if JF_COM_ENVIRONMENT == 'Development':
    ALLOWED_HOSTS = ['localhost', '127.0.0.1']
elif JF_COM_ENVIRONMENT == 'Production':
    ALLOWED_HOSTS = ['justinfolvarcik.com', 'www.justinfolvarcik.com', '.on.aws']
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    CSRF_TRUSTED_ORIGINS = ['https://justinfolvarcik.com',
                            'https://www.justinfolvarcik.com',
                            # Terraform leaves the trailing slash, but Django needs it removed
                            os.environ.get('JF_COM_FUNCTION_URL', '').removesuffix('/')
                            ]

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'justinfolvarcik_com.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'justinfolvarcik_com.wsgi.application'

# Database settings
# Django always expects a default connection, so we define it conditionally based on environment
if JF_COM_ENVIRONMENT == 'Development':
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }
elif JF_COM_ENVIRONMENT == 'Production':
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'USER': os.environ.get('JF_COM_DB_USER'),
            'PASSWORD': os.environ.get('JF_COM_DB_PASS'),
            'HOST': os.environ.get('JF_COM_DB_HOST'),
            'PORT': 5432,
            'NAME': os.environ.get('JF_COM_DB_NAME'),
        }
    }

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'America/New_York'  # Use my time zone
USE_I18N = True
USE_TZ = True

if JF_COM_ENVIRONMENT == 'Production':
    INSTALLED_APPS += ['storages']
    JF_COM_BUCKET = os.environ.get('JF_COM_ASSETS_BUCKET')
    JF_COM_BUCKET_LOCATION = 'static'
    STORAGES = {
        'staticfiles': {
            'BACKEND': 'storages.backends.s3.S3Storage',
            'OPTIONS': {
                'bucket_name': JF_COM_BUCKET,
                'region_name': os.environ.get('JF_COM_REGION'),
                'location': JF_COM_BUCKET_LOCATION,
                'querystring_auth': False,
                'custom_domain': f'{JF_COM_BUCKET}.s3.amazonaws.com',
            }
        }
    }
    # This is the actual location of the static files
    STATIC_URL = f'https://{JF_COM_BUCKET}.s3.amazonaws.com/{JF_COM_BUCKET_LOCATION}/'
elif JF_COM_ENVIRONMENT == 'Development':
    STATIC_URL = 'static/'

