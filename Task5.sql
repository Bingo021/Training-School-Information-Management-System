#(1)学生查询成绩相关信息
#输入：学号、身份证号
#输出：选修总课程数、最好成绩、最差成绩、平均分、获得总学分(所有信息使用输出参数输出)。
DELIMITER //

CREATE PROCEDURE GetScoreInformation(
  IN student_id VARCHAR(10),
  IN id VARCHAR(18),
  OUT total_courses INT,
  OUT best_score INT,
  OUT worst_score INT,
  OUT average_score DECIMAL(5,2),
  OUT total_credits INT
)
BEGIN
  -- 选修总课程数
  SELECT COUNT(DISTINCT es.CourseID) INTO total_courses
  FROM ExamScore es
  JOIN Course c ON es.CourseID = c.CourseID
  WHERE es.StuID = student_id AND EXISTS (SELECT 1 FROM Student WHERE StuID = student_id AND SID = id);
  
  -- 最好成绩
  SELECT MAX(Score) INTO best_score
  FROM ExamScore
  WHERE StuID = student_id;
  
  -- 最差成绩
  SELECT MIN(Score) INTO worst_score
  FROM ExamScore
  WHERE StuID = student_id;
  
  -- 平均分
  SELECT AVG(Score) INTO average_score
  FROM ExamScore
  WHERE StuID = student_id;
  
  -- 获得总学分
  SELECT SUM(ClassHour) INTO total_credits
  FROM ExamScore es
  JOIN Course c ON es.CourseID = c.CourseID
  WHERE es.StuID = student_id AND EXISTS (SELECT 1 FROM Student WHERE StuID = student_id AND SID = id);
END //

DELIMITER ;
-- 调用
CALL GetScoreInformation('S160001', '110101199801011111', @total_courses, @best_score, @worst_score, @average_score, @total_credits);
-- 输出查询结果
SELECT @total_courses AS '选修总课程数', @best_score AS '最好成绩', @worst_score AS '最差成绩', @average_score AS '平均分', @total_credits AS '获得总学分';
#(2)学生查询某门课程成绩
#输入：学号、身份证号、教学班号
#输出：成绩
DELIMITER //

CREATE PROCEDURE GetCourseScore(
  IN student_id VARCHAR(10),
  IN id_card VARCHAR(18),
  IN class_id VARCHAR(15),
  OUT score INT
)
BEGIN
  SELECT es.Score INTO score
  FROM ExamScore es
  JOIN Student s ON es.StuID = s.StuID
  JOIN Course c ON es.CourseID = c.CourseID
  WHERE es.StuID = student_id AND c.ClassID = class_id;
END //

DELIMITER ;

-- 调用
SET @score = 0;
CALL GetCourseScore('S160001', '110101199801011111', 'TC-2016-001', @score);
-- 输出查询结果
SELECT '该门课程成绩为：', @score;
#(3)工资信息查询
#写存储过程查询教职工工资
#输入：员工号、发放年月
#输出：应发工资是否正确，如正确，Return 1，不正确，Return 状态0，并输出正确的应发工资。
DELIMITER //

