/*==============================================================*/
/* DBMS name:      MySQL 5.0                                    */
/* Created on:     2023/6/15 10:42:14                           */
/*==============================================================*/


drop table if exists Class;

drop table if exists Course;

drop table if exists Dormitory;

drop table if exists Employee;

drop table if exists ExamScore;

drop table if exists Salary;

drop table if exists Student;

/*==============================================================*/
/* Table: Class                                                 */
/*==============================================================*/
create table Class
(
   ClassID              varchar(20) not null,
   Tea_EmpID            varchar(10) not null,
   Semester             varchar(10),
   StartTime            varchar(20),
   EndTime              varchar(20),
   ClassRoom            varchar(6),
   StuNub               int,
   Evaluation           varchar(6),
   CourseID             varchar(10) not null,
   primary key (ClassID)
);

/*==============================================================*/
/* Table: Course                                                */
/*==============================================================*/
create table Course
(
   CourseID             varchar(10) not null,
   CourseName           varchar(20),
   ClassHour            int,
   primary key (CourseID)
);

/*==============================================================*/
/* Table: Dormitory                                             */
/*==============================================================*/
create table Dormitory
(
   DormNub              varchar(10) not null,
   CapNub               int,
   ResNub               int,
   SexLimit             char(2),
   primary key (DormNub)
);

/*==============================================================*/
/* Table: Employee                                              */
/*==============================================================*/
create table Employee
(
   EmpID                varchar(10) not null,
   EmpName              varchar(8),
   Category             char(4),
   EBirth               date,
   EID                  varchar(18),
   ESex                 char(2),
   Title                varchar(8),
   primary key (EmpID),
   key AK_Identifier_1 (EmpID)
);

/*==============================================================*/
/* Table: ExamScore                                             */
/*==============================================================*/
create table ExamScore
(
   CourseID             varchar(10) not null,
   StuID                varchar(10) not null,
   Score                float,
   primary key (CourseID, StuID)
);

/*==============================================================*/
/* Table: Salary                                                */
/*==============================================================*/
create table Salary
(
   EmpID                varchar(10) not null,
   SalaryMonth          date,
   BasePay              float(8,2),
   HourlyPay            float(8,2),
   Tax                  float(8,2),
   NetPay               float(8,2)
);

/*==============================================================*/
/* Table: Student                                               */
/*==============================================================*/
create table Student
(
   StuID                varchar(10) not null,
   StuName              varchar(8),
   Sex                  char(2),
   SBirth               date,
   SID                  varchar(18),
   DormNub              varchar(10) not null,
   primary key (StuID)
);

alter table Class add constraint FK_contain foreign key (CourseID)
      references Course (CourseID) on delete restrict on update restrict;

alter table Class add constraint FK_offer foreign key (Tea_EmpID)
      references Employee (EmpID) on delete restrict on update restrict;

alter table ExamScore add constraint FK_ExamScore1 foreign key (CourseID)
      references Course (CourseID) on delete restrict on update restrict;

alter table ExamScore add constraint FK_ExamScore2 foreign key (StuID)
      references Student (StuID) on delete restrict on update restrict;

alter table Salary add constraint FK_pay foreign key (EmpID)
      references Employee (EmpID) on delete restrict on update restrict;

alter table Student add constraint FK_reside foreign key (DormNub)
      references Dormitory (DormNub) on delete restrict on update restrict;

