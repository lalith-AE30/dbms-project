-- =====================================================
-- Alumni Mentor Portal - Stored Procedures and Functions
-- =====================================================

USE mentor_alumni_portal;

DELIMITER $$

-- =====================================================
-- 1. MENTORSHIP REQUEST WORKFLOW PROCEDURES
-- =====================================================

-- Procedure to create mentorship request
CREATE PROCEDURE sp_create_mentorship_request(
    IN p_alumni_id VARCHAR(20),
    IN p_student_id VARCHAR(20),
    IN p_message TEXT
)
BEGIN
    DECLARE v_alumni_exists INT;
    DECLARE v_student_exists INT;
    DECLARE v_active_relationship INT;

    -- Check if alumni exists
    SELECT COUNT(*) INTO v_alumni_exists FROM Alumni WHERE Alumni_ID = p_alumni_id;
    IF v_alumni_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Alumni does not exist';
    END IF;

    -- Check if student exists
    SELECT COUNT(*) INTO v_student_exists FROM Student WHERE Student_ID = p_student_id;
    IF v_student_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student does not exist';
    END IF;

    -- Check if active relationship already exists
    SELECT COUNT(*) INTO v_active_relationship
    FROM Provides
    WHERE Alumni_ID = p_alumni_id AND Student_ID = p_student_id AND Status = 'Active';

    IF v_active_relationship > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Active mentorship relationship already exists';
    END IF;

    -- Create the request
    INSERT INTO Mentorship_Request (Alumni_ID, Student_ID, Request_Message, Status)
    VALUES (p_alumni_id, p_student_id, p_message, 'Pending');

    SELECT 'Mentorship request created successfully' AS Result;
END$$

-- Procedure to accept mentorship request
CREATE PROCEDURE sp_accept_mentorship_request(
    IN p_request_id INT,
    IN p_response_message TEXT
)
BEGIN
    DECLARE v_alumni_id VARCHAR(20);
    DECLARE v_student_id VARCHAR(20);

    -- Get request details
    SELECT Alumni_ID, Student_ID INTO v_alumni_id, v_student_id
    FROM Mentorship_Request
    WHERE Request_ID = p_request_id AND Status = 'Pending';

    IF v_alumni_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Request not found or already processed';
    END IF;

    -- Update request status
    UPDATE Mentorship_Request
    SET Status = 'Accepted', Response_Date = CURDATE(), Response_Message = p_response_message
    WHERE Request_ID = p_request_id;

    -- Create mentorship relationship
    INSERT INTO Provides (Alumni_ID, Student_ID, Status)
    VALUES (v_alumni_id, v_student_id, 'Active')
    ON DUPLICATE KEY UPDATE Status = 'Active';

    SELECT 'Mentorship request accepted' AS Result;
END$$

-- Procedure to reject mentorship request
CREATE PROCEDURE sp_reject_mentorship_request(
    IN p_request_id INT,
    IN p_response_message TEXT
)
BEGIN
    UPDATE Mentorship_Request
    SET Status = 'Rejected', Response_Date = CURDATE(), Response_Message = p_response_message
    WHERE Request_ID = p_request_id AND Status = 'Pending';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Request not found or already processed';
    END IF;

    SELECT 'Mentorship request rejected' AS Result;
END$$

-- =====================================================
-- 2. SKILL MATCHING FUNCTIONS
-- =====================================================

