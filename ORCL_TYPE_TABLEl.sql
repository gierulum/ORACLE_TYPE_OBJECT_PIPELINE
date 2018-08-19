--OBJECTS
/*
CREATE OR REPLACE TYPE NAME AS OBJECT (ATR DATA_TYPE...);

CREATE OR REPLACE TYPE NAME_TYPE IS TABLE OF TYPE_TABLE;
CREATE OR REPLACE TYPE NAME_TYPE IS VARRAY OF TYPE_TABLE;

*/

CREATE TYPE V_DATA IS OBJECT (A_DATA DATE, A_DEP NUMBER(10));
CREATE TYPE V_DATA_T IS TABLE OF V_DATA;

--DROP TYPE V_DATA
--DROP TYPE V_DATA_T

/

CREATE OR REPLACE FUNCTION MY_DATES(P_PERIOD VARCHAR, P_ID NUMBER)
RETURN V_DATA_T
IS 
  C_NUM NUMBER;
  B_DATA_T V_DATA_T := V_DATA_T();
  B_DATA V_DATA   := V_DATA(NULL, NULL);
  --B_PERIOD DATE   := TRUNC(P_PERIOD);
  --V_MEMORY NUMBER;
  
  CURSOR MGIE IS 
  SELECT MAX(ID)
  FROM 
  (SELECT ID,
  LAG(TEXT_1,1) OVER (ORDER BY TEXT_1) LAG,
  LEAD(TEXT_1,1) OVER (ORDER BY TEXT_1) LEAD
  FROM AAA_TEST_DATATABLE) A
  WHERE P_ID BETWEEN A.LAG AND A.LEAD; 
 
  BEGIN 
    OPEN MGIE;
    FETCH MGIE INTO C_NUM;
    CLOSE MGIE;
    FOR I IN 1..C_NUM LOOP
      B_DATA_T.EXTEND;
      B_DATA.A_DATA := TO_DATE(SYSDATE, 'YYYY-MM-DD');
      B_DATA.A_DEP  := I+1;
      B_DATA_T(I) := B_DATA;
    END LOOP;
    RETURN B_DATA_T;
  END;

/

SELECT * FROM TABLE(MY_DATES(10, 300));
  
/

CREATE TABLE AA_EMPLOYEES (ID NUMBER,
NAME VARCHAR2(30),
SURNAME VARCHAR2(30),
BIRTH_DATE DATE
);
/

INSERT INTO AA_EMPLOYEES VALUES ( 1, 'PETER', 'SULLIVAN', '1981-02-28');
INSERT INTO AA_EMPLOYEES VALUES ( 2, 'MARGOT', 'KASPERSKY', '1981-02-16');
INSERT INTO AA_EMPLOYEES VALUES ( 5, 'OLGA', 'BROOKS', '1981-02-28');
INSERT INTO AA_EMPLOYEES VALUES ( 6, 'MARK', 'TOLKIEN', '1981-02-28');
INSERT INTO AA_EMPLOYEES VALUES ( 3, 'JOSH', 'XYZ', '1981-02-10');
INSERT INTO AA_EMPLOYEES VALUES ( 4, 'ANNA', 'ABCD', '1981-02-15');
COMMIT;

/

CREATE TYPE T_EMPLOYEES IS OBJECT (NAME VARCHAR2(30), BORN DATE);
CREATE TYPE T_EMPL IS TABLE OF T_EMPLOYEES;

--DROP TYPE T_EMPLOYEES;
--DROP TYPE T_EMPL; 

/

CREATE OR REPLACE FUNCTION EMPL_BORN(V_NAME VARCHAR2, V_BIRTH_DATE DATE)
  RETURN T_EMPL
IS
  W_EMPL T_EMPL := T_EMPL();
  W_EMPLOYEES T_EMPLOYEES := T_EMPLOYEES(NULL, NULL);
  W_COUNT NUMBER;

CURSOR COUNT_EMPL IS
SELECT COUNT(1)
FROM AA_EMPLOYEES 
WHERE BIRTH_DATE LIKE V_BIRTH_DATE
AND NAME LIKE V_NAME;


CURSOR C_EMPL (V_ROWNUM IN NUMBER) IS
SELECT 
NAME, 
BIRTH_DATE
FROM AA_EMPLOYEES 
WHERE BIRTH_DATE = V_BIRTH_DATE
AND NAME = V_NAME 
AND ROWNUM = V_ROWNUM;

BEGIN
  OPEN COUNT_EMPL;
  FETCH COUNT_EMPL INTO W_COUNT;
  CLOSE COUNT_EMPL;
  FOR I IN 1..W_COUNT LOOP
    FOR X IN C_EMPL(I) LOOP
    
      W_EMPL.EXTEND;
      W_EMPLOYEES.NAME := X.NAME;
      W_EMPLOYEES.BORN := TO_DATE(X.BIRTH_DATE, 'YYYY-MM-DD');
      W_EMPL(I) := W_EMPLOYEES;
    --CLOSE C_EMPL;
    END LOOP;
  END LOOP;
  RETURN W_EMPL; 
END;

/

SELECT * FROM TABLE(EMPL_BORN('JOSH','81/02/10'));

/

select * from AA_EMPLOYEES 

/

create type personal_employees is object(name_surname varchar2(60));
create type name_surnames is table of personal_employees;

create or replace function person_employee(v_birth_date date)
return name_surnames
pipelined 
is 
  v_n_persons number(10);
  v_name_surnames name_surnames:= name_surnames();
  v_names personal_employees := personal_employees(null);
  v_pers_names varchar2(50);
  
  cursor num_persons is 
  select 
  count(1) 
  from AA_EMPLOYEES
  where birth_date = v_birth_date;

  cursor persons_by_birth(y in number) is 
  select name||' '||surname names
  from AA_EMPLOYEES 
  where birth_date = v_birth_date 
  and rownum = y;

begin

  open num_persons;
  fetch num_persons into v_n_persons;
  close num_persons;

  for y in 1..v_n_persons loop
    for q in persons_by_birth(y) loop
      v_names.name_surname := q.names;
    end loop;
    pipe row (v_names);  
  end loop;
  return;
end;

/

select * from table(person_employee('81/02/28'));
