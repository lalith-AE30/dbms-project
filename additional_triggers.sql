-- =====================================================
-- Additional Triggers for Enhanced Functionality
-- =====================================================

USE mentor_alumni_portal;

DELIMITER $$

-- =====================================================
-- 1. MENTORSHIP REQUEST WORKFLOW TRIGGERS
-- =====================================================

-- Trigger: Auto-accept requests when session is created
CREATE TRIGGER tr_mentorship_session_auto_accept_request
AFTER INSERT ON MentorshipSession
FOR EACH ROW
BEGIN
    -- Update any pending request to accepted
    UPDATE Mentorship_Request
    SET Status = 'Accepted', Response_Date = CURDATE(), Response_Message = 'Auto-accepted: Session scheduled'
    WHERE Alumni_ID = NEW.Alumni_ID
    AND Student_ID = NEW.Student_ID
    AND Status = 'Pending';
END$$

-- Trigger: Validate mentorship request before insert
CREATE TRIGGER tr_mentorship_request_before_insert
BEFORE INSERT ON Mentorship_Request
FOR EACH ROW
BEGIN
    DECLARE v_pending_requests INT;
    DECLARE v_active_relationship INT;

    -- Check if student already has 3 pending requests
    SELECT COUNT(*) INTO v_pending_requests
    FROM Mentorship_Request
    WHERE Student_ID = NEW.Student_ID AND Status = 'Pending';

    IF v_pending_requests >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student cannot have more than 3 pending mentorship requests';
    END IF;

    -- Check if active relationship already exists
    SELECT COUNT(*) INTO v_active_relationship
    FROM Provides
    WHERE Alumni_ID = NEW.Alumni_ID
    AND Student_ID = NEW.Student_ID
    AND Status = 'Active';

    IF v_active_relationship > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Active mentorship relationship already exists';
    END IF;
END$$

-- =====================================================
-- 2. ACHIEVEMENT AND DISTINGUISHED STATUS TRIGGERS
-- =====================================================

-- Trigger: Auto-award distinguished status after achievement
CREATE TRIGGER tr_achievement_after_insert
AFTER INSERT ON Achievement
FOR EACH ROW
BEGIN
    DECLARE v_achievement_count INT;
    DECLARE v_mentee_count INT;
    DECLARE v_avg_rating DECIMAL(3,2);
    DECLARE v_distinguished_exists INT;

    -- Count achievements for this alumni
    SELECT COUNT(*) INTO v_achievement_count
    FROM Achievement
    WHERE Alumni_ID = NEW.Alumni_ID;

    -- Count unique mentees
    SELECT COUNT(DISTINCT Student_ID) INTO v_mentee_count
    FROM MentorshipSession
    WHERE Alumni_ID = NEW.Alumni_ID;

    -- Get average rating
    SELECT COALESCE(AVG(Rating), 0) INTO v_avg_rating
    FROM Feedback
    WHERE Alumni_ID = NEW.Alumni_ID;

    -- Check if already has distinguished status
    SELECT COUNT(*) INTO v_distinguished_exists
    FROM Achievement
    WHERE Alumni_ID = NEW.Alumni_ID AND Achievement_Name = 'Distinguished Mentor';

    -- Award distinguished status if criteria met
    IF v_achievement_count >= 5 AND v_distinguished_exists = 0 THEN
        INSERT INTO Achievement (Alumni_ID, Achievement_Name, Description, Year)
        VALUES (NEW.Alumni_ID, 'Distinguished Mentor',
                CONCAT('Recognized for ', v_achievement_count, ' achievements'),
                YEAR(CURDATE()));
    ELSIF v_mentee_count >= 10 AND v_avg_rating >= 4.5 AND v_distinguished_exists = 0 THEN
        INSERT INTO Achievement (Alumni_ID, Achievement_Name, Achievement_Type, Description, Year)
        VALUES (NEW.Alumni_ID, 'Excellence in Mentorship', 'Mentorship',
                CONCAT('Mentored ', v_mentee_count, ' students with ', v_avg_rating, ' average rating'),
                YEAR(CURDATE()));
    END IF;
