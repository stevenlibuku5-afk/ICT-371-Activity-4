
CREATE TABLE lab_sessions (
    session_id INTEGER PRIMARY KEY,
    session_name VARCHAR(100),
    available_workstations INTEGER
);

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    lecturer VARCHAR(100),
    session_id INTEGER REFERENCES lab_sessions(session_id),
    workstations INTEGER,
    status VARCHAR(20)
);

INSERT INTO lab_sessions (session_id, session_name, available_workstations)
VALUES
(201, 'Database Practical', 20),
(202, 'Networking Practical', 10),
(203, 'Programming Practical', 5);

 IF ELSIF ELSE


DO $$
DECLARE
    available INTEGER;
BEGIN
    SELECT available_workstations
    INTO available
    FROM lab_sessions
    WHERE session_id = 203;

    IF available = 0 THEN
        RAISE NOTICE 'The session is FULL.';
    ELSIF available <= 2 THEN
        RAISE NOTICE 'The session is NEARLY FULL.';
    ELSE
        RAISE NOTICE 'The session has ENOUGH workstations.';
    END IF;
END $$;

 3. WHILE loop for three session preparation reminders

DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN
    WHILE reminder_number <= 3 LOOP
        RAISE NOTICE 'Session preparation reminder %', reminder_number;
        reminder_number := reminder_number + 1;
    END LOOP;
END $$;

 Numeric FOR loop for three workstation checks

DO $$
BEGIN
    FOR check_number IN 1..3 LOOP
        RAISE NOTICE 'Workstation check %', check_number;
    END LOOP;
END $$;


4. Create reserve_workstations procedure

CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_lecturer VARCHAR,
    p_session_id INTEGER,
    p_workstations INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    available INTEGER;
BEGIN

    IF p_workstations <= 0 THEN
        RAISE EXCEPTION 'Invalid number of workstations. Quantity must be greater than zero.';
    END IF;

    SELECT available_workstations
    INTO available
    FROM lab_sessions
    WHERE session_id = p_session_id;

    IF available IS NULL THEN
        RAISE NOTICE 'Lab session does not exist.';
    ELSIF p_workstations > available THEN
        RAISE NOTICE 'Reservation rejected. Only % workstations are available.', available;
    ELSE
        UPDATE lab_sessions
        SET available_workstations = available_workstations - p_workstations
        WHERE session_id = p_session_id;

        INSERT INTO reservations
        (lecturer, session_id, workstations, status)
        VALUES
        (p_lecturer, p_session_id, p_workstations, 'RESERVED');

        RAISE NOTICE 'Reservation successful for % workstations.', p_workstations;
    END IF;

END;
$$;

 5. Two valid reservations and one exceeding capacity

CALL reserve_workstations('Mr Banda', 201, 5);

CALL reserve_workstations('Mrs Phiri', 202, 4);

CALL reserve_workstations('Mr Tembo', 203, 10);


-- Query sessions and reservations

SELECT * FROM lab_sessions;

SELECT * FROM reservations;


6. Create cancel_reservation procedure

CREATE OR REPLACE PROCEDURE cancel_reservation(
    p_reservation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    reservation_status VARCHAR;
    reserved_workstations INTEGER;
    reserved_session INTEGER;
BEGIN

    SELECT status, workstations, session_id
    INTO reservation_status, reserved_workstations, reserved_session
    FROM reservations
    WHERE reservation_id = p_reservation_id;

    IF reservation_status IS NULL THEN
        RAISE NOTICE 'Reservation does not exist.';
    ELSIF reservation_status = 'RESERVED' THEN

        UPDATE lab_sessions
        SET available_workstations =
            available_workstations + reserved_workstations
        WHERE session_id = reserved_session;

        UPDATE reservations
        SET status = 'CANCELLED'
        WHERE reservation_id = p_reservation_id;

        RAISE NOTICE 'Reservation cancelled and workstations released.';

    ELSE
        RAISE NOTICE 'Reservation has already been cancelled. Workstations will not be released again.';
    END IF;

END;
$$;


Call it twice for the same reservation

CALL cancel_reservation(1);

CALL cancel_reservation(1);


7. Explicit cursor to display sessions with few workstations remaining

DO $$
DECLARE
    session_record RECORD;

    session_cursor CURSOR FOR
        SELECT session_id, session_name, available_workstations
        FROM lab_sessions
        WHERE available_workstations <= 5;

BEGIN

    OPEN session_cursor;

    LOOP
        FETCH session_cursor INTO session_record;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Session: %, Available workstations: %',
            session_record.session_name,
            session_record.available_workstations;
    END LOOP;

    CLOSE session_cursor;

END $$;


 8. Try to reserve zero workstations
Handle invalid quantity with an EXCEPTION block

DO $$
BEGIN

    BEGIN
        CALL reserve_workstations('Mr Zero', 201, 0);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Invalid reservation handled: %', SQLERRM;
    END;

END $$;

 9. Final queries

SELECT
    session_id,
    session_name,
    available_workstations
FROM lab_sessions
ORDER BY session_id;

SELECT
    reservation_id,
    lecturer,
    session_id,
    workstations,
    status
FROM reservations
ORDER BY reservation_id;