CREATE PROCEDURE CalculateSalary(
  IN employee_id VARCHAR(10),
  IN payment_month DATE,
  OUT is_correct BIT,
  OUT salary DECIMAL(8,2)
)
BEGIN
  DECLARE basic_salary DECIMAL(8,2);
  DECLARE hourly_wage DECIMAL(8,2);
  DECLARE course_count INT;
  DECLARE tax DECIMAL(5,2);
  DECLARE employee_category VARCHAR(4);
  DECLARE employee_title VARCHAR(8);
  
  -- 获取员工信息
  SELECT Category, Title INTO employee_category, employee_title
  FROM employee
  WHERE EmpID = employee_id;
  
  -- 判断学期
  SET @semester = CONCAT(YEAR(payment_month), IF(MONTH(payment_month) <= 6, '-01', '-02'));

  -- 获取基本工资和每课时工资
  CASE employee_category
    WHEN '教师' THEN
      CASE employee_title
        WHEN '讲师' THEN SET basic_salary = 1000, hourly_wage = 80;
        WHEN '副教授' THEN SET basic_salary = 1500, hourly_wage = 90;
        WHEN '教授' THEN SET basic_salary = 2000, hourly_wage = 100;
        ELSE SET basic_salary = 0, hourly_wage = 0;
      END CASE;
    ELSE SET basic_salary = 3000, hourly_wage = 0;
  END CASE;

  -- 获取课时数
  SET course_count = (
    SELECT SUM(cr.ClassHour)
    FROM class AS c
    INNER JOIN course AS cr ON c.ClassID = cr.ClassID
    WHERE c.EmpID = employee_id AND c.Semester = @semester
  );

  -- 计算工资
  SET salary = basic_salary + (hourly_wage * course_count);

  -- 计算税金
  SET tax = CASE
    WHEN salary >= 5000 THEN (salary - 5000) * 0.1 + 150
    WHEN salary >= 3500 THEN (salary - 3500) * 0.03
    ELSE 0
  END;

  SET salary = salary - tax;

  -- 判断工资是否正确
  SET is_correct = (
    SELECT COUNT(*)
    FROM salary
    WHERE EmpID = employee_id AND SalaryMonth = payment_month
  );
  
  -- 输出查询结果
  IF is_correct = 1 THEN
    SELECT CONCAT('应发工资正确，应发工资为：', salary);
  ELSE
    SELECT '应发工资不正确';
  END IF;
END //

DELIMITER ;
-- 调用
SET @is_correct = 0;
SET @salary = 0;
CALL CalculateSalary('T0001', '2022-06-01', @is_correct, @salary);
-- 输出查询结果
SELECT @is_correct, @salary;

#(4)任课教师了解课程考试情况
#输入：工号、身份证号、教学班号
#输出：平均分、90分以上人数、70-90之间人数、60-70人数以及不及格人数（输出参数）
DELIMITER //

CREATE PROCEDURE GetCourseExamStats(
  IN emp_id VARCHAR(10),
  IN id_card VARCHAR(18),
  IN class_id VARCHAR(20),
  OUT average_score DECIMAL(5,2),
  OUT count_90_above INT,
  OUT count_70_90 INT,
  OUT count_60_70 INT,
  OUT count_below_60 INT
)
BEGIN
  -- 计算平均分
  SELECT AVG(es.Score) INTO average_score
  FROM examscore es
  INNER JOIN course c ON es.CourseID = c.CourseID
  INNER JOIN class cl ON c.ClassID = cl.ClassID
  INNER JOIN employee e ON cl.EmpID = e.EmpID
  WHERE e.EmpID = emp_id AND e.EID = id_card AND cl.ClassID = class_id;

  -- 统计各分数段的人数
  SELECT COUNT(*) INTO count_90_above
  FROM examscore es
  INNER JOIN course c ON es.CourseID = c.CourseID
  INNER JOIN class cl ON c.ClassID = cl.ClassID
  INNER JOIN employee e ON cl.EmpID = e.EmpID
  WHERE e.EmpID = emp_id AND e.EID = id_card AND cl.ClassID = class_id AND es.Score >= 90;

  SELECT COUNT(*) INTO count_70_90
  FROM examscore es
  INNER JOIN course c ON es.CourseID = c.CourseID
  INNER JOIN class cl ON c.ClassID = cl.ClassID
  INNER JOIN employee e ON cl.EmpID = e.EmpID
  WHERE e.EmpID = emp_id AND e.EID = id_card AND cl.ClassID = class_id AND es.Score >= 70 AND es.Score < 90;

  SELECT COUNT(*) INTO count_60_70
  FROM examscore es
  INNER JOIN course c ON es.CourseID = c.CourseID
  INNER JOIN class cl ON c.ClassID = cl.ClassID
  INNER JOIN employee e ON cl.EmpID = e.EmpID
  WHERE e.EmpID = emp_id AND e.EID = id_card AND cl.ClassID = class_id AND es.Score >= 60 AND es.Score < 70;

  SELECT COUNT(*) INTO count_below_60
  FROM examscore es
  INNER JOIN course c ON es.CourseID = c.CourseID
  INNER JOIN class cl ON c.ClassID = cl.ClassID
  INNER JOIN employee e ON cl.EmpID = e.EmpID
  WHERE e.EmpID = emp_id AND e.EID = id_card AND cl.ClassID = class_id AND es.Score < 60;