END$$

-- Trigger: Update alumni status based on achievements
CREATE TRIGGER tr_alumni_update_distinguished_status
AFTER INSERT ON Achievement
FOR EACH ROW
BEGIN
    -- If this is a distinguished award, update alumni table if status column exists
    -- This assumes we might add a Status column to Alumni table in future
    IF NEW.Achievement_Name IN ('Distinguished Mentor', 'Excellence in Mentorship') THEN
        -- Placeholder for future status update
        -- UPDATE Alumni SET Status = 'Distinguished' WHERE Alumni_ID = NEW.Alumni_ID;
        -- Notification would be handled by application layer
        DO 0; -- No operation - placeholder
    END IF;
END$$

-- =====================================================
-- 3. SKILL MATCHING NOTIFICATION TRIGGERS
-- =====================================================

-- Trigger: Notify when student adds new skill interest
CREATE TRIGGER tr_student_skills_after_insert
AFTER INSERT ON Student_Skills
FOR EACH ROW
BEGIN
    DECLARE v_matching_alumni INT;

    -- Count alumni who have this skill
    SELECT COUNT(*) INTO v_matching_alumni
    FROM Alumni_Skills
    WHERE Skill_ID = NEW.Skill_ID;

    -- Log potential matches (could be extended to notification system)
    IF v_matching_alumni > 0 THEN
        INSERT INTO Skill_Match_Log (Student_ID, Skill_ID, Matching_Alumni_Count, Match_Date)
        VALUES (NEW.Student_ID, NEW.Skill_ID, v_matching_alumni, CURDATE())
        ON DUPLICATE KEY UPDATE Matching_Alumni_Count = v_matching_alumni, Match_Date = CURDATE();
    END IF;
END$$

-- =====================================================
-- 4. SESSION VALIDATION AND LIMITS TRIGGERS
-- =====================================================

-- Trigger: Prevent session scheduling in the past
CREATE TRIGGER tr_mentorship_session_before_insert_date
BEFORE INSERT ON MentorshipSession
FOR EACH ROW
BEGIN
    -- Prevent scheduling sessions in the past
    IF NEW.Date < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot schedule sessions in the past';
    END IF;

    -- Prevent scheduling too far in future (max 3 months)
    IF NEW.Date > DATE_ADD(CURDATE(), INTERVAL 3 MONTH) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot schedule sessions more than 3 months in advance';
    END IF;
END$$

-- Trigger: Limit daily sessions per mentor
CREATE TRIGGER tr_mentorship_session_daily_limit
BEFORE INSERT ON MentorshipSession
FOR EACH ROW
BEGIN
    DECLARE v_today_sessions INT;

    -- Count sessions already scheduled for this alumni on the same date
    SELECT COUNT(*) INTO v_today_sessions
    FROM MentorshipSession
    WHERE Alumni_ID = NEW.Alumni_ID AND Date = NEW.Date;

    -- Limit to 3 sessions per day per alumni
    IF v_today_sessions >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Alumni cannot have more than 3 sessions per day';
    END IF;
END$$

-- =====================================================
-- 5. FEEDBACK ENHANCEMENT TRIGGERS
-- =====================================================

