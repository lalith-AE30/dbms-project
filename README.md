# Alumni Mentor Portal Database

A comprehensive MySQL database system for managing an alumni-student mentorship program with automated triggers for data integrity and business logic enforcement.

## 📋 Overview

The Alumni Mentor Portal facilitates mentorship connections between experienced alumni and current students. It includes:

- Alumni profiles with experience and achievements
- Student profiles with academic information
- Mentorship session tracking
- Feedback system with ratings
- Skill management
- Industry information
- Automated triggers for data validation and relationships

## 🗄️ Database Schema

### Core Tables

- **Alumni** - Alumni information and professional details
- **Student** - Student academic and contact information
- **Skill** - Skills database with categories
- **Industry** - Alumni industry information
- **Achievement** - Alumni achievements and awards
- **MentorshipSession** - Scheduled mentorship sessions
- **Feedback** - Session feedback and ratings

### Auxiliary Tables

- **Provides** - Mentor-mentee relationships
- **Alumni_Skills** - Alumni skill associations
- **Student_Skills** - Student skill interests
- **Mentorship_Request** - Mentorship request tracking
- **Feedback_Log** - Audit trail for feedback

## 🚀 Quick Setup

### Prerequisites
- MySQL 8.0 or higher
- MySQL command-line client or MySQL Workbench
- Root or user privileges with CREATE, INSERT, TRIGGER permissions

### Installation Steps

1. **Clone or download the database files**

   ```bash
   # Make sure you have the required SQL files:
   # - database_schema.sql (required)
   # - database_triggers.sql (required)
   # - database_procedures_functions.sql (optional - for advanced features)
   # - additional_triggers.sql (optional - for enhanced triggers)
   # - simple_procedures.sql (optional - for common tasks)
   ```

2. **(Optional) Drop existing database** - Use this only if you want a fresh install

   ```bash
   mysql -u root -p -e "DROP DATABASE IF EXISTS mentor_alumni_portal;"
   ```

3. **Create the database**

   ```bash
   mysql -u root -p < database_schema.sql
   ```

   Enter your MySQL password when prompted.

4. **Install triggers**

   ```bash
   mysql -u root -p mentor_alumni_portal < database_triggers.sql
   ```

5. **(Optional) Install advanced stored procedures and functions**

   ```bash
   mysql -u root -p mentor_alumni_portal < database_procedures_functions.sql
   ```

6. **(Optional) Install additional enhanced triggers**

   ```bash
   mysql -u root -p mentor_alumni_portal < additional_triggers.sql
   ```

7. **(Optional) Install simple procedures for common tasks**

   ```bash
   mysql -u root -p mentor_alumni_portal < simple_procedures.sql
   ```

8. **Verify installation**
   ```bash
   mysql -u root -p mentor_alumni_portal -e "SHOW TABLES; SHOW TRIGGERS; SHOW PROCEDURE STATUS; SHOW FUNCTION STATUS;"
   ```

## 📁 File Structure

```
dbms/
├── README.md                         # This documentation
├── database_schema.sql               # Database tables and sample data
├── database_triggers.sql             # All database triggers
├── validate.sql                      # Validation script to test functionality
├── database_procedures_functions.sql # Advanced stored procedures and functions
├── additional_triggers.sql           # Additional triggers for enhanced features
├── simple_procedures.sql             # Simple stored procedures for common tasks
├── test_new_features.sql             # Test script for new features
├── feature_summary.md                # Summary of all features
└── relation_diagram.jpg              # Database relation diagram
```

## 🎯 Key Features & Triggers

### Data Validation Triggers

- **Email Uniqueness**: Prevents duplicate emails for students and alumni
- **Phone Number Format**: Validates 10-digit phone numbers
- **Rating Constraints**: Ensures feedback ratings are between 1-5
- **Date Validation**: Prevents future dates for feedback and sessions
- **Academic Year**: Validates year of study (1-4)

### Automation Triggers

- **Experience Calculation**: Automatically calculates years of experience from graduation year
- **Relationship Creation**: Auto-creates mentor-mentee relationships after first session
- **Feedback Logging**: Automatically logs all feedback entries
- **Premium Mentor Status**: Updates mentor status based on ratings and session count
- **Auto-accept Requests**: Automatically accepts mentorship requests when sessions are scheduled
- **Distinguished Status**: Awards distinguished status to alumni with 5+ achievements
- **Skill Match Logging**: Logs potential mentor-mentee matches based on skills
- **Session Limits**: Enforces daily session limits for quality control
- **Graduation Handling**: Automatically graduates students and updates their status

### Business Logic Triggers

- **Referential Integrity**: Enforces foreign key constraints
- **Cascade Operations**: Maintains data consistency across related tables
- **Achievement Tracking**: Awards distinguished status for alumni with 5+ achievements

## 🔧 Stored Procedures & Functions

### Mentorship Request Management
- **sp_create_mentorship_request**: Creates mentorship requests with validation
- **sp_accept_mentorship_request**: Accepts requests and creates relationships
- **sp_reject_mentorship_request**: Rejects requests with response message

### Analytics & Reporting
- **sp_find_mentor_matches**: Finds compatible mentors based on skills
- **sp_alumni_performance_dashboard**: Alumni performance metrics
- **sp_department_statistics**: Department-wise mentorship statistics
- **sp_trending_skills**: Shows most in-demand skills
- **sp_get_alumni_statistics**: Individual alumni statistics
- **sp_get_student_sessions**: Student session history
- **sp_get_top_mentors**: Top mentors by rating
- **sp_get_department_stats**: Department-wise statistics

### Utility Functions
- **fn_calculate_skill_match**: Calculates skill compatibility percentage
- **fn_months_since_graduation**: Calculates months since graduation

