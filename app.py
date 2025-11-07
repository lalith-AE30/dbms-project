#!/usr/bin/env python3
"""
Alumni Mentor Portal - Flask Testing Application
This app provides a web interface to test the MySQL database functionality
"""

import os
import mysql.connector
from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
from mysql.connector import Error
from datetime import datetime, date
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.secret_key = 'your-secret-key-here'

# Database configuration
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

def execute_procedure(procedure_name, params=None):
    """Execute stored procedure"""
    connection = get_db_connection()
    if not connection:
        return None

    try:
        cursor = connection.cursor(dictionary=True)

        if params:
            placeholders = ','.join(['%s'] * len(params))
            cursor.callproc(procedure_name, params)
        else:
            cursor.callproc(procedure_name)

        # Get results from the procedure
        result = []
        for dataset in cursor.stored_results():
            result.extend(dataset.fetchall())

        cursor.close()
        return result
    except Error as e:
        logger.error(f"Error executing procedure {procedure_name}: {e}")
        return None
    finally:
        connection.close()

@app.route('/')
def index():
    """Home page"""
    return render_template('index.html')

@app.route('/dashboard')
def dashboard():
    """Dashboard showing database statistics"""
    try:
        stats = {}

        # Get table counts
        stats['alumni_count'] = execute_query("SELECT COUNT(*) as count FROM Alumni")[0]['count']
        stats['student_count'] = execute_query("SELECT COUNT(*) as count FROM Student")[0]['count']
        stats['session_count'] = execute_query("SELECT COUNT(*) as count FROM MentorshipSession")[0]['count']
        stats['feedback_count'] = execute_query("SELECT COUNT(*) as count FROM Feedback")[0]['count']

        # Get recent activity
        stats['recent_sessions'] = execute_query("""
            SELECT ms.Session_Date, a.Name as Alumni_Name, s.Name as Student_Name
            FROM MentorshipSession ms
            JOIN Alumni a ON ms.Alumni_ID = a.Alumni_ID
            JOIN Student s ON ms.Student_ID = s.Student_ID
            ORDER BY ms.Session_Date DESC LIMIT 5
        """)

        return render_template('dashboard.html', stats=stats)
    except Exception as e:
        flash(f'Error loading dashboard: {str(e)}', 'error')
        return render_template('dashboard.html', stats={})

# Alumni Routes
@app.route('/alumni')
def list_alumni():
    """List all alumni"""
    alumni = execute_query("""
        SELECT Alumni_ID, Name, Email, Current_Designation, Company, Years_of_Experience
        FROM Alumni
        ORDER BY Name
    """)
    return render_template('alumni/list.html', alumni=alumni)

@app.route('/alumni/add', methods=['GET', 'POST'])
def add_alumni():
    """Add new alumni"""
    if request.method == 'POST':
        try:
            data = request.form
            query = """
                INSERT INTO Alumni (Alumni_ID, Name, Phone_Number, Email, Graduation_Year,
                                  Current_Designation, Company, Location, Years_of_Experience)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            params = (
                data['alumni_id'], data['name'], data['phone'], data['email'],
                data['graduation_year'], data['designation'], data['company'],
                data['location'], data['experience'] or None
            )

            execute_query(query, params, fetch=False)
            flash('Alumni added successfully!', 'success')
            return redirect(url_for('list_alumni'))

        except Exception as e:
            flash(f'Error adding alumni: {str(e)}', 'error')
            return render_template('alumni/add.html')

    return render_template('alumni/add.html')

# Student Routes
@app.route('/students')
def list_students():
    """List all students"""
    students = execute_query("""
        SELECT Student_ID, Name, Email, Department, Year_of_Study
        FROM Student
        ORDER BY Name
    """)
    return render_template('students/list.html', students=students)

@app.route('/students/add', methods=['GET', 'POST'])
def add_student():
    """Add new student"""
    if request.method == 'POST':
        try:
            data = request.form
            query = """
                INSERT INTO Student (Student_ID, Name, Phone_Number, Email, Department, Year_of_Study)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            params = (
                data['student_id'], data['name'], data['phone'], data['email'],
                data['department'], data['year_of_study']
            )

            execute_query(query, params, fetch=False)
            flash('Student added successfully!', 'success')
            return redirect(url_for('list_students'))

        except Exception as e:
            flash(f'Error adding student: {str(e)}', 'error')
            return render_template('students/add.html')

    return render_template('students/add.html')

