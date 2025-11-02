-- =====================================================
-- Alumni Mentor Portal - Complete Trigger Implementation (MySQL Compatible)
-- =====================================================

USE mentor_alumni_portal;

-- First, create missing tables that are referenced in triggers
DELIMITER $$

-- Create Provides table (many-to-many relationship between Alumni and Students)
CREATE TABLE IF NOT EXISTS Provides (
    Alumni_ID VARCHAR(20),
    Student_ID VARCHAR(20),
    Mentorship_Start_Date DATE DEFAULT (CURRENT_DATE),
    Status VARCHAR(20) DEFAULT 'Active',
    PRIMARY KEY (Alumni_ID, Student_ID),
    FOREIGN KEY (Alumni_ID) REFERENCES Alumni(Alumni_ID) ON DELETE CASCADE,
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE
)$$

-- Create Alumni_Skills table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS Alumni_Skills (
    Alumni_ID VARCHAR(20),
    Skill_ID VARCHAR(20),
    Acquired_Date DATE DEFAULT (CURRENT_DATE),
    Proficiency_Level VARCHAR(50),
    PRIMARY KEY (Alumni_ID, Skill_ID),
    FOREIGN KEY (Alumni_ID) REFERENCES Alumni(Alumni_ID) ON DELETE CASCADE,
    FOREIGN KEY (Skill_ID) REFERENCES Skill(Skill_ID) ON DELETE CASCADE
)$$

-- Create Student_Skills table (skills students want to learn)
CREATE TABLE IF NOT EXISTS Student_Skills (
    Student_ID VARCHAR(20),
    Skill_ID VARCHAR(20),
    Priority_Level INT DEFAULT 1,
    Status VARCHAR(20) DEFAULT 'Wanted',
    PRIMARY KEY (Student_ID, Skill_ID),
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    FOREIGN KEY (Skill_ID) REFERENCES Skill(Skill_ID) ON DELETE CASCADE
)$$

-- Create Mentorship_Request table for tracking requests
CREATE TABLE IF NOT EXISTS Mentorship_Request (
    Request_ID INT AUTO_INCREMENT PRIMARY KEY,
    Alumni_ID VARCHAR(20),
    Student_ID VARCHAR(20),
    Request_Date DATE DEFAULT (CURRENT_DATE),
    Status VARCHAR(20) DEFAULT 'Pending',
    Request_Message TEXT,
    Response_Date DATE,
    Response_Message TEXT,
    FOREIGN KEY (Alumni_ID) REFERENCES Alumni(Alumni_ID),
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID)
)$$

-- Create Feedback_Log table for audit trail
CREATE TABLE IF NOT EXISTS Feedback_Log (
    Log_ID INT AUTO_INCREMENT PRIMARY KEY,
    Alumni_ID VARCHAR(20),
    Student_ID VARCHAR(20),
    Feedback_Date DATE,
    Logged_At TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)$$

DELIMITER ;

-- =====================================================
-- TRIGGER IMPLEMENTATIONS
-- =====================================================

-- =====================================================
-- 1. FEEDBACK RELATED TRIGGERS
-- =====================================================

DELIMITER $$

-- Trigger: Log feedback automatically when inserted
CREATE TRIGGER tr_feedback_after_insert
AFTER INSERT ON Feedback
FOR EACH ROW
BEGIN
    -- Log the feedback entry
    INSERT INTO Feedback_Log (Alumni_ID, Student_ID, Feedback_Date)
    VALUES (NEW.Alumni_ID, NEW.Student_ID, NEW.Date);
END$$

-- Trigger: Validate feedback before insert
CREATE TRIGGER tr_feedback_before_insert
BEFORE INSERT ON Feedback
FOR EACH ROW
BEGIN
    -- Ensure rating is between 1 and 5
    IF NEW.Rating < 1 OR NEW.Rating > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rating must be between 1 and 5';
    END IF;

    -- Ensure date is not in the future
    IF NEW.Date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Feedback date cannot be in the future';
    END IF;
END$$

DELIMITER ;

-- =====================================================
-- 2. STUDENT RELATED TRIGGERS
-- =====================================================

DELIMITER $$

-- Trigger: Validate student data before insert
CREATE TRIGGER tr_student_before_insert
BEFORE INSERT ON Student
FOR EACH ROW
BEGIN
    DECLARE email_count INT;

    -- Check if email already exists
    SELECT COUNT(*) INTO email_count
    FROM Student
    WHERE Email = NEW.Email;

    IF email_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email already registered for another student';
    END IF;

    -- Validate phone number format (should be 10 digits)
    IF NEW.Phone_Number IS NOT NULL AND (NEW.Phone_Number < 1000000000 OR NEW.Phone_Number > 9999999999) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Phone number must be 10 digits';
    END IF;

    -- Validate year of study (1-4 for undergraduate)
    IF NEW.Year_of_Study IS NOT NULL AND (NEW.Year_of_Study < 1 OR NEW.Year_of_Study > 4) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Year of study must be between 1 and 4';
    END IF;
END$$

