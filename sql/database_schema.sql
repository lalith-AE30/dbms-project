-- =====================================================
-- Alumni Mentor Portal Database Schema
-- =====================================================

-- Create Database
CREATE DATABASE IF NOT EXISTS mentor_alumni_portal;
USE mentor_alumni_portal;

-- =====================================================
-- CORE TABLES
-- =====================================================

-- 1. Alumni Table (Updated to match actual database structure)
CREATE TABLE Alumni (
    Alumni_ID VARCHAR(20) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Phone_Number BIGINT UNIQUE,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Graduation_Year INT,
    Current_Designation VARCHAR(100),
    Company VARCHAR(100),
    Location VARCHAR(100),
    Years_of_Experience INT
);

-- 2. Student Table
CREATE TABLE Student (
    Student_ID VARCHAR(20) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Phone_Number BIGINT UNIQUE,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Department VARCHAR(100),
    Year_of_Study INT
);

-- 3. Skill Table
CREATE TABLE Skill (
    Skill_ID VARCHAR(20) PRIMARY KEY,
    Skill_Name VARCHAR(100) NOT NULL,
    Proficiency_Level VARCHAR(50),
    Category VARCHAR(50)
);

-- 4. Industry Table
CREATE TABLE Industry (
    Industry_ID VARCHAR(20) PRIMARY KEY,
    Alumni_ID VARCHAR(20),
    Sector VARCHAR(100),
    Location VARCHAR(100),
    Size VARCHAR(50),
    Industry_Name VARCHAR(100),
    FOREIGN KEY (Alumni_ID) REFERENCES Alumni(Alumni_ID)
);

-- 5. Achievement Table
CREATE TABLE Achievement (
    Achievement_ID VARCHAR(20) PRIMARY KEY,
    Alumni_ID VARCHAR(20),
    Awarding_Body VARCHAR(100),
    Title VARCHAR(100),
    Description TEXT,
    Year INT,
    FOREIGN KEY (Alumni_ID) REFERENCES Alumni(Alumni_ID)
);

-- 6. MentorshipSession Table (Updated to match actual database structure)
CREATE TABLE MentorshipSession (
    Session_ID VARCHAR(20) PRIMARY KEY,
    Alumni_ID VARCHAR(20),
    Student_ID VARCHAR(20),
    Session_Date DATE,
    Duration_Minutes INT,
    Topic VARCHAR(200),
    FOREIGN KEY (Alumni_ID) REFERENCES Alumni(Alumni_ID),
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID)
);

-- 7. Feedback Table (Updated to match actual database structure)
CREATE TABLE Feedback (
    Feedback_ID VARCHAR(20) PRIMARY KEY,
    Alumni_ID VARCHAR(20),
    Student_ID VARCHAR(20),
    Rating INT CHECK (Rating >= 1 AND Rating <= 5),
    Date DATE,
    Comments TEXT,
    FOREIGN KEY (Alumni_ID) REFERENCES Alumni(Alumni_ID),
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID)
);

-- =====================================================
-- SAMPLE DATA
-- =====================================================

-- Insert Alumni Data
INSERT INTO Alumni VALUES
('PESALU001', 'Ravi Kumar', 9876543210, 'ravi@alumni.com', 2015, 'Software Engineer', 8),
('PESALU002', 'Sneha R', 9876500000, 'sneha@alumni.com', 2018, 'Data Scientist', 5),
('PESALU003', 'Arun Raj', 9988776655, 'arun@alumni.com', 2016, 'Product Manager', 7),
('PESALU004', 'Divya Sharma', 9123456780, 'divya@alumni.com', 2019, 'UX Designer', 4),
('PESALU005', 'Kiran M', 9871234567, 'kiran@alumni.com', 2014, 'DevOps Engineer', 10),
('PESALU006', 'Fatima Noor', 9090909090, 'fatima@alumni.com', 2020, 'Data Analyst', 3);

