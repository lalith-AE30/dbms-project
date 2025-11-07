import mysql.connector
import logging
from mysql.connector import Error

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'root',
    'database': 'mentor_alumni_portal',
    'autocommit': True
}

def get_db_connection():
    """Get database connection"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        if connection.is_connected():
            logger.info("Successfully connected to database")
            return connection
    except Error as e:
        logger.error(f"Error connecting to database: {e}")
        return None
    return None

def execute_query(query, params=None, fetch=True):
    """Execute database query"""
    connection = get_db_connection()
    if not connection:
        return None

    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(query, params)

        if fetch:
            result = cursor.fetchall()
        else:
            result = cursor.rowcount

        cursor.close()
        return result
    except Error as e:
        logger.error(f"Error executing query: {e}")
        return None
    finally:
        connection.close()

query = """
    INSERT INTO Student (Student_ID, Name, Phone_Number, Email, Department, Year_of_Study)
    VALUES (%s, %s, %s, %s, %s, %s)
"""
params = (
    '9234734', 'Alice B Johnson', '12335672890', 'alice.johnson@example.com', 'Computer Science', 2
)

execute_query(query, params, fetch=False)

students = execute_query("""
        SELECT *
        FROM Student
        ORDER BY Name
""")

for s in students:
    logger.info(s)