# Mentorship Session Routes
@app.route('/sessions')
def list_sessions():
    """List mentorship sessions"""
    sessions = execute_query("""
        SELECT ms.Session_ID, ms.Session_Date, ms.Duration_Minutes, ms.Topic,
               a.Name as Alumni_Name, s.Name as Student_Name
        FROM MentorshipSession ms
        JOIN Alumni a ON ms.Alumni_ID = a.Alumni_ID
        JOIN Student s ON ms.Student_ID = s.Student_ID
        ORDER BY ms.Session_Date DESC
    """)
    return render_template('sessions/list.html', sessions=sessions)

@app.route('/sessions/add', methods=['GET', 'POST'])
def add_session():
    """Add new mentorship session"""
    if request.method == 'POST':
        try:
            data = request.form
            query = """
                INSERT INTO MentorshipSession (Session_ID, Alumni_ID, Student_ID,
                                             Session_Date, Duration_Minutes, Topic)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            params = (
                data['session_id'], data['alumni_id'], data['student_id'],
                data['session_date'], data['duration'], data['topic']
            )

            execute_query(query, params, fetch=False)
            flash('Session added successfully!', 'success')
            return redirect(url_for('list_sessions'))

        except Exception as e:
            flash(f'Error adding session: {str(e)}', 'error')
            # Get alumni and student lists for dropdown
            alumni = execute_query("SELECT Alumni_ID, Name FROM Alumni ORDER BY Name")
            students = execute_query("SELECT Student_ID, Name FROM Student ORDER BY Name")
            return render_template('sessions/add.html', alumni=alumni, students=students)

    # Get alumni and student lists for dropdown
    alumni = execute_query("SELECT Alumni_ID, Name FROM Alumni ORDER BY Name")
    students = execute_query("SELECT Student_ID, Name FROM Student ORDER BY Name")
    return render_template('sessions/add.html', alumni=alumni, students=students)

# Feedback Routes
@app.route('/feedback')
def list_feedback():
    """List all feedback"""
    # Get alumni filter parameter
    alumni_filter = request.args.get('alumni_id', '')
    
    # Get all alumni for dropdown
    alumni = execute_query("SELECT Alumni_ID, Name FROM Alumni ORDER BY Name")
    
    # Build query based on filter
    if alumni_filter:
        feedback = execute_query("""
            SELECT f.Feedback_ID, f.Rating, f.Date, f.Comments,
                   a.Name as Alumni_Name, s.Name as Student_Name
            FROM Feedback f
            JOIN Alumni a ON f.Alumni_ID = a.Alumni_ID
            JOIN Student s ON f.Student_ID = s.Student_ID
            WHERE f.Alumni_ID = %s
            ORDER BY f.Date DESC
        """, (alumni_filter,))
    else:
        feedback = execute_query("""
            SELECT f.Feedback_ID, f.Rating, f.Date, f.Comments,
                   a.Name as Alumni_Name, s.Name as Student_Name
            FROM Feedback f
            JOIN Alumni a ON f.Alumni_ID = a.Alumni_ID
            JOIN Student s ON f.Student_ID = s.Student_ID
            ORDER BY f.Date DESC
        """)
    
    return render_template('feedback/list.html', feedback=feedback, alumni=alumni, selected_alumni=alumni_filter)

@app.route('/feedback/add', methods=['GET', 'POST'])
def add_feedback():
    """Add new feedback"""
    if request.method == 'POST':
        try:
            data = request.form
            query = """
                INSERT INTO Feedback (Feedback_ID, Alumni_ID, Student_ID,
                                    Rating, Date, Comments)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            params = (
                data['feedback_id'], data['alumni_id'], data['student_id'],
                data['rating'], data['feedback_date'], data['comments']
            )

            execute_query(query, params, fetch=False)
            flash('Feedback added successfully!', 'success')
            return redirect(url_for('list_feedback'))

        except Exception as e:
            flash(f'Error adding feedback: {str(e)}', 'error')
            # Get alumni and student lists for dropdown
            alumni = execute_query("SELECT Alumni_ID, Name FROM Alumni ORDER BY Name")
            students = execute_query("SELECT Student_ID, Name FROM Student ORDER BY Name")
            return render_template('feedback/add.html', alumni=alumni, students=students)

    # Get alumni and student lists for dropdown
    alumni = execute_query("SELECT Alumni_ID, Name FROM Alumni ORDER BY Name")
    students = execute_query("SELECT Student_ID, Name FROM Student ORDER BY Name")
    return render_template('feedback/add.html', alumni=alumni, students=students)

