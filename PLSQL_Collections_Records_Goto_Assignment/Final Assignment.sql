
-- ==========================
-- 1. Create Tables
-- ==========================
CREATE TABLE WARDS (
    ward_id NUMBER PRIMARY KEY,
    ward_name VARCHAR2(50),
    total_beds NUMBER,
    location VARCHAR2(50)
);

CREATE TABLE BEDS (
    bed_id NUMBER PRIMARY KEY,
    ward_id NUMBER REFERENCES WARDS(ward_id),
    occupied CHAR(1) DEFAULT 'N',
    bed_type VARCHAR2(20)
);

CREATE TABLE PATIENTS (
    patient_id NUMBER PRIMARY KEY,
    patient_name VARCHAR2(50),
    bed_id NUMBER REFERENCES BEDS(bed_id),
    admit_date DATE,
    discharge_date DATE,
    condition VARCHAR2(50)
);

-- ==========================
-- 2. Insert Sample Data
-- ==========================
INSERT INTO WARDS VALUES (1, 'General Ward', 5, '1st Floor');
INSERT INTO WARDS VALUES (2, 'ICU', 3, '2nd Floor');
INSERT INTO WARDS VALUES (3, 'Pediatrics', 4, '3rd Floor');

INSERT INTO BEDS VALUES (101, 1, 'N', 'General');
INSERT INTO BEDS VALUES (102, 1, 'N', 'General');
INSERT INTO BEDS VALUES (103, 1, 'N', 'General');
INSERT INTO BEDS VALUES (104, 1, 'N', 'General');
INSERT INTO BEDS VALUES (105, 1, 'N', 'General');

INSERT INTO BEDS VALUES (201, 2, 'N', 'ICU');
INSERT INTO BEDS VALUES (202, 2, 'N', 'ICU');
INSERT INTO BEDS VALUES (203, 2, 'N', 'ICU');

INSERT INTO BEDS VALUES (301, 3, 'N', 'Pediatric');
INSERT INTO BEDS VALUES (302, 3, 'N', 'Pediatric');
INSERT INTO BEDS VALUES (303, 3, 'N', 'Pediatric');
INSERT INTO BEDS VALUES (304, 3, 'N', 'Pediatric');

INSERT INTO PATIENTS VALUES (1, 'John Doe', NULL, NULL, NULL, 'Flu');
INSERT INTO PATIENTS VALUES (2, 'Jane Smith', NULL, NULL, NULL, 'Covid');
INSERT INTO PATIENTS VALUES (3, 'Baby Mike', NULL, NULL, NULL, 'Fever');

COMMIT;

-- ==========================
-- 3. PL/SQL RECORD Example
-- ==========================
DECLARE
    TYPE ward_rec IS RECORD (
        ward_id WARDS.ward_id%TYPE,
        ward_name WARDS.ward_name%TYPE,
        total_beds WARDS.total_beds%TYPE,
        location WARDS.location%TYPE
    );
    w ward_rec;
BEGIN
    SELECT ward_id, ward_name, total_beds, location
    INTO w
    FROM WARDS
    WHERE ward_id = 2;

    DBMS_OUTPUT.PUT_LINE('Ward: ' || w.ward_name || ' | Location: ' || w.location || ' | Total Beds: ' || w.total_beds);
END;

-- ==========================
-- 4. PL/SQL COLLECTION Example
-- ==========================
DECLARE
    TYPE bed_list IS TABLE OF BEDS.bed_id%TYPE;
    available_beds bed_list;
BEGIN
    SELECT bed_id BULK COLLECT INTO available_beds
    FROM BEDS
    WHERE occupied = 'N';

    DBMS_OUTPUT.PUT_LINE('Available Beds:');
    FOR i IN 1..available_beds.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(available_beds(i));
    END LOOP;
END;

-- ==========================
-- 5. PL/SQL GOTO Example
-- ==========================
DECLARE
    free_beds NUMBER;
BEGIN
    SELECT COUNT(*) INTO free_beds FROM BEDS WHERE occupied = 'N';

    IF free_beds = 0 THEN
        GOTO no_beds;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Number of available beds: ' || free_beds);
    RETURN;

    <<no_beds>>
    DBMS_OUTPUT.PUT_LINE('No beds available in hospital!');
END;

-- ==========================
-- 6. Trigger for Alerts
-- ==========================
CREATE OR REPLACE TRIGGER bed_occupancy_alert
AFTER INSERT OR UPDATE ON BEDS
FOR EACH ROW
DECLARE
    occupied_count NUMBER;
    total_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO occupied_count FROM BEDS
    WHERE ward_id = :NEW.ward_id AND occupied = 'Y';

    SELECT total_beds INTO total_count FROM WARDS
    WHERE ward_id = :NEW.ward_id;

    IF occupied_count >= total_count THEN
        DBMS_OUTPUT.PUT_LINE('ALERT: Ward ' || :NEW.ward_id || ' is full!');
    END IF;
END;

-- ==========================
-- 7. Additional Queries
-- ==========================
-- Show bed occupancy per ward
SELECT w.ward_name, COUNT(b.bed_id) AS total_beds, 
       SUM(CASE WHEN b.occupied='Y' THEN 1 ELSE 0 END) AS occupied_beds,
       SUM(CASE WHEN b.occupied='N' THEN 1 ELSE 0 END) AS free_beds
FROM WARDS w
JOIN BEDS b ON w.ward_id=b.ward_id
GROUP BY w.ward_name;

-- Show all patients per ward
SELECT w.ward_name, p.patient_name, b.bed_id, p.condition
FROM PATIENTS p
JOIN BEDS b ON p.bed_id=b.bed_id
JOIN WARDS w ON b.ward_id=w.ward_id
ORDER BY w.ward_name;
