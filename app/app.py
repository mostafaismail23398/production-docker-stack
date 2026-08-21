from flask import Flask, jsonify, request
import os
import psycopg2

app = Flask(__name__)


def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "db"),
        database=os.getenv("DB_NAME", "appdb"),
        user=os.getenv("DB_USER", "appuser"),
        password=os.getenv("DB_PASSWORD", "password"),
    )


def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL
        );
    """)

    conn.commit()
    cursor.close()
    conn.close()


@app.route("/")
def home():
    return jsonify({
        "message": "Production Docker Stack is running",
        "status": "healthy"
    })


@app.route("/health")
def health():
    try:
        conn = get_db_connection()
        conn.close()

        return jsonify({
            "status": "healthy",
            "database": "connected"
        }), 200

    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }), 503


@app.route("/users", methods=["GET"])
def get_users():
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT id, name FROM users ORDER BY id;")
    users = cursor.fetchall()

    cursor.close()
    conn.close()

    return jsonify([
        {
            "id": user[0],
            "name": user[1]
        }
        for user in users
    ])


@app.route("/users", methods=["POST"])
def create_user():
    data = request.get_json()

    name = data.get("name")

    if not name:
        return jsonify({"error": "name is required"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        "INSERT INTO users (name) VALUES (%s) RETURNING id;",
        (name,)
    )

    user_id = cursor.fetchone()[0]

    conn.commit()

    cursor.close()
    conn.close()

    return jsonify({
        "id": user_id,
        "name": name
    }), 201


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000)