-- Test the alumni functions
USE mentor_alumni_portal;

-- Test GetAlumniAverageRating function
SELECT
    Alumni_ID,
    Name,
    GetAlumniAverageRating(Alumni_ID) AS Average_Rating
FROM Alumni
LIMIT 3;

-- Test GetAlumniSessionCount function
SELECT
    Alumni_ID,
    Name,
    GetAlumniSessionCount(Alumni_ID) AS Total_Sessions
FROM Alumni
LIMIT 3;

-- Test both functions together
SELECT
    a.Alumni_ID,
    a.Name,
    GetAlumniSessionCount(a.Alumni_ID) AS Sessions,
    GetAlumniAverageRating(a.Alumni_ID) AS Avg_Rating
FROM Alumni a
WHERE a.Alumni_ID = 'PESALU001';