-- Function to calculate skill match percentage between alumni and student
CREATE FUNCTION fn_calculate_skill_match(
    p_alumni_id VARCHAR(20),
    p_student_id VARCHAR(20)
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_matching_skills INT;
    DECLARE v_total_student_skills INT;
    DECLARE v_match_percentage DECIMAL(5,2);

    -- Count matching skills
    SELECT COUNT(*) INTO v_matching_skills
    FROM Alumni_Skills a_s
    JOIN Student_Skills s_s ON a_s.Skill_ID = s_s.Skill_ID
    WHERE a_s.Alumni_ID = p_alumni_id AND s_s.Student_ID = p_student_id;

    -- Count total skills student wants to learn
    SELECT COUNT(*) INTO v_total_student_skills
    FROM Student_Skills
    WHERE Student_ID = p_student_id;

    -- Calculate percentage
    IF v_total_student_skills = 0 THEN
        SET v_match_percentage = 0;
    ELSE
        SET v_match_percentage = (v_matching_skills * 100.0) / v_total_student_skills;
    END IF;

    RETURN v_match_percentage;
END$$

-- Procedure to find best mentor matches for a student
CREATE PROCEDURE sp_find_mentor_matches(
    IN p_student_id VARCHAR(20),
    IN p_min_match_percentage DECIMAL(5,2)
)
BEGIN
    SELECT
        a.Alumni_ID,
        a.Name,
        a.Current_Designation,
        i.Industry_Name,
        fn_calculate_skill_match(a.Alumni_ID, p_student_id) AS Match_Percentage,
        (SELECT AVG(Rating) FROM Feedback f WHERE f.Alumni_ID = a.Alumni_ID) AS Avg_Rating,
        (SELECT COUNT(*) FROM MentorshipSession ms WHERE ms.Alumni_ID = a.Alumni_ID) AS Total_Sessions
    FROM Alumni a
    LEFT JOIN Industry i ON a.Alumni_ID = i.Alumni_ID
    WHERE a.Alumni_ID NOT IN (
        SELECT Alumni_ID FROM Provides WHERE Student_ID = p_student_id AND Status = 'Active'
    )
    HAVING Match_Percentage >= p_min_match_percentage
    ORDER BY Match_Percentage DESC, Avg_Rating DESC;
END$$

-- =====================================================
-- 3. STATISTICS AND REPORTING PROCEDURES
-- =====================================================

-- Procedure to get alumni performance dashboard
CREATE PROCEDURE sp_alumni_performance_dashboard()
BEGIN
    SELECT
        a.Alumni_ID,
        a.Name,
        a.Current_Designation,
        a.Years_of_Experience,
        COUNT(DISTINCT ms.Student_ID) AS Total_Mentees,
        COUNT(ms.Session_ID) AS Total_Sessions,
        COALESCE(AVG(f.Rating), 0) AS Average_Rating,
        COUNT(DISTINCT ach.Achievement_ID) AS Total_Achievements,
        CASE
            WHEN COUNT(ms.Session_ID) >= 10 AND AVG(f.Rating) >= 4.5 THEN 'Premium Mentor'
            WHEN COUNT(ms.Session_ID) >= 5 AND AVG(f.Rating) >= 4.0 THEN 'Good Mentor'
            WHEN COUNT(ms.Session_ID) >= 1 THEN 'Active Mentor'
            ELSE 'Inactive Mentor'
        END AS Mentor_Status
    FROM Alumni a
    LEFT JOIN MentorshipSession ms ON a.Alumni_ID = ms.Alumni_ID
    LEFT JOIN Feedback f ON a.Alumni_ID = f.Alumni_ID
    LEFT JOIN Achievement ach ON a.Alumni_ID = ach.Alumni_ID
    GROUP BY a.Alumni_ID, a.Name, a.Current_Position, a.Years_of_Experience
    ORDER BY Total_Sessions DESC, Average_Rating DESC;
END$$

-- Procedure to get department-wise mentorship statistics
CREATE PROCEDURE sp_department_statistics()
BEGIN
    SELECT
        s.Department,
        COUNT(DISTINCT s.Student_ID) AS Total_Students,
        COUNT(DISTINCT ms.Alumni_ID) AS Active_Mentors,
        COUNT(ms.Session_ID) AS Total_Sessions,
        COALESCE(AVG(f.Rating), 0) AS Avg_Rating,
        COUNT(DISTINCT CASE WHEN p.Status = 'Premium_Mentor' THEN p.Alumni_ID END) AS Premium_Mentors
    FROM Student s
    LEFT JOIN MentorshipSession ms ON s.Student_ID = ms.Student_ID
    LEFT JOIN Feedback f ON ms.Alumni_ID = f.Alumni_ID AND ms.Student_ID = f.Student_ID
    LEFT JOIN Provides p ON ms.Alumni_ID = p.Alumni_ID AND s.Student_ID = p.Student_ID
    GROUP BY s.Department
    ORDER BY Total_Sessions DESC;
END$$

-- =====================================================
-- 4. SKILL MANAGEMENT PROCEDURES
-- =====================================================

-- Procedure to add skill to alumni with proficiency level
CREATE PROCEDURE sp_add_alumni_skill(
    IN p_alumni_id VARCHAR(20),
    IN p_skill_id VARCHAR(20),
    IN p_proficiency VARCHAR(50)
)
BEGIN
    DECLARE v_skill_exists INT;

    -- Check if skill exists
    SELECT COUNT(*) INTO v_skill_exists FROM Skill WHERE Skill_ID = p_skill_id;
    IF v_skill_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Skill does not exist';
    END IF;

    -- Add skill with proficiency
    INSERT INTO Alumni_Skills (Alumni_ID, Skill_ID, Proficiency_Level)
    VALUES (p_alumni_id, p_skill_id, p_proficiency)
    ON DUPLICATE KEY UPDATE Proficiency_Level = p_proficiency;

    SELECT 'Skill added to alumni profile' AS Result;
END$$

-- Procedure to find trending skills among students
CREATE PROCEDURE sp_trending_skills()
BEGIN
    SELECT
        s.Skill_ID,
        s.Skill_Name,
        s.Category,
        COUNT(ss.Student_ID) AS Demand_Count,
        COUNT(DISTINCT ss.Department) AS Departments_Interested
    FROM Skill s
    JOIN Student_Skills ss ON s.Skill_ID = ss.Skill_ID
    GROUP BY s.Skill_ID, s.Skill_Name, s.Category
    ORDER BY Demand_Count DESC
    LIMIT 10;
END$$

-- =====================================================
-- 5. ACHIEVEMENT AND RECOGNITION
-- =====================================================

-- Procedure to award distinguished alumni status
CREATE PROCEDURE sp_check_distinguished_status(
    IN p_alumni_id VARCHAR(20)
)
BEGIN
    DECLARE v_achievement_count INT;
    DECLARE v_mentee_count INT;
    DECLARE v_avg_rating DECIMAL(3,2);

    -- Count achievements
    SELECT COUNT(*) INTO v_achievement_count
    FROM Achievement
    WHERE Alumni_ID = p_alumni_id;

    -- Count unique mentees
    SELECT COUNT(DISTINCT Student_ID) INTO v_mentee_count
    FROM MentorshipSession
    WHERE Alumni_ID = p_alumni_id;

    -- Get average rating
    SELECT COALESCE(AVG(Rating), 0) INTO v_avg_rating
    FROM Feedback
    WHERE Alumni_ID = p_alumni_id;

    -- Check if qualifies for distinguished status
    IF v_achievement_count >= 5 OR (v_mentee_count >= 10 AND v_avg_rating >= 4.5) THEN
        -- Add distinguished achievement if not exists
        INSERT IGNORE INTO Achievement (Alumni_ID, Achievement_Name, Description, Year)
        VALUES (p_alumni_id, 'Distinguished Mentor',
                CONCAT('Recognized for excellence in mentoring ', v_mentee_count, ' students with avg rating of ', v_avg_rating),
                YEAR(CURDATE()));
        SELECT 'Distinguished status awarded' AS Result;
    ELSE
        SELECT 'Criteria not met for distinguished status' AS Result;
    END IF;
END$$

-- =====================================================
-- 6. SESSION MANAGEMENT
-- =====================================================

-- Procedure to schedule session with validation
CREATE PROCEDURE sp_schedule_session(
    IN p_alumni_id VARCHAR(20),
    IN p_student_id VARCHAR(20),
    IN p_session_date DATE,
    IN p_mode VARCHAR(20),
    IN p_duration VARCHAR(20)
)
BEGIN
    DECLARE v_active_relationship INT;
    DECLARE v_conflict_sessions INT;

    -- Check if active relationship exists
    SELECT COUNT(*) INTO v_active_relationship
    FROM Provides
    WHERE Alumni_ID = p_alumni_id AND Student_ID = p_student_id AND Status = 'Active';

    -- Check for scheduling conflicts (max 2 sessions per day)
    SELECT COUNT(*) INTO v_conflict_sessions
    FROM MentorshipSession
    WHERE (Alumni_ID = p_alumni_id OR Student_ID = p_student_id)
    AND Date = p_session_date;

    IF v_active_relationship = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No active mentorship relationship exists';
    END IF;

    IF v_conflict_sessions >= 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot schedule more than 2 sessions per day';
    END IF;

    -- Insert session
    INSERT INTO MentorshipSession (Alumni_ID, Student_ID, Date, Mode, Duration)
    VALUES (p_alumni_id, p_student_id, p_session_date, p_mode, p_duration);

    SELECT 'Session scheduled successfully' AS Result;
END$$

DELIMITER ;

-- =====================================================
-- VIEW DEFINITIONS FOR REPORTING
-- =====================================================

-- View: Mentorship Summary
CREATE OR REPLACE VIEW v_mentorship_summary AS
SELECT
    a.Alumni_ID,
    a.Name AS Alumni_Name,
    a.Current_Position,
    s.Student_ID,
    s.Name AS Student_Name,
    s.Department,
    p.Status AS Relationship_Status,
    COUNT(ms.Session_ID) AS Session_Count,
    AVG(f.Rating) AS Average_Rating,
    MAX(ms.Session_Date) AS_Last_Session_Date
FROM Alumni a
JOIN Provides p ON a.Alumni_ID = p.Alumni_ID
JOIN Student s ON p.Student_ID = s.Student_ID
LEFT JOIN MentorshipSession ms ON a.Alumni_ID = ms.Alumni_ID AND s.Student_ID = ms.Student_ID
LEFT JOIN Feedback f ON a.Alumni_ID = f.Alumni_ID AND s.Student_ID = f.Student_ID
GROUP BY a.Alumni_ID, a.Name, a.Current_Position, s.Student_ID, s.Name, s.Department, p.Status;

-- View: Top Performing Mentors
CREATE OR REPLACE VIEW v_top_mentors AS
SELECT
    a.Alumni_ID,
    a.Name,
    a.Current_Position,
    i.Industry_Name,
    COUNT(DISTINCT ms.Student_ID) AS Total_Mentees,
    COUNT(ms.Session_ID) AS Total_Sessions,
    COALESCE(AVG(f.Rating), 0) AS Average_Rating,
    COUNT(DISTINCT ach.Achievement_ID) AS Achievements
FROM Alumni a
LEFT JOIN MentorshipSession ms ON a.Alumni_ID = ms.Alumni_ID
LEFT JOIN Feedback f ON a.Alumni_ID = f.Alumni_ID
LEFT JOIN Industry i ON a.Alumni_ID = i.Alumni_ID
LEFT JOIN Achievement ach ON a.Alumni_ID = ach.Alumni_ID
GROUP BY a.Alumni_ID, a.Name, a.Current_Position, i.Industry_Name
HAVING Total_Sessions >= 3
ORDER BY Average_Rating DESC, Total_Sessions DESC;

-- View: Skill Gap Analysis
CREATE OR REPLACE VIEW v_skill_gap_analysis AS
SELECT
    s.Skill_Name,
    s.Category,
    COUNT(DISTINCT ss.Student_ID) AS Students_Interested,
    COUNT(DISTINCT als.Alumni_ID) AS Alumni_Available,
    CASE
        WHEN COUNT(DISTINCT ss.Student_ID) > COUNT(DISTINCT als.Alumni_ID) THEN 'Shortage'
        WHEN COUNT(DISTINCT ss.Student_ID) = COUNT(DISTINCT als.Alumni_ID) THEN 'Balanced'
        ELSE 'Surplus'
    END AS Skill_Availability
FROM Skill s
LEFT JOIN Student_Skills ss ON s.Skill_ID = ss.Skill_ID
LEFT JOIN Alumni_Skills als ON s.Skill_ID = als.Skill_ID
GROUP BY s.Skill_ID, s.Skill_Name, s.Category
ORDER BY Students_Interested DESC;