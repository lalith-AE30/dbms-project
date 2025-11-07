-- =====================================================
-- Alumni Mentor Portal - Stored Procedures for Common Actions
-- =====================================================

USE mentor_alumni_portal;

DELIMITER $$

-- Procedure 1: Register New Student
-- Handles student registration with proper validation
CREATE PROCEDURE RegisterStudent(
    IN p_Student_ID VARCHAR(20),
    IN p_Name VARCHAR(100),
    IN p_Phone BIGINT,
    IN p_Email VARCHAR(100),
    IN p_Dept VARCHAR(50),
    IN p_Year INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Insert student (triggers will handle validation)
    INSERT INTO Student VALUES (p_Student_ID, p_Name, p_Phone, p_Email, p_Dept, p_Year);

    COMMIT;
    SELECT 'Student registered successfully' AS Message;
END$$

-- Procedure 2: Schedule Mentorship Session (Updated to match actual database structure)
-- Creates a new mentorship session and handles relationships
CREATE PROCEDURE ScheduleSession(
    IN p_Session_ID VARCHAR(20),
    IN p_Alumni_ID VARCHAR(20),
    IN p_Student_ID VARCHAR(20),
    IN p_Session_Date DATE,
    IN p_Duration_Minutes INT,
    IN p_Topic VARCHAR(200)
)
BEGIN
    DECLARE v_alumni_exists INT;
    DECLARE v_student_exists INT;

    -- Check if alumni exists
    SELECT COUNT(*) INTO v_alumni_exists FROM Alumni WHERE Alumni_ID = p_Alumni_ID;
    IF v_alumni_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Alumni not found';
    END IF;

    -- Check if student exists
    SELECT COUNT(*) INTO v_student_exists FROM Student WHERE Student_ID = p_Student_ID;
    IF v_student_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student not found';
    END IF;

    -- Insert session with unique ID (trigger auto-creates relationship)
    INSERT INTO MentorshipSession VALUES (p_Session_ID, p_Alumni_ID, p_Student_ID, p_Session_Date, p_Duration_Minutes, p_Topic);

    SELECT 'Session scheduled successfully' AS Message;
END$$

-- Procedure 3: Submit Feedback (Updated to match actual database structure)
-- Submits feedback for a mentorship session
CREATE PROCEDURE SubmitFeedback(
    IN p_Feedback_ID VARCHAR(20),
    IN p_Alumni_ID VARCHAR(20),
    IN p_Student_ID VARCHAR(20),
    IN p_Rating INT,
    IN p_Date DATE,
    IN p_Comments TEXT
)
BEGIN
    DECLARE v_session_exists INT;

    -- Check if session exists
    SELECT COUNT(*) INTO v_session_exists
    FROM MentorshipSession
    WHERE Alumni_ID = p_Alumni_ID AND Student_ID = p_Student_ID AND Session_Date = p_Date;

    IF v_session_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Session not found';
    END IF;

    -- Insert feedback with unique ID (triggers handle validation and logging)
    INSERT INTO Feedback VALUES (p_Feedback_ID, p_Alumni_ID, p_Student_ID, p_Rating, p_Date, p_Comments);

    SELECT 'Feedback submitted successfully' AS Message;
END$$

-- Procedure 4: Get Alumni by Industry
-- Retrieves alumni filtered by industry/sector
CREATE PROCEDURE GetAlumniByIndustry(
    IN p_Sector VARCHAR(100)
)
BEGIN
    SELECT DISTINCT
        a.Alumni_ID,
        a.Name,
        a.Email,
        a.Current_Designation,
        a.Years_of_Experience,
        i.Industry_Name,
        i.Location
    FROM Alumni a
    JOIN Industry i ON a.Alumni_ID = i.Alumni_ID
    WHERE i.Sector = p_Sector OR p_Sector IS NULL
    ORDER BY a.Years_of_Experience DESC;
END$$

-- Procedure 5: Get Student Session History
-- Retrieves all sessions for a specific student
CREATE PROCEDURE GetStudentSessions(
    IN p_Student_ID VARCHAR(20)
)
BEGIN
    SELECT
        m.Session_Date,
        m.Duration_Minutes,
        m.Topic,
        a.Name AS Alumni_Name,
        a.Current_Designation,
        i.Industry_Name,
        IFNULL(f.Rating, 0) AS Rating,
        IFNULL(f.Comments, 'No feedback yet') AS Comments
    FROM MentorshipSession m
    JOIN Alumni a ON m.Alumni_ID = a.Alumni_ID
    LEFT JOIN Feedback f ON m.Alumni_ID = f.Alumni_ID
                        AND m.Student_ID = f.Student_ID
                        AND m.Session_Date = f.Date
    LEFT JOIN Industry i ON a.Alumni_ID = i.Alumni_ID
    WHERE m.Student_ID = p_Student_ID
    ORDER BY m.Session_Date DESC;
END$$

-- Procedure 6: Get Mentor Statistics
-- Retrieves comprehensive statistics for an alumni mentor
CREATE PROCEDURE GetMentorStats(
    IN p_Alumni_ID VARCHAR(20)
)
BEGIN
    SELECT
        a.Alumni_ID,
        a.Name,
        a.Current_Designation,
        a.Years_of_Experience,
        COUNT(DISTINCT m.Student_ID) AS Total_Mentees,
        COUNT(m.Alumni_ID) AS Total_Sessions,
        IFNULL(AVG(f.Rating), 0) AS Average_Rating,
        COUNT(f.Rating) AS Feedback_Count,
        CASE
            WHEN AVG(f.Rating) >= 4.5 THEN 'Excellent'
            WHEN AVG(f.Rating) >= 4.0 THEN 'Very Good'
            WHEN AVG(f.Rating) >= 3.5 THEN 'Good'
            WHEN AVG(f.Rating) > 0 THEN 'Average'
            ELSE 'No Feedback'
        END AS Performance_Rating
    FROM Alumni a
    LEFT JOIN MentorshipSession m ON a.Alumni_ID = m.Alumni_ID
    LEFT JOIN Feedback f ON a.Alumni_ID = f.Alumni_ID
    WHERE a.Alumni_ID = p_Alumni_ID
    GROUP BY a.Alumni_ID, a.Name, a.Current_Designation, a.Years_of_Experience;
END$$

-- Procedure 7: Find Alumni by Skill
-- Retrieves alumni who have specific skills
CREATE PROCEDURE GetAlumniBySkill(
    IN p_Skill_Name VARCHAR(100)
)
BEGIN
    SELECT DISTINCT
        a.Alumni_ID,
        a.Name,
        a.Email,
        a.Current_Designation,
        a.Years_of_Experience,
        s.Skill_Name,
        as_prof.Proficiency_Level
    FROM Alumni a
    JOIN Alumni_Skills as_prof ON a.Alumni_ID = as_prof.Alumni_ID
    JOIN Skill s ON as_prof.Skill_ID = s.Skill_ID
    WHERE s.Skill_Name LIKE CONCAT('%', p_Skill_Name, '%')
    ORDER BY a.Years_of_Experience DESC;
END$$

-- Procedure 8: Create Mentorship Request
-- Creates a new mentorship request
CREATE PROCEDURE CreateMentorshipRequest(
    IN p_Alumni_ID VARCHAR(20),
    IN p_Student_ID VARCHAR(20),
    IN p_Message TEXT
)
BEGIN
    DECLARE v_request_exists INT;

    -- Check if request already exists and is pending
    SELECT COUNT(*) INTO v_request_exists
    FROM Mentorship_Request
    WHERE Alumni_ID = p_Alumni_ID
      AND Student_ID = p_Student_ID
      AND Status = 'Pending';

    IF v_request_exists > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mentorship request already pending';
    END IF;

    -- Create new request
    INSERT INTO Mentorship_Request (Alumni_ID, Student_ID, Request_Message)
    VALUES (p_Alumni_ID, p_Student_ID, p_Message);

    SELECT 'Mentorship request created successfully' AS Message;
END$$

-- Procedure 9: Delete Old Sessions
-- Deletes all mentorship sessions older than one week
CREATE PROCEDURE DeleteOldSessions()
BEGIN
    DECLARE v_deleted_count INT;

    -- Delete sessions that are older than 7 days
    DELETE FROM MentorshipSession
    WHERE Session_Date < DATE_SUB(CURDATE(), INTERVAL 7 DAY);

    -- Get count of deleted rows
    SELECT ROW_COUNT() INTO v_deleted_count;

    SELECT CONCAT(v_deleted_count, ' sessions older than 7 days have been deleted.') AS Message;
END$$

DELIMITER ;

-- Example Usage:
/*
-- Register a new student
CALL RegisterStudent('STU008', 'Jane Smith', 9876543211, 'jane@pes.edu', 'ECE', 2);

-- Schedule a session
CALL ScheduleSession('PESALU001', 'STU008', '2025-12-15', 'Online', '1 hour');

-- Submit feedback
CALL SubmitFeedback('PESALU001', 'STU008', '2025-12-15', 'Very helpful session!', 5);

-- Get alumni by industry
CALL GetAlumniByIndustry('Software');

-- Get student session history
CALL GetStudentSessions('STU001');

-- Get mentor statistics
CALL GetMentorStats('PESALU001');

-- Find alumni by skill
CALL GetAlumniBySkill('Python');

-- Create mentorship request
CALL CreateMentorshipRequest('PESALU002', 'STU008', 'Interested in learning about product management');
*/