# Connections Route
@app.route('/connections')
def alumni_student_connections():
    """Show alumni-student mentorship connections"""
    query = """
        SELECT 
            a.Name as Alumni_Name,
            a.Company,
            a.Current_Designation,
            s.Name as Student_Name,
            s.Department,
            s.Year_of_Study,
            COUNT(ms.Session_ID) as Total_Sessions,
            MAX(ms.Session_Date) as Last_Session
        FROM Alumni a
        INNER JOIN MentorshipSession ms ON a.Alumni_ID = ms.Alumni_ID
        INNER JOIN Student s ON ms.Student_ID = s.Student_ID
        GROUP BY a.Alumni_ID, a.Name, a.Company, a.Current_Designation,
                 s.Student_ID, s.Name, s.Department, s.Year_of_Study
        ORDER BY Total_Sessions DESC, Last_Session DESC
    """
    connections = execute_query(query)
    return render_template('connections.html', connections=connections)

# Trigger Testing Routes
@app.route('/test/triggers')
def test_triggers():
    """Test database triggers"""
    return render_template('test/triggers.html')

@app.route('/test/email_uniqueness', methods=['POST'])
def test_email_uniqueness():
    """Test email uniqueness trigger"""
    try:
        # Try to insert duplicate email
        query = """
            INSERT INTO Student (Student_ID, Name, Email, Department, Year_of_Study)
            VALUES (%s, %s, %s, %s, %s)
        """
        params = ('TEST_EMAIL', 'Test Student', 'john.doe@example.com', 'CS', 2)
        execute_query(query, params, fetch=False)
        flash('❌ Email uniqueness trigger FAILED - duplicate email was allowed', 'error')
    except Exception as e:
        if "Email already registered" in str(e):
            flash('✅ Email uniqueness trigger WORKED - duplicate email blocked', 'success')
        else:
            flash(f'⚠️ Unexpected error: {str(e)}', 'warning')

    return redirect(url_for('test_triggers'))

@app.route('/test/rating_validation', methods=['POST'])
def test_rating_validation():
    """Test rating validation trigger"""
    try:
        # Try to insert invalid rating
        query = """
            INSERT INTO Feedback (Feedback_ID, Alumni_ID, Student_ID, Rating, Date)
            VALUES (%s, %s, %s, %s, %s)
        """
        params = ('TEST_RATING', 'ALUM001', 'STU001', 6, date.today())
        execute_query(query, params, fetch=False)
        flash('❌ Rating validation trigger FAILED - invalid rating (6) was allowed', 'error')
    except Exception as e:
        if "Rating must be between 1 and 5" in str(e):
            flash('✅ Rating validation trigger WORKED - invalid rating (6) blocked', 'success')
        else:
            flash(f'⚠️ Unexpected error: {str(e)}', 'warning')

    return redirect(url_for('test_triggers'))

@app.route('/test/auto_logging', methods=['POST'])
def test_auto_logging():
    """Test automatic feedback logging trigger"""
    try:
        # Insert valid feedback
        query = """
            INSERT INTO Feedback (Feedback_ID, Alumni_ID, Student_ID, Rating, Date, Comments)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        params = ('TEST_AUTO_LOG', 'ALUM001', 'STU001', 5, date.today(), 'Test auto logging')
        execute_query(query, params, fetch=False)

        # Check if it was logged
        log_check = execute_query("""
            SELECT COUNT(*) as count FROM Feedback_Log
            WHERE Alumni_ID = 'ALUM001' AND Student_ID = 'STU001'
        """)

        if log_check and log_check[0]['count'] > 0:
            flash('✅ Auto-logging trigger WORKED - feedback was automatically logged', 'success')
        else:
            flash('❌ Auto-logging trigger FAILED - feedback was not logged', 'error')
    except Exception as e:
        flash(f'⚠️ Error testing auto-logging: {str(e)}', 'warning')

    return redirect(url_for('test_triggers'))

# Procedure Testing Routes

@app.route('/test/procedures')
def test_procedures():
    """Test stored procedures"""
    return render_template('test/procedures.html')

@app.route('/api/procedures/<procedure_name>', methods=['POST'])
def api_test_procedure(procedure_name):
    try:
        if procedure_name == "RegisterStudent":
            params = ('STU999', 'Test User', 9876543210, 'test@pes.edu', 'CSE', 2)
        elif procedure_name == "ScheduleSession":
            params = ('SES100', 'PESALU001', 'STU999', '2025-11-05', 60, 'Career Guidance')
        elif procedure_name == "SubmitFeedback":
            params = ('FDB100', 'PESALU001', 'STU999', 5, '2025-11-05', 'Great session')

        result = execute_procedure(procedure_name, params)

        return jsonify({'success': True, 'data': result})

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)