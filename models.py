from flask_sqlalchemy import SQLAlchemy
from app import db

class user(db.model):
    id = db.column(db.Integer, primary_key=True)
    username = db.column(db.sting(80), nullable=False)
    email = db.column)db.string(120), unique=True, nullable=False)
    password = db.column(db.string(120), nullable=False)
   
    def __repr__(self):
        