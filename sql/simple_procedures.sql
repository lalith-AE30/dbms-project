-- =====================================================
-- Simple Stored Procedures for Alumni Mentor Portal
-- =====================================================

USE mentor_alumni_portal;

DELIMITER $$

-- Procedure to get alumni statistics
CREATE PROCEDURE sp_get_alumni_statistics(IN p_alumni_id VARCHAR(20))
BEGIN
    SELECT
        a.Name,
        a.Current_Position,
        a.Years_of_Experience,
        COUNT(DISTINCT ms.Student_ID) AS Total_Mentees,
        COUNT(ms.Session_ID) AS Total_Sessions,
        COALESCE(AVG(f.Rating), 0) AS Average_Rating
    FROM Alumni a
    LEFT JOIN MentorshipSession ms ON a.Alumni_ID = ms.Alumni_ID
    LEFT JOIN Feedback f ON a.Alumni_ID = f.Alumni_ID
    WHERE a.Alumni_ID = p_alumni_id
    GROUP BY a.Alumni_ID, a.Name, a.Current_Position, a.Years_of_Experience;
END$$

-- Procedure to get student session history
CREATE PROCEDURE sp_get_student_sessions(IN p_student_id VARCHAR(20))
BEGIN
    SELECT
        s.Name AS Student_Name,
        a.Name AS Alumni_Name,
        a.Current_Position,
        ms.Date,
        ms.Mode,
        ms.Duration,
        f.Rating,
        f.Comments
    FROM Student s
    JOIN MentorshipSession ms ON s.Student_ID = ms.Student_ID
    JOIN Alumni a ON ms.Alumni_ID = a.Alumni_ID
    LEFT JOIN Feedback f ON ms.Alumni_ID = f.Alumni_ID
        AND ms.Student_ID = f.Student_ID
        AND ms.Date = f.Date
    WHERE s.Student_ID = p_student_id
    ORDER BY ms.Date DESC;
END$$

-- Procedure to get top mentors by rating
CREATE PROCEDURE sp_get_top_mentors(IN p_limit INT)
BEGIN
    SELECT
        a.Alumni_ID,
        a.Name,
        a.Current_Position,
        COUNT(DISTINCT ms.Student_ID) AS Total_Mentees,
        COUNT(ms.Session_ID) AS Total_Sessions,
        COALESCE(AVG(f.Rating), 0) AS Average_Rating
    FROM Alumni a
    LEFT JOIN MentorshipSession ms ON a.Alumni_ID = ms.Alumni_ID
    LEFT JOIN Feedback f ON a.Alumni_ID = f.Alumni_ID
    GROUP BY a.Alumni_ID, a.Name, a.Current_Position
    HAVING Total_Sessions > 0
    ORDER BY Average_Rating DESC, Total_Sessions DESC
    LIMIT p_limit;
END$$

-- Procedure to get department statistics
CREATE PROCEDURE sp_get_department_stats()
BEGIN
    SELECT
        s.Department,
        COUNT(DISTINCT s.Student_ID) AS Total_Students,
        COUNT(DISTINCT ms.Alumni_ID) AS Active_Mentors,
        COUNT(ms.Session_ID) AS Total_Sessions,
        COALESCE(AVG(f.Rating), 0) AS Avg_Rating
    FROM Student s
    LEFT JOIN MentorshipSession ms ON s.Student_ID = ms.Student_ID
    LEFT JOIN Feedback f ON ms.Alumni_ID = f.Alumni_ID
        AND ms.Student_ID = f.Student_ID
    GROUP BY s.Department
    ORDER BY Total_Sessions DESC;
END$$

-- Function to calculate months since graduation
CREATE FUNCTION fn_months_since_graduation(p_graduation_year INT) RETURNS INT
DETERMINISTIC
BEGIN
    RETURN (YEAR(CURDATE()) - p_graduation_year) * 12 + MONTH(CURDATE());
END$$

DELIMITER ;

-- Test the procedures
CALL sp_get_alumni_statistics('PESALU001');
CALL sp_get_student_sessions('PESSTU001');
CALL sp_get_top_mentors(5);
CALL sp_get_department_stats();

SELECT fn_months_since_graduation(2020) AS Months_Since_Graduation;

SHOW PROCEDURE STATUS WHERE Db = 'mentor_alumni_portal';
SHOW FUNCTION STATUS WHERE Db = 'mentor_alumni_portal';