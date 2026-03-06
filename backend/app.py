import logging
import os
import sqlite3
from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime, timezone
from enum import Enum
from logging.handlers import RotatingFileHandler
from typing import Optional, Dict, Any, List, Union, Tuple
from functools import wraps

from flask import Flask, request, jsonify, g
from itsdangerous import URLSafeTimedSerializer as Serializer
from werkzeug.security import generate_password_hash, check_password_hash
from flask_cors import CORS
#Domain Entities
@dataclass
class User:
    """Domain entity representing a user"""
    id: Optional[int]
    username: str
    email: str
    password_hash: str
    
    @classmethod
    def create(cls, username: str, email: str, password: str, password_hasher: 'PasswordHasher') -> 'User':
        """Factory method to create a new user with hashed password"""
        return cls(
            id=None,
            username=username,
            email=email,
            password_hash=password_hasher.hash(password)
        )
    
    def verify_password(self, password: str, password_hasher: 'PasswordHasher') -> bool:
        """Verify user password"""
        return password_hasher.verify(self.password_hash, password)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary (without sensitive data)"""
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email
        }


@dataclass
class AuthToken:
    """Value object for authentication token"""
    token: str
    user_id: int
    
    @classmethod
    def create(cls, user_id: int, serializer: 'TokenSerializer') -> 'AuthToken':
        """Create a new auth token"""
        return cls(
            token=serializer.encode({'user_id': user_id}),
            user_id=user_id
        )
    
    def validate(self, serializer: 'TokenSerializer') -> Optional[int]:
        """Validate token and return user_id if valid"""
        try:
            data = serializer.decode(self.token)
            return data.get('user_id')
        except:
            return None


# ===================== Value Objects =====================

@dataclass
class RequestMetadata:
    """Value object for request metadata"""
    ip_address: str
    user_agent: str
    timestamp: datetime
    endpoint: str
    
    @classmethod
    def from_flask_request(cls, endpoint: str) -> 'RequestMetadata':
        """Create from Flask request"""
        return cls(
            ip_address=request.remote_addr or 'unknown',
            user_agent=request.headers.get('User-Agent', 'unknown'),
            timestamp=datetime.now(timezone.utc),
            endpoint=endpoint
        )


class AuthEventType(Enum):
    """Authentication event types"""
    LOGIN_SUCCESS = "login_success"
    LOGIN_FAILURE = "login_failure"
    LOGIN_MISSING_FIELDS = "login_missing_fields"
    REGISTER_SUCCESS = "register_success"
    REGISTER_FAILURE = "register_failure"
    REGISTER_MISSING_FIELDS = "register_missing_fields"
    USER_NOT_FOUND = "user_not_found"
    INVALID_PASSWORD = "invalid_password"
    USER_EXISTS = "user_exists"


@dataclass
class AuthEvent:
    """Domain event for authentication activities"""
    event_type: AuthEventType
    metadata: RequestMetadata
    user_id: Optional[int] = None
    username: Optional[str] = None
    email: Optional[str] = None
    additional_data: Optional[Dict[str, Any]] = None


# ===================== Interfaces (Ports) =====================

class UserRepository(ABC):
    """Repository interface for User entities"""
    
    @abstractmethod
    def find_by_username(self, username: str) -> Optional[User]:
        pass
    
    @abstractmethod
    def find_by_email(self, email: str) -> Optional[User]:
        pass
    
    @abstractmethod
    def find_by_username_or_email(self, username: str, email: str) -> Optional[User]:
        pass
    
    @abstractmethod
    def save(self, user: User) -> User:
        pass


class PasswordHasher(ABC):
    """Interface for password hashing"""
    
    @abstractmethod
    def hash(self, password: str) -> str:
        pass
    
    @abstractmethod
    def verify(self, hashed: str, password: str) -> bool:
        pass


class TokenSerializer(ABC):
    """Interface for token serialization"""
    
    @abstractmethod
    def encode(self, data: Dict[str, Any]) -> str:
        pass
    
    @abstractmethod
    def decode(self, token: str) -> Dict[str, Any]:
        pass


class EventPublisher(ABC):
    """Interface for publishing domain events"""
    
    @abstractmethod
    def publish(self, event: AuthEvent) -> None:
        pass


class RequestParser(ABC):
    """Interface for parsing request data"""
    
    @abstractmethod
    def parse_credentials(self) -> Tuple[Optional[str], Optional[str], Optional[str]]:
        """Parse username, email, password from request"""
        pass


# ===================== Implementations =====================

class SQLiteUserRepository(UserRepository):
    """SQLite implementation of UserRepository"""
    
    def __init__(self, database_path: str):
        self.database_path = database_path
    
    def _get_connection(self):
        """Get database connection"""
        conn = sqlite3.connect(self.database_path)
        conn.row_factory = sqlite3.Row
        return conn
    
    def _row_to_user(self, row: sqlite3.Row) -> User:
        """Convert database row to User entity"""
        return User(
            id=row['id'],
            username=row['username'],
            email=row['email'],
            password_hash=row['password']
        )
    
    def find_by_username(self, username: str) -> Optional[User]:
        conn = self._get_connection()
        cur = conn.cursor()
        cur.execute('SELECT id, username, email, password FROM users WHERE username = ?', (username,))
        row = cur.fetchone()
        conn.close()
        return self._row_to_user(row) if row else None
    
    def find_by_email(self, email: str) -> Optional[User]:
        conn = self._get_connection()
        cur = conn.cursor()
        cur.execute('SELECT id, username, email, password FROM users WHERE email = ?', (email,))
        row = cur.fetchone()
        conn.close()
        return self._row_to_user(row) if row else None
    
    def find_by_username_or_email(self, username: str, email: str) -> Optional[User]:
        conn = self._get_connection()
        cur = conn.cursor()
        cur.execute('SELECT id, username, email, password FROM users WHERE username = ? OR email = ?', 
                   (username, email))
        row = cur.fetchone()
        conn.close()
        return self._row_to_user(row) if row else None
    
    def save(self, user: User) -> User:
        conn = self._get_connection()
        cur = conn.cursor()
        
        if user.id is None:
            cur.execute(
                'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
                (user.username, user.email, user.password_hash)
            )
            user.id = cur.lastrowid
        else:
            cur.execute(
                'UPDATE users SET username = ?, email = ?, password = ? WHERE id = ?',
                (user.username, user.email, user.password_hash, user.id)
            )
        
        conn.commit()
        conn.close()
        return user


class WerkzeugPasswordHasher(PasswordHasher):
    """Werkzeug implementation of PasswordHasher"""
    
    def hash(self, password: str) -> str:
        return generate_password_hash(password)
    
    def verify(self, hashed: str, password: str) -> bool:
        return check_password_hash(hashed, password)


class ItsdangerousTokenSerializer(TokenSerializer):
    """Itsdangerous implementation of TokenSerializer"""
    
    def __init__(self, secret_key: str):
        self.serializer = Serializer(secret_key)
    
    def encode(self, data: Dict[str, Any]) -> str:
        return self.serializer.dumps(data)
    
    def decode(self, token: str) -> Dict[str, Any]:
        return self.serializer.loads(token)


class LoggingEventPublisher(EventPublisher):
    """Logging implementation of EventPublisher"""
    
    def __init__(self, logger_name: str = 'auth', log_dir: str = 'logs'):
        self.logger = self._setup_logger(logger_name, log_dir)
    
    def _setup_logger(self, logger_name: str, log_dir: str) -> logging.Logger:
        """Setup rotating file logger"""
        os.makedirs(log_dir, exist_ok=True)
        log_file = os.path.join(log_dir, 'auth.log')
        
        handler = RotatingFileHandler(log_file, maxBytes=5 * 1024 * 1024, backupCount=5)
        formatter = logging.Formatter('%(asctime)s %(levelname)s %(name)s: %(message)s')
        handler.setFormatter(formatter)
        handler.setLevel(logging.INFO)
        
        logger = logging.getLogger(logger_name)
        logger.setLevel(logging.INFO)
        
        if not logger.handlers:
            logger.addHandler(handler)
        
        return logger
    
    def publish(self, event: AuthEvent) -> None:
        """Publish auth event to log"""
        log_data = {
            'event': event.event_type.value,
            'ip': event.metadata.ip_address,
            'ua': event.metadata.user_agent,
            'timestamp': event.metadata.timestamp.isoformat(),
            'user_id': event.user_id,
            'username': event.username,
            'email': event.email
        }
        
        if event.additional_data:
            log_data.update(event.additional_data)
        
        # Log at appropriate level
        if event.event_type in [AuthEventType.LOGIN_SUCCESS, AuthEventType.REGISTER_SUCCESS]:
            self.logger.info(f"Auth event: {log_data}")
        else:
            self.logger.warning(f"Auth event: {log_data}")


class FlaskRequestParser(RequestParser):
    """Flask implementation of RequestParser"""
    
    def parse_credentials(self) -> Tuple[Optional[str], Optional[str], Optional[str]]:
        """Parse username, email, password from Flask request"""
        if request.is_json:
            data = request.get_json() or {}
            username = data.get('username')
            email = data.get('email')
            password = data.get('password')
        else:
            username = request.form.get('username')
            email = request.form.get('email')
            password = request.form.get('password')
        
        return username, email, password


# ===================== Services =====================

class AuthenticationService:
    """Core authentication service"""
    
    def __init__(
        self,
        user_repository: UserRepository,
        password_hasher: PasswordHasher,
        token_serializer: TokenSerializer,
        event_publisher: EventPublisher
    ):
        self.user_repository = user_repository
        self.password_hasher = password_hasher
        self.token_serializer = token_serializer
        self.event_publisher = event_publisher
    
    def login(self, username: Optional[str], email: Optional[str], password: str, 
              metadata: RequestMetadata) -> Dict[str, Any]:
        """Process login attempt"""
        
        # Find user
        user = None
        if username:
            user = self.user_repository.find_by_username(username)
        elif email:
            user = self.user_repository.find_by_email(email)
        
        # User not found
        if not user:
            self.event_publisher.publish(AuthEvent(
                event_type=AuthEventType.USER_NOT_FOUND,
                metadata=metadata,
                username=username,
                email=email
            ))
            raise AuthenticationError("Invalid credentials")
        
        # Verify password
        if not user.verify_password(password, self.password_hasher):
            self.event_publisher.publish(AuthEvent(
                event_type=AuthEventType.INVALID_PASSWORD,
                metadata=metadata,
                user_id=user.id,
                username=username,
                email=email
            ))
            raise AuthenticationError("Invalid credentials")
        
        # Success - create token
        token = AuthToken.create(user.id, self.token_serializer)
        
        self.event_publisher.publish(AuthEvent(
            event_type=AuthEventType.LOGIN_SUCCESS,
            metadata=metadata,
            user_id=user.id,
            username=user.username,
            email=user.email
        ))
        
        return {
            'token': token.token,
            'user': user.to_dict()
        }
    
    def register(self, username: str, email: str, password: str, 
                 metadata: RequestMetadata) -> Dict[str, Any]:
        """Process registration attempt"""
        
        # Check if user exists
        existing = self.user_repository.find_by_username_or_email(username, email)
        if existing:
            self.event_publisher.publish(AuthEvent(
                event_type=AuthEventType.USER_EXISTS,
                metadata=metadata,
                username=username,
                email=email
            ))
            raise UserExistsError("User with that username or email already exists")
        
        # Create and save user
        user = User.create(username, email, password, self.password_hasher)
        saved_user = self.user_repository.save(user)
        
        self.event_publisher.publish(AuthEvent(
            event_type=AuthEventType.REGISTER_SUCCESS,
            metadata=metadata,
            user_id=saved_user.id,
            username=saved_user.username,
            email=saved_user.email
        ))
        
        return {
            'user': saved_user.to_dict()
        }


# ===================== Exceptions =====================

class AuthenticationError(Exception):
    """Authentication failed"""
    pass


class UserExistsError(Exception):
    """User already exists"""
    pass


class ValidationError(Exception):
    """Input validation failed"""
    pass


# ===================== Flask Adapters =====================

class FlaskAuthController:
    """Flask adapter for authentication endpoints"""
    
    def __init__(self, auth_service: AuthenticationService, request_parser: RequestParser):
        self.auth_service = auth_service
        self.request_parser = request_parser
        self._register_routes()
    
    def _register_routes(self):
        """Register routes with Flask"""
        # These would be registered in the Flask app setup
        pass
    
    def login(self) -> Tuple[Dict[str, Any], int]:
        """Handle login request"""
        try:
            # Parse request
            username, email, password = self.request_parser.parse_credentials()
            metadata = RequestMetadata.from_flask_request('login')
            
            # Validate
            if not (username or email) or not password:
                self.auth_service.event_publisher.publish(AuthEvent(
                    event_type=AuthEventType.LOGIN_MISSING_FIELDS,
                    metadata=metadata,
                    username=username,
                    email=email
                ))
                return {'error': 'Missing username/email or password'}, 400
            
            # Process login
            result = self.auth_service.login(username, email, password, metadata)
            return result, 200
            
        except AuthenticationError as e:
            return {'error': str(e)}, 401
        except Exception as e:
            # Log unexpected errors
            logging.exception("Unexpected error in login")
            return {'error': 'Internal server error'}, 500
    
    def register(self) -> Tuple[Dict[str, Any], int]:
        """Handle register request"""
        try:
            # Parse request
            username, email, password = self.request_parser.parse_credentials()
            metadata = RequestMetadata.from_flask_request('register')
            
            # Validate
            if not username or not email or not password:
                self.auth_service.event_publisher.publish(AuthEvent(
                    event_type=AuthEventType.REGISTER_MISSING_FIELDS,
                    metadata=metadata,
                    username=username,
                    email=email
                ))
                return {'error': 'Missing username, email or password'}, 400
            
            # Process registration
            result = self.auth_service.register(username, email, password, metadata)
            return {'message': 'User created', **result}, 201
            
        except UserExistsError as e:
            return {'error': str(e)}, 409
        except Exception as e:
            # Log unexpected errors
            logging.exception("Unexpected error in register")
            return {'error': 'Internal server error'}, 500


# ===================== Application Factory =====================

class Application:
    """Application factory and composition root"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.app = Flask(__name__)
        self.app.config.update(config)
        
        # Enable CORS
        CORS(self.app)
        
        # Setup dependencies
        self._setup_dependencies()
        
        # Setup routes
        self._setup_routes()
    
    def _setup_dependencies(self):
        """Setup dependency injection"""
        # Repositories
        self.user_repository = SQLiteUserRepository(
            database_path=self.config.get('DATABASE', 'database.db')
        )
        
        # Initialize database
        self._init_database()
        
        # Services
        self.password_hasher = WerkzeugPasswordHasher()
        self.token_serializer = ItsdangerousTokenSerializer(
            secret_key=self.config['SECRET_KEY']
        )
        self.event_publisher = LoggingEventPublisher(
            logger_name='auth',
            log_dir=self.config.get('LOG_DIR', 'logs')
        )
        
        # Core service
        self.auth_service = AuthenticationService(
            user_repository=self.user_repository,
            password_hasher=self.password_hasher,
            token_serializer=self.token_serializer,
            event_publisher=self.event_publisher
        )
        
        # Request parser
        self.request_parser = FlaskRequestParser()
        
        # Controller
        self.auth_controller = FlaskAuthController(
            auth_service=self.auth_service,
            request_parser=self.request_parser
        )
    
    def _init_database(self):
        """Initialize database schema"""
        db_path = self.config.get('DATABASE', 'database.db')
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        
        # Create users table if it doesn't exist
        cur.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL UNIQUE,
                email TEXT NOT NULL UNIQUE,
                password TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def _setup_routes(self):
        """Setup Flask routes"""
        
        @self.app.route('/login', methods=['POST', 'OPTIONS'])
        def login():
            if request.method == 'OPTIONS':
                return '', 204
            try:
                result, status_code = self.auth_controller.login()
                response = jsonify(result)
                response.status_code = status_code
                return response
            except Exception as e:
                logging.exception("Error in login route")
                return jsonify({'error': 'Internal server error'}), 500
        
        @self.app.route('/register', methods=['POST', 'OPTIONS'])
        def register():
            if request.method == 'OPTIONS':
                return '', 204
            try:
                result, status_code = self.auth_controller.register()
                response = jsonify(result)
                response.status_code = status_code
                return response
            except Exception as e:
                logging.exception("Error in register route")
                return jsonify({'error': 'Internal server error'}), 500
    
    def get_app(self) -> Flask:
        """Get configured Flask app"""
        return self.app


# ===================== Configuration =====================

class Config:
    """Configuration management"""
    
    @staticmethod
    def get_default() -> Dict[str, Any]:
        """Get default configuration"""
        return {
            'SECRET_KEY': os.environ.get('SECRET_KEY', 'change-this-to-a-secure-random-key'),
            'DATABASE': os.environ.get('DATABASE', 'database.db'),
            'LOG_DIR': os.environ.get('LOG_DIR', 'logs'),
            'DEBUG': os.environ.get('DEBUG', 'False').lower() == 'true'
        }
    
    @staticmethod
    def from_env() -> Dict[str, Any]:
        """Load configuration from environment"""
        return Config.get_default()


# ===================== Entry Point =====================

# Create application instance
config = Config.from_env()
application = Application(config)
app = application.get_app()

if __name__ == '__main__':
    app.run(debug=config['DEBUG'])