-- Trigger: Update mentorship statistics after feedback
CREATE TRIGGER tr_feedback_comprehensive_after_insert
AFTER INSERT ON Feedback
FOR EACH ROW
BEGIN
    DECLARE avg_rating DECIMAL(3,2);
    DECLARE total_sessions INT;

    -- Calculate average rating
    SELECT AVG(Rating) INTO avg_rating
    FROM Feedback
    WHERE Alumni_ID = NEW.Alumni_ID;

    -- Count total sessions
    SELECT COUNT(*) INTO total_sessions
    FROM MentorshipSession
    WHERE Alumni_ID = NEW.Alumni_ID;

    -- Update mentor status in Provides table
    IF avg_rating >= 4.5 AND total_sessions >= 5 THEN
        UPDATE Provides
        SET Status = 'Premium_Mentor'
        WHERE Alumni_ID = NEW.Alumni_ID AND Student_ID = NEW.Student_ID;
    END IF;
END$$

DELIMITER ;

-- =====================================================
-- 3. ALUMNI RELATED TRIGGERS
-- =====================================================

DELIMITER $$

-- Trigger: Validate alumni data before insert
CREATE TRIGGER tr_alumni_before_insert
BEFORE INSERT ON Alumni
FOR EACH ROW
BEGIN
    DECLARE email_count INT;

    -- Check email uniqueness
    SELECT COUNT(*) INTO email_count
    FROM Alumni
    WHERE Email = NEW.Email;

    IF email_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email already registered for another alumni';
    END IF;

    -- Validate graduation year (should not be in future)
    IF NEW.Graduation_Year > YEAR(CURDATE()) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Graduation year cannot be in the future';
    END IF;

    -- Calculate years of experience if not provided
    IF NEW.Years_of_Experience IS NULL THEN
        SET NEW.Years_of_Experience = YEAR(CURDATE()) - NEW.Graduation_Year;
    END IF;
END$$

DELIMITER ;

-- =====================================================
-- 4. MENTORSHIP SESSION RELATED TRIGGERS
-- =====================================================

DELIMITER $$

-- Trigger: Validate mentorship session before insert (Updated to match actual database structure)
CREATE TRIGGER tr_mentorship_session_before_insert
BEFORE INSERT ON MentorshipSession
FOR EACH ROW
BEGIN
    DECLARE alumni_exists INT;
    DECLARE student_exists INT;

    -- Check if alumni and student exist
    SELECT COUNT(*) INTO alumni_exists FROM Alumni WHERE Alumni_ID = NEW.Alumni_ID;
    SELECT COUNT(*) INTO student_exists FROM Student WHERE Student_ID = NEW.Student_ID;

    IF alumni_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Alumni does not exist';
    END IF;

    IF student_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student does not exist';
    END IF;

    -- Validate duration is positive
    IF NEW.Duration_Minutes IS NOT NULL AND NEW.Duration_Minutes <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Duration must be positive';
    END IF;
END$$

-- Trigger: Create mentorship relationship after first session
CREATE TRIGGER tr_mentorship_session_after_insert
AFTER INSERT ON MentorshipSession
FOR EACH ROW
BEGIN
    -- Create or update the Provides relationship
    INSERT IGNORE INTO Provides (Alumni_ID, Student_ID, Status)
    VALUES (NEW.Alumni_ID, NEW.Student_ID, 'Active');
END$$

DELIMITER ;

-- =====================================================
-- 5. INDUSTRY RELATED TRIGGERS
-- =====================================================

DELIMITER $$

-- Trigger: Validate industry data before insert
CREATE TRIGGER tr_industry_before_insert
BEFORE INSERT ON Industry
FOR EACH ROW
BEGIN
    -- Ensure alumni exists
    IF NOT EXISTS (SELECT 1 FROM Alumni WHERE Alumni_ID = NEW.Alumni_ID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Alumni does not exist';
    END IF;
END$$

DELIMITER ;

-- =====================================================
-- 6. ACHIEVEMENT RELATED TRIGGERS
-- =====================================================

DELIMITER $$

-- Trigger: Validate achievement data
CREATE TRIGGER tr_achievement_before_insert
BEFORE INSERT ON Achievement
FOR EACH ROW
BEGIN
    -- Validate year is reasonable
    IF NEW.Year < 1950 OR NEW.Year > YEAR(CURDATE()) + 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Achievement year is invalid';
    END IF;

    -- Ensure alumni exists
    IF NOT EXISTS (SELECT 1 FROM Alumni WHERE Alumni_ID = NEW.Alumni_ID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Alumni does not exist';
    END IF;
END$$

DELIMITER ;

-- =====================================================
-- 7. SKILL RELATED TRIGGERS
-- =====================================================

DELIMITER $$

-- Trigger: Validate skill data
CREATE TRIGGER tr_skill_before_insert
BEFORE INSERT ON Skill
FOR EACH ROW
BEGIN
    -- Ensure skill name is unique
    IF EXISTS (SELECT 1 FROM Skill WHERE Skill_Name = NEW.Skill_Name) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Skill already exists';
    END IF;

    -- Set default category if not provided
    IF NEW.Category IS NULL THEN
        SET NEW.Category = 'General';
    END IF;
END$$

DELIMITER ;

-- =====================================================
-- SHOW CREATED TRIGGERS
-- =====================================================

SHOW TRIGGERS;