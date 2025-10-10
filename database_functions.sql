-- Function to calculate average rating for an alumni
DELIMITER //
CREATE FUNCTION GetAlumniAverageRating(alumni_id VARCHAR(10))
RETURNS DECIMAL(3,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE avg_rating DECIMAL(3,2);

    SELECT COALESCE(AVG(Rating), 0) INTO avg_rating
    FROM Feedback
    WHERE Alumni_ID = alumni_id;

    RETURN avg_rating;
END //
DELIMITER ;

-- Function to count total sessions for an alumni
DELIMITER //
CREATE FUNCTION GetAlumniSessionCount(alumni_id VARCHAR(10))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE session_count INT;

    SELECT COUNT(*) INTO session_count
    FROM MentorshipSession
    WHERE Alumni_ID = alumni_id;

    RETURN session_count;
END //
DELIMITER ;