-- Trigger: Update mentor statistics after feedback
CREATE TRIGGER tr_feedback_update_mentor_stats
AFTER INSERT ON Feedback
FOR EACH ROW
BEGIN
    DECLARE v_total_feedback INT;
    DECLARE v_avg_rating DECIMAL(3,2);
    DECLARE v_total_sessions INT;

    -- Calculate new statistics
    SELECT COUNT(*), AVG(Rating) INTO v_total_feedback, v_avg_rating
    FROM Feedback
    WHERE Alumni_ID = NEW.Alumni_ID;

    SELECT COUNT(*) INTO v_total_sessions
    FROM MentorshipSession
    WHERE Alumni_ID = NEW.Alumni_ID;

    -- Update relationship status based on performance
    IF v_avg_rating >= 4.5 AND v_total_sessions >= 5 THEN
        UPDATE Provides
        SET Status = 'Premium_Mentor'
        WHERE Alumni_ID = NEW.Alumni_ID AND Student_ID = NEW.Student_ID;
    ELSIF v_avg_rating < 2.5 AND v_total_feedback >= 3 THEN
        UPDATE Provides
        SET Status = 'Needs_Improvement'
        WHERE Alumni_ID = NEW.Alumni_ID AND Student_ID = NEW.Student_ID;
    END IF;
END$$

-- =====================================================
-- 6. DATA CONSISTENCY TRIGGERS
-- =====================================================

-- Trigger: Cascade update when student graduates
CREATE TRIGGER tr_student_update_graduation
AFTER UPDATE ON Student
FOR EACH ROW
BEGIN
    -- If student is graduating (Year_of_Study becomes 5 or NULL)
    IF NEW.Year_of_Study = 5 OR (OLD.Year_of_Study <= 4 AND NEW.Year_of_Study IS NULL) THEN
        -- Deactivate ongoing mentorship relationships
        UPDATE Provides
        SET Status = 'Graduated'
        WHERE Student_ID = NEW.Student_ID AND Status = 'Active';

        -- Cancel pending mentorship requests
        UPDATE Mentorship_Request
        SET Status = 'Cancelled', Response_Date = CURDATE(),
            Response_Message = 'Student has graduated'
        WHERE Student_ID = NEW.Student_ID AND Status = 'Pending';
    END IF;
END$$

-- Trigger: Log significant activities
CREATE TRIGGER tr_log_activity
AFTER INSERT ON MentorshipSession
FOR EACH ROW
BEGIN
    INSERT INTO Activity_Log (Activity_Type, Alumni_ID, Student_ID, Activity_Date, Details)
    VALUES ('Session Scheduled', NEW.Alumni_ID, NEW.Student_ID, NEW.Date,
            CONCAT('Mode: ', NEW.Mode, ', Duration: ', NEW.Duration));
END$$

DELIMITER ;

-- =====================================================
-- CREATE SUPPORTING TABLES FOR NEW TRIGGERS
-- =====================================================

-- Create Skill_Match_Log table
CREATE TABLE IF NOT EXISTS Skill_Match_Log (
    Log_ID INT AUTO_INCREMENT PRIMARY KEY,
    Student_ID VARCHAR(20),
    Skill_ID VARCHAR(20),
    Matching_Alumni_Count INT,
    Match_Date DATE,
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    FOREIGN KEY (Skill_ID) REFERENCES Skill(Skill_ID) ON DELETE CASCADE
);

-- Create Activity_Log table
CREATE TABLE IF NOT EXISTS Activity_Log (
    Log_ID INT AUTO_INCREMENT PRIMARY KEY,
    Activity_Type VARCHAR(50),
    Alumni_ID VARCHAR(20),
    Student_ID VARCHAR(20),
    Activity_Date DATE,
    Details TEXT,
    Logged_At TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Alumni_ID) REFERENCES Alumni(Alumni_ID) ON DELETE SET NULL,
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE SET NULL
);

-- Create indexes for performance
CREATE INDEX idx_mentorship_request_student ON Mentorship_Request(Student_ID, Status);
CREATE INDEX idx_feedback_alumni_rating ON Feedback(Alumni_ID, Rating);
CREATE INDEX idx_mentorship_session_date ON MentorshipSession(Date, Alumni_ID);
CREATE INDEX idx_alumni_achievements ON Achievement(Alumni_ID, Achievement_Type);

-- Show all triggers
SHOW TRIGGERS;