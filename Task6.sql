#使用触发器完成为学生表添加一条记录，则触发器触发，对应宿舍的剩余容量减1，查询剩余容量值，如果剩余容量值<0,则回滚事务
DELIMITER //

CREATE TRIGGER `trg_insert_student` AFTER INSERT ON `student`
FOR EACH ROW
BEGIN
    UPDATE `dormitory` SET `ResNub` = `ResNub` + 1 WHERE `DormNub` = NEW.`DormNub`;
END //

DELIMITER ;
