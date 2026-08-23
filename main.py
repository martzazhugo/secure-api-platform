from fastapi import FastAPI, HTTPException
import sqlite3
import os

app = FastAPI(title="Secure API Platform - Lab")
DB_FILE = "app_lab.db"

def init_db():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            password TEXT,
            role TEXT
        )
    """)
    cursor.execute("SELECT COUNT(*) FROM users")
    if cursor.fetchone()[0] == 0:
        cursor.execute("INSERT INTO users (username, password, role) VALUES ('admin', 'admin123', 'admin')")
        cursor.execute("INSERT INTO users (username, password, role) VALUES ('user1', 'user123', 'user')")
        conn.commit()
    conn.close()

init_db()

# PERBAIKAN #1: Ambil rahasia dari Environment Variable (tidak di-hardcode)
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "default-fallback-secret-for-local-dev-only")

@app.get("/")
def read_root():
    return {"status": "healthy", "service": "secure-api-platform"}

# PERBAIKAN #2: Gunakan Parameterized Query (?) untuk mencegah SQL Injection
@app.get("/api/v1/users/search")
def search_user(username: str):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Menggunakan tuples (?) menggantikan string formatting (f"...")
    query = "SELECT id, username, role FROM users WHERE username = ?"
    try:
        cursor.execute(query, (username,))
        result = cursor.fetchall()
        conn.close()
        return {"query_executed": query, "results": result}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=400, detail=str(e))
