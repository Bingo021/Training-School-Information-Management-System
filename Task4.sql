#（1）显示男同学的计算机导论课程的平均成绩。
SELECT AVG(Score) AS '平均成绩'
FROM examscore es
JOIN Course c ON es.CourseID = c.CourseID
JOIN Student s ON es.StuID = s.StuID
WHERE s.Sex = '男' AND c.CourseName = '计算机导论';
#（2）将男同学和男教师的姓名、出身日期、身份证号合并显示出来。
SELECT s.StuName AS '同学姓名', s.SBirth AS '同学生日', s.SID AS '同学身份证',
       e.EmpName AS '老师姓名', e.EBirth AS '老师生日', e.EID AS '老师身份证'
FROM Student s, Employee e
WHERE s.Sex = '男' AND e.ESex = '男';
#（3）创建视图显示女同学的姓名，出身日期，身份证号。
CREATE VIEW FemaleStudents AS
SELECT StuName, SBirth, SID
FROM Student
WHERE Sex = '女';
#（4）按性别分组统计每个组的学生人数。
SELECT Sex, COUNT(*) AS '小组人数'
FROM Student
GROUP BY Sex;
#（5）按性别分组统计女同学的平均年龄，将平均年龄大于20岁的组显示出来。
SELECT Sex, AVG(YEAR(CURDATE())-YEAR(SBirth)) AS '平均年龄'
FROM Student
WHERE Sex = '女'
GROUP BY Sex
HAVING AVG(YEAR(CURDATE())-YEAR(SBirth)) > 20;
#（6）显示S160002号学生选修的所有课程的课程名，成绩及任课教师姓名。
SELECT c.CourseName AS '课程名', es.Score AS '成绩', E.EmpName AS '教师姓名'
FROM Student s
JOIN ExamScore es ON s.StuID = es.StuID
JOIN Course c ON es.CourseID = c.CourseID
JOIN Class cl ON c.ClassID = cl.ClassID
JOIN Employee e ON cl.EmpID = e.EmpID
WHERE s.StuID = 'S160002';
#（7）显示所有成绩都在90分以上的学生的学号，姓名。
SELECT s.StuID, s.StuName
FROM Student s
JOIN ExamScore es ON s.StuID = es.StuID
GROUP BY s.StuID, s.StuName
HAVING MIN(es.score) >= 90;