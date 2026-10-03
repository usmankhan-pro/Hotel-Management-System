import os

import mysql.connector
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", ""),
    "database": os.getenv("DB_NAME", "hotel_management_db"),
}

def get_connection():
    """Returns a new MySQL connection."""
    return mysql.connector.connect(**DB_CONFIG)

def query(sql, params=None, fetch=True):
    """
    Run any SQL query.
    - fetch=True  → returns list of dicts (for SELECT)
    - fetch=False → commits and returns lastrowid (for INSERT/UPDATE/DELETE)
    """
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(sql, params or ())
        if fetch:
            result = cursor.fetchall()
        else:
            conn.commit()
            result = cursor.lastrowid
        return result
    finally:
        cursor.close()
        conn.close()
