-- Test Stored Procedures
USE mentor_alumni_portal;

-- Test 1: Register Student
CALL RegisterStudent('STU999', 'Test Student', 9999999999, 'test@pes.edu', 'CSE', 3);

-- Test 2: Schedule Session
CALL ScheduleSession('PESALU001', 'STU999', '2025-12-20', 'Online', '1 hour');

-- Test 3: Submit Feedback
-- CALL SubmitFeedback('PESALU001', 'STU999', '2025-12-20', 'Test feedback', 5);

-- Test 4: Get Alumni by Industry
CALL GetAlumniByIndustry('Software');

-- Test 5: Get Student Sessions
CALL GetStudentSessions('STU999');

-- Test 6: Get Mentor Stats
CALL GetMentorStats('PESALU001');

-- Test 7: Get Alumni by Skill
CALL GetAlumniBySkill('Python');

-- Test 8: Create Mentorship Request
CALL CreateMentorshipRequest('PESALU002', 'STU999', 'Test request message');

SELECT 'All procedure tests completed' AS Status;