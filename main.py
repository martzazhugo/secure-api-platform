from fastapi import FastAPI, HTTPException
import sqlite3

app = FastAPI(title="Secure API Platform - Lab")
DB_FILE = "app_lab.db"

# Inisialisasi DB SQLite sederhana
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

# VULNERABILITY #1: Hardcoded Secret
JWT_SECRET_KEY = "super-secret-key-that-should-not-be-hardcoded"

@app.get("/")
def read_root():
    return {"status": "healthy", "service": "secure-api-platform"}

# VULNERABILITY #2: SQL Injection via Raw Query Formatting
@app.get("/api/v1/users/search")
def search_user(username: str):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    query = f"SELECT id, username, role FROM users WHERE username = '{username}'"
    try:
        cursor.execute(query)
        result = cursor.fetchall()
        conn.close()
        return {"query_executed": query, "results": result}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=400, detail=str(e))