-- Insert Student Data
INSERT INTO Student VALUES
('PESSTU001', 'Ananya', 9900000001, 'ananya@pes.edu', 'CSE', 3),
('PESSTU002', 'Arjun', 9900000002, 'arjun@pes.edu', 'ECE', 2),
('PESSTU003', 'Megha', 9900000003, 'megha@pes.edu', 'ISE', 4),
('PESSTU004', 'Rohit', 9900000004, 'rohit@pes.edu', 'CSE', 1),
('PESSTU005', 'Tanya', 9900000005, 'tanya@pes.edu', 'ME', 2),
('PESSTU006', 'Vikram', 9900000006, 'vikram@pes.edu', 'EEE', 3);

-- Insert Skill Data
INSERT INTO Skill VALUES
('PESSK001', 'Python', 'Intermediate', 'Programming'),
('PESSK002', 'Machine Learning', 'Beginner', 'AI/ML'),
('PESSK003', 'Communication', 'Advanced', 'Soft Skill'),
('PESSK004', 'Java', 'Intermediate', 'Programming'),
('PESSK005', 'Cloud Computing', 'Beginner', 'Infrastructure'),
('PESSK006', 'UI/UX Design', 'Advanced', 'Design');

-- Insert Industry Data
INSERT INTO Industry VALUES
('PESIND001', 'PESALU001', 'Software', 'Bangalore', 'Large', 'TechCorp'),
('PESIND002', 'PESALU002', 'Analytics', 'Hyderabad', 'Medium', 'DataWorks'),
('PESIND003', 'PESALU003', 'Product', 'Chennai', 'Large', 'Prodify'),
('PESIND004', 'PESALU004', 'Design', 'Pune', 'Small', 'CreativeLab'),
('PESIND005', 'PESALU005', 'Infrastructure', 'Delhi', 'Large', 'CloudX'),
('PESIND006', 'PESALU006', 'Analytics', 'Mumbai', 'Medium', 'InsightAI');

-- Insert Achievement Data
INSERT INTO Achievement VALUES
('PESACH001', 'PESALU001', 'Google', 'Best Innovator', 'Awarded for outstanding innovation', 2020),
('PESACH002', 'PESALU002', 'Microsoft', 'Rising Star', 'Early career recognition', 2021),
('PESACH003', 'PESALU003', 'Amazon', 'Leadership Excellence', 'Recognized for leadership skills', 2022),
('PESACH004', 'PESALU004', 'Adobe', 'Design Excellence', 'Award for UX design work', 2023),
('PESACH005', 'PESALU005', 'AWS', 'Top Cloud Architect', 'For contributions to DevOps community', 2019),
('PESACH006', 'PESALU006', 'Tableau', 'Data Visualization Pro', 'Outstanding dashboards', 2024);

-- Insert Mentorship Sessions (Updated to match actual database structure)
INSERT INTO MentorshipSession VALUES
('SES001', 'PESALU001', 'PESSTU001', '2025-09-15', 60, 'Career Guidance'),
('SES002', 'PESALU002', 'PESSTU002', '2025-09-20', 120, 'Data Science Path'),
('SES003', 'PESALU003', 'PESSTU003', '2025-09-25', 45, 'Product Management'),
('SES004', 'PESALU004', 'PESSTU004', '2025-09-28', 90, 'UX Design Portfolio'),
('SES005', 'PESALU005', 'PESSTU005', '2025-09-30', 60, 'Cloud Computing'),
('SES006', 'PESALU006', 'PESSTU006', '2025-10-01', 60, 'Analytics Fundamentals');

-- Insert Feedback Data (Updated to match actual database structure)
INSERT INTO Feedback VALUES
('FDB001', 'PESALU001', 'PESSTU001', 5, '2025-09-15', 'Very helpful session!'),
('FDB002', 'PESALU002', 'PESSTU002', 4, '2025-09-20', 'Great insights shared.'),
('FDB003', 'PESALU003', 'PESSTU003', 5, '2025-09-25', 'Loved the product tips!'),
('FDB004', 'PESALU004', 'PESSTU004', 4, '2025-09-28', 'Very interactive session.'),
('FDB005', 'PESALU005', 'PESSTU005', 5, '2025-09-30', 'Learned a lot about cloud.'),
('FDB006', 'PESALU006', 'PESSTU006', 4, '2025-10-01', 'Good overview of analytics.');

-- Display success message
SELECT 'Database schema created successfully!' AS Status;
SELECT 'Tables created: 7' AS Info;
SELECT 'Sample records inserted: 42' AS Info;