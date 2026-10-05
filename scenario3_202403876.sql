
1. Create tables and add three rooms

DROP TABLE IF EXISTS allocations;
DROP TABLE IF EXISTS hostel_rooms;

CREATE TABLE hostel_rooms (
    room_id INTEGER PRIMARY KEY,
    room_name VARCHAR(50),
    available_spaces INTEGER
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    room_id INTEGER REFERENCES hostel_rooms(room_id),
    status VARCHAR(20)
);

INSERT INTO hostel_rooms (room_id, room_name, available_spaces)
VALUES
(301, 'Room A', 4),
(302, 'Room B', 2),
(303, 'Room C', 1);


 2. IF ELSIF ELSE
 Check whether a room is full, has one space left or has several spaces

DO $$
DECLARE
    spaces INTEGER;
BEGIN
    SELECT available_spaces
    INTO spaces
    FROM hostel_rooms
    WHERE room_id = 303;

    IF spaces = 0 THEN
        RAISE NOTICE 'The room is FULL.';
    ELSIF spaces = 1 THEN
        RAISE NOTICE 'The room has ONE SPACE LEFT.';
    ELSE
        RAISE NOTICE 'The room has SEVERAL SPACES available.';
    END IF;
END $$;


 3. WHILE loop for three hostel inspection days

DO $$
DECLARE
    inspection_day INTEGER := 1;
BEGIN
    WHILE inspection_day <= 3 LOOP
        RAISE NOTICE 'Hostel inspection day %', inspection_day;
        inspection_day := inspection_day + 1;
    END LOOP;
END $$;


Numeric FOR loop for three room checks

DO $$
BEGIN
    FOR check_number IN 1..3 LOOP
        RAISE NOTICE 'Room check %', check_number;
    END LOOP;
END $$;


 4. Create allocate_room procedure

CREATE OR REPLACE PROCEDURE allocate_room(
    p_student_number VARCHAR,
    p_room_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    spaces INTEGER;
BEGIN

    IF TRIM(p_student_number) = '' OR p_student_number IS NULL THEN
        RAISE EXCEPTION 'Invalid student number. Student number cannot be blank.';
    END IF;

    SELECT available_spaces
    INTO spaces
    FROM hostel_rooms
    WHERE room_id = p_room_id;

    IF spaces IS NULL THEN
        RAISE NOTICE 'Hostel room does not exist.';
    ELSIF spaces <= 0 THEN
        RAISE NOTICE 'Allocation rejected. The room is FULL.';
    ELSE
        UPDATE hostel_rooms
        SET available_spaces = available_spaces - 1
        WHERE room_id = p_room_id;

        INSERT INTO allocations
        (student_number, room_id, status)
        VALUES
        (p_student_number, p_room_id, 'ALLOCATED');

        RAISE NOTICE 'Room allocation successful for student %.',
            p_student_number;
    END IF;

END;
$$;


5. Two valid allocations and one allocation to a full room

CALL allocate_room('202408460', 301);

CALL allocate_room('202408461', 302);

CALL allocate_room('202408462', 303);


 Query rooms and allocations

SELECT * FROM hostel_rooms;

SELECT * FROM allocations;


 6. Create check_out procedure

CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    allocation_status VARCHAR;
    allocated_room INTEGER;
BEGIN

    SELECT status, room_id
    INTO allocation_status, allocated_room
    FROM allocations
    WHERE allocation_id = p_allocation_id;

    IF allocation_status IS NULL THEN
        RAISE NOTICE 'Allocation does not exist.';

    ELSIF allocation_status = 'ALLOCATED' THEN

        UPDATE hostel_rooms
        SET available_spaces = available_spaces + 1
        WHERE room_id = allocated_room;

        UPDATE allocations
        SET status = 'CHECKED_OUT'
        WHERE allocation_id = p_allocation_id;

        RAISE NOTICE 'Student checked out and bed space released.';

    ELSE
        RAISE NOTICE 'Student has already checked out. Bed space will not be released again.';
    END IF;

END;
$$;


 Call it twice for the same allocation

CALL check_out(1);

CALL check_out(1);


 7. Explicit cursor to display full or nearly full rooms

DO $$
DECLARE
    room_record RECORD;

    room_cursor CURSOR FOR
        SELECT room_id, room_name, available_spaces
        FROM hostel_rooms
        WHERE available_spaces <= 1;

BEGIN

    OPEN room_cursor;

    LOOP
        FETCH room_cursor INTO room_record;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Room: %, Available spaces: %',
            room_record.room_name,
            room_record.available_spaces;
    END LOOP;

    CLOSE room_cursor;

END $$;


8. Attempt an allocation using a blank student number
Handle the invalid input with an EXCEPTION block

DO $$
BEGIN

    BEGIN
        CALL allocate_room('', 301);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Invalid student number handled: %', SQLERRM;
    END;

END $$;


9.Final queries

SELECT
    room_id,
    room_name,
    available_spaces
FROM hostel_rooms
ORDER BY room_id;

SELECT
    allocation_id,
    student_number,
    room_id,
    status
FROM allocations
ORDER BY allocation_id;