END //

DELIMITER ;
-- 调用
SET @average_score = 0;
SET @count_90_above = 0;
SET @count_70_90 = 0;
SET @count_60_70 = 0;
SET @count_below_60 = 0;
CALL GetCourseExamStats('T0001', '110101198001011111', 'TC-2016-001', @average_score, @count_90_above, @count_70_90, @count_60_70, @count_below_60);
-- 输出查询结果
SELECT '平均分：', @average_score;
SELECT '90分以上人数：', @count_90_above;
SELECT '70-90分之间人数：', @count_70_90;
SELECT '60-70分之间人数：', @count_60_70;
SELECT '不及格人数：', @count_below_60;

#(5)为新生安排宿舍，由两个存储过程完成。存储过程1显示可选宿舍，存储过程2选定宿舍，为新生安排。
#存储过程1输入：学号
#存储过程1输出：显示符合条件的房间号
#注：适合的房间号含义为性别和该学号学生相同，同时房间剩余容量大于零。
DELIMITER //

CREATE PROCEDURE GetAvailableRoomsByStudentID(
  IN student_id VARCHAR(10)
)
BEGIN
  DECLARE student_sex CHAR(2);

  -- 获取学生的性别
  SELECT Sex INTO student_sex
  FROM student
  WHERE StuID = student_id;

  -- 查询符合条件的房间号
  SELECT DormNub
  FROM dormitory
  WHERE SexLimit = student_sex
    AND ResNub < CapNub;
END //

DELIMITER ;
-- 调用
CALL GetAvailableRoomsByStudentID('S160001');
#存储过程2输入：学号、房间号
#存储过程2输出：为学生安排宿舍，同时相应宿舍剩余容量减1。
DELIMITER //

CREATE PROCEDURE AssignDormitoryToStudent(
  IN student_id VARCHAR(10),
  IN dormitory_number VARCHAR(10)
)
BEGIN
  DECLARE dormitory_capacity INT;
  DECLARE dormitory_remaining INT;
  DECLARE student_dormitory VARCHAR(10);

  -- 检查学生是否已入住其他宿舍
  SELECT DormNub INTO student_dormitory
  FROM student
  WHERE StuID = student_id;

  IF student_dormitory IS NULL THEN
    -- 检查宿舍是否存在
    SELECT CapNub, ResNub INTO dormitory_capacity, dormitory_remaining
    FROM dormitory
    WHERE DormNub = dormitory_number;

    -- 检查宿舍剩余容量
    IF dormitory_remaining > 0 THEN
      -- 更新学生表的宿舍信息
      UPDATE student
      SET DormNub = dormitory_number
      WHERE StuID = student_id;

      -- 更新宿舍表的剩余容量
      UPDATE dormitory
      SET ResNub = ResNub - 1
      WHERE DormNub = dormitory_number;

      SELECT '宿舍分配成功。' AS Message;
    ELSE
      SELECT '宿舍已满，无法分配。' AS Message;
    END IF;
  ELSE
    -- 检查学生是否已经入住输入的宿舍
    IF student_dormitory = dormitory_number THEN
      SELECT '学生已入住该宿舍，无需重新分配。' AS Message;
    ELSE
      SELECT '学生已入住其他宿舍，无法分配。' AS Message;
    END IF;
  END IF;
END //

DELIMITER ;

-- 调用
CALL AssignDormitoryToStudent('S160001', '11-101');
#(6)任课教师了解上课信息
#输入：教学班号、教师工号、课程号、学期、上课起止时间、教室
#输出：上课总人数
DELIMITER //

CREATE PROCEDURE GetClassTotalStudents(
  IN class_id VARCHAR(20),
  IN emp_id VARCHAR(10),
  IN course_id VARCHAR(10),
  IN semester VARCHAR(10),
  IN start_time VARCHAR(20),
  IN end_time VARCHAR(20),
  IN class_room VARCHAR(6),
  OUT total_students INT
)
BEGIN
  DECLARE existing_class INT;

  -- 检查教学班号是否已存在
  SELECT COUNT(*) INTO existing_class
  FROM class
  WHERE ClassID = class_id;

  IF existing_class > 0 THEN
    -- 教学班号已存在，直接返回上课总人数
    SELECT StuNub INTO total_students
    FROM class
    WHERE ClassID = class_id;
  ELSE
    -- 教学班号不存在，插入新的教学班信息
    INSERT INTO class (ClassID, EmpID, Semester, StartTime, EndTime, ClassRoom)
    VALUES (class_id, emp_id, semester, start_time, end_time, class_room);

    -- 获取上课总人数
    SELECT StuNub INTO total_students
    FROM class
    WHERE ClassID = class_id;
  END IF;
END //

DELIMITER ;
-- 调用
CALL GetClassTotalStudents('TC-2016-001', 'T0001', 'C0001', '2022-01', '周一8:00-10:00', '周三8:00-10:00', '101', @total_students);
-- 输出查询结果
SELECT '上课总人数为：', @total_students;
#(7)转教学班
#允许学生转教学班，学生选课表中允许修改教学班号，对应的教学班表中，原教学班的总人数少1，新教学班的总人数加1。(提示：事务完成)
#输入：学号、新教学班号
DELIMITER //

CREATE PROCEDURE TransferStudentClass(
    IN studentID VARCHAR(10),
    IN newClassID VARCHAR(20)
)
BEGIN
    DECLARE oldClassID VARCHAR(20);
    
    -- 获取学生当前所在教学班
    SELECT c.ClassID INTO oldClassID
    FROM ExamScore es
    JOIN Course c ON es.CourseID = c.CourseID
    WHERE es.StuID = studentID;
    
    -- 开启事务
    START TRANSACTION;
    
    -- 更新原教学班的总人数减少1
    UPDATE class
    SET StuNub = StuNub - 1
    WHERE ClassID = oldClassID;
    
    -- 更新新教学班的总人数增加1
    UPDATE class
    SET StuNub = StuNub + 1
    WHERE ClassID = newClassID;
    
    -- 提交事务
    COMMIT;
    
    -- 输出提示信息
    SELECT '事务已完成。' AS Message;
END //

DELIMITER ;
-- 调用
CALL TransferStudentClass('S160004', 'TC-2016-002');

#(8)使用事务完成学生选课，学生选择教学班时，SC表应插入一条选课记录，同时教学班表对应的总人数加1，如果总人数超过50，则回滚事务。
DELIMITER //

CREATE PROCEDURE EnrollCourse(
    IN p_StuID VARCHAR(10),
    IN p_ClassID VARCHAR(20)
)
BEGIN
    DECLARE class_capacity INT;
    DECLARE current_count INT;
    
    START TRANSACTION;
    
    -- 检查教学班是否存在
    SELECT COUNT(*) INTO current_count FROM class WHERE ClassID = p_ClassID;
    IF current_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '教学班不存在';
    END IF;
    
    -- 检查教学班是否已满
    SELECT StuNub INTO class_capacity FROM class WHERE ClassID = p_ClassID;
    IF class_capacity >= 50 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '教学班已满';
    END IF;
    
    -- 插入选课记录
    INSERT INTO examscore (CourseID, StuID) VALUES (p_ClassID, p_StuID);
    
    -- 更新教学班总人数
    UPDATE class SET StuNub = StuNub + 1 WHERE ClassID = p_ClassID;
    
    COMMIT;
END //

DELIMITER ;
-- 调用
CALL EnrollCourse('S160004', 'TC-2016-00');
