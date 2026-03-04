import logging
import os
import sqlite3
from logging.handlers import RotatingFileHandler
from flask import Flask, request, jsonify
from itsdangerous import URLSafeTimedSerializer as Serializer
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.config['SECRET_KEY'] = 'change-this-to-a-secure-random-key'

DATABASE = 'database.db'

# auth logging
LOG_DIR = 'logs'
os.makedirs(LOG_DIR, exist_ok=True)
log_file = os.path.join(LOG_DIR, 'auth.log')
handler = RotatingFileHandler(log_file, maxBytes=5 * 1024 * 1024, backupCount=5)
formatter = logging.Formatter('%(asctime)s %(levelname)s %(name)s: %(message)s')
handler.setFormatter(formatter)
handler.setLevel(logging.INFO)

auth_logger = logging.getLogger('auth')
auth_logger.setLevel(logging.INFO)
if not auth_logger.handlers:
    auth_logger.addHandler(handler)


def get_db_connection():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn


@app.route('/login', methods=['POST'])
def login():
    # Accept JSON 
    if request.is_json:
        data = request.get_json()
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
    else:
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')

    if not (username or email) or not password:
        ip = request.remote_addr
        ua = request.headers.get('User-Agent', '')
        auth_logger.warning("Login attempt missing_fields username=%s email=%s ip=%s ua=%s", username, email, ip, ua)
        return jsonify({'error': 'Missing username/email or password'}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    if username:
        cur.execute('SELECT id, username, email, password FROM users WHERE username = ?', (username,))
    else:
        cur.execute('SELECT id, username, email, password FROM users WHERE email = ?', (email,))

    user = cur.fetchone()
    conn.close()

    ip = request.remote_addr
    ua = request.headers.get('User-Agent', '')

    if not user:
        auth_logger.warning("Login failed user_not_found username=%s email=%s ip=%s ua=%s", username, email, ip, ua)
        return jsonify({'error': 'Invalid credentials'}), 401

    # Verify hashed password
    if check_password_hash(user['password'], password):
        s = Serializer(app.config['SECRET_KEY'])
        token = s.dumps({'user_id': user['id']})
        auth_logger.info("Login success user_id=%s username=%s email=%s ip=%s ua=%s", user['id'], user['username'], user['email'], ip, ua)
        return jsonify({
            'token': token,
            'user': {'id': user['id'], 'username': user['username'], 'email': user['email']}
        }), 200

    auth_logger.warning("Login failed invalid_password username=%s email=%s user_id=%s ip=%s ua=%s", username, email, user['id'], ip, ua)
    return jsonify({'error': 'Invalid credentials'}), 401


@app.route('/register', methods=['POST'])
def register():
    if request.is_json:
        data = request.get_json()
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
    else:
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')

    if not username or not email or not password:
        ip = request.remote_addr
        ua = request.headers.get('User-Agent', '')
        auth_logger.warning("Register attempt missing_fields username=%s email=%s ip=%s ua=%s", username, email, ip, ua)
        return jsonify({'error': 'Missing username, email or password'}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    # Check for existing username/email
    cur.execute('SELECT id FROM users WHERE username = ? OR email = ?', (username, email))
    if cur.fetchone():
        conn.close()
        ip = request.remote_addr
        ua = request.headers.get('User-Agent', '')
        auth_logger.warning("Register failed exists username=%s email=%s ip=%s ua=%s", username, email, ip, ua)
        return jsonify({'error': 'User with that username or email already exists'}), 409

    hashed = generate_password_hash(password)
    cur.execute('INSERT INTO users (username, email, password) VALUES (?, ?, ?)', (username, email, hashed))
    conn.commit()
    user_id = cur.lastrowid
    conn.close()
    ip = request.remote_addr
    ua = request.headers.get('User-Agent', '')
    auth_logger.info("Register success user_id=%s username=%s email=%s ip=%s ua=%s", user_id, username, email, ip, ua)

    return jsonify({'message': 'User created', 'user': {'id': user_id, 'username': username, 'email': email}}), 201


if __name__ == '__main__':
    app.run(debug=True) 