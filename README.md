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
   # - database_schema.sql
   # - database_triggers.sql
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

5. **Verify installation**
   ```bash
   mysql -u root -p mentor_alumni_portal -e "SHOW TABLES; SHOW TRIGGERS;"
   ```

## 📁 File Structure

```
dbms/
├── README.md                         # This documentation
├── database_schema.sql               # Database tables and sample data
├── database_triggers.sql             # All database triggers
├── validate.sql                      # Validation script to test functionality
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

### Business Logic Triggers

- **Referential Integrity**: Enforces foreign key constraints
- **Cascade Operations**: Maintains data consistency across related tables
- **Achievement Tracking**: Awards distinguished status for alumni with 5+ achievements

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

After installation, run the validation script to ensure everything is working:

```bash
mysql -u root -p < validate.sql
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

The script shows before/after counts for each operation to prove triggers are working.

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