### Database Views
- **v_mentorship_summary**: Overview of all mentorship relationships
- **v_top_mentors**: Best performing mentors ranked by rating
- **v_skill_gap_analysis**: Supply/demand analysis for skills

## 📊 Sample Data

The database includes sample data for testing:

- **6 Alumni**: Various roles (Software Engineer, Data Scientist, Product Manager, etc.)
- **6 Students**: From different departments and years
- **6 Skills**: Mix of technical and soft skills
- **6 Industries**: Different sectors and locations
- **6 Achievements**: Awards and recognitions
- **6 Sessions**: Sample mentorship sessions
- **6 Feedback**: Ratings and comments

## 🧪 Validation and Testing

### Basic Validation

After installation, run the validation script to ensure everything is working:

```bash
mysql -u root -p < validate.sql
```

### Testing New Features

To test the advanced features and procedures:

```bash
# Test additional triggers and enhanced features
mysql -u root -p mentor_alumni_portal < test_new_features.sql
```

### Expected Output

The validation script demonstrates all trigger functionality by:

- ✅ Validating student data (email uniqueness, phone format, year of study)
- ✅ Auto-calculating alumni experience from graduation year
- ✅ Auto-creating mentor-mentee relationships when sessions are added
- ✅ Auto-logging all feedback entries
- ✅ Enforcing rating constraints (1-5)
- ✅ Updating mentor status based on performance
- ✅ Blocking invalid data with clear error messages

The test_new_features.sql script additionally tests:

- ✅ Mentorship request workflow (create, accept, reject)
- ✅ Skill-based matching algorithms
- ✅ Premium mentor status updates
- ✅ Distinguished alumni recognition
- ✅ Session limit enforcement
- ✅ Activity logging and audit trails

The scripts show before/after counts for each operation to prove triggers and procedures are working.

## 💻 Usage Examples

### Adding a New Student

```sql
INSERT INTO Student VALUES ('STU007', 'John Doe', 9876543210, 'john@pes.edu', 'CSE', 3);
```

- Trigger validates email uniqueness
- Trigger validates phone number format
- Trigger validates year of study

### Scheduling a Mentorship Session

```sql
INSERT INTO MentorshipSession VALUES ('PESALU001', 'STU007', '2025-12-01', 'Online', '1 hour');
```

- Trigger validates alumni and student existence
- Trigger auto-creates relationship in Provides table
- Trigger updates mentorship request status if pending

### Submitting Feedback

```sql
INSERT INTO Feedback VALUES ('PESALU001', 'STU007', '2025-12-01', 'Great session!', 5);
```

- Trigger validates rating (1-5)
- Trigger validates date (not in future)
- Trigger logs feedback automatically
- Trigger updates mentor statistics

### Using Stored Procedures

#### Create a Mentorship Request

```sql
CALL sp_create_mentorship_request('PESALU001', 'STU007', 'Interested in machine learning guidance');
```

#### Accept a Mentorship Request

```sql
CALL sp_accept_mentorship_request(1, 'Looking forward to mentoring you!');
```

#### Find Compatible Mentors

```sql
CALL sp_find_mentor_matches('CSE', 'Python', 'Machine Learning');
```

#### Get Alumni Statistics

```sql
CALL sp_get_alumni_statistics('PESALU001');
```

#### View Student Session History

```sql
CALL sp_get_student_sessions('PESSTU001');
```

#### Get Top Mentors

```sql
CALL sp_get_top_mentors(5);
```

#### Department-wise Statistics

```sql
CALL sp_get_department_stats();
```

### Using Functions

#### Calculate Months Since Graduation

```sql
SELECT fn_months_since_graduation(2020) AS Months_Since_Graduation;
```

#### Calculate Skill Match Percentage

```sql
SELECT fn_calculate_skill_match('PESALU001', 'STU007') AS Match_Percentage;
```

## 🔧 Common Operations

### View All Alumni

```sql
SELECT * FROM Alumni;
```

### View Student Sessions

```sql
SELECT s.Name, m.Date, m.Mode, m.Duration
FROM MentorshipSession m
JOIN Student s ON m.Student_ID = s.Student_ID
WHERE s.Student_ID = 'PESSTU001';
```

### View Average Ratings for Alumni

```sql
SELECT a.Name, AVG(f.Rating) AS Avg_Rating, COUNT(*) AS Total_Sessions
FROM Alumni a
LEFT JOIN Feedback f ON a.Alumni_ID = f.Alumni_ID
GROUP BY a.Alumni_ID, a.Name
ORDER BY Avg_Rating DESC;
```

### Find Alumni by Industry

```sql
SELECT a.Name, i.Industry_Name, i.Location, i.Sector
FROM Alumni a
JOIN Industry i ON a.Alumni_ID = i.Alumni_ID
WHERE i.Sector = 'Software';
```

## 📚 Additional Resources

### Feature Summary
For a comprehensive list of all features, triggers, procedures, and functions, refer to:
- [feature_summary.md](feature_summary.md) - Complete feature documentation

### Database Schema Visualization
- [relation_diagram.jpg](relation_diagram.jpg) - Visual representation of table relationships

### Advanced Features Documentation
- **Stored Procedures**: See `database_procedures_functions.sql` for advanced procedures
- **Simple Procedures**: See `simple_procedures.sql` for common operations
- **Additional Triggers**: See `additional_triggers.sql` for enhanced automation

### Performance Considerations
- Indexes have been created on frequently queried columns (IDs, emails, dates)
- Stored procedures use optimized queries for better performance
- Views are available for complex reporting queries
- Consider partitioning large tables by date for production use

### Security Notes
- Input validation is handled at the database level through triggers
- Stored procedures use parameterized queries to prevent SQL injection
- Consider implementing row-level security for multi-tenant deployments
