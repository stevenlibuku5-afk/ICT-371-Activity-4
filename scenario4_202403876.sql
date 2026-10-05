

CREATE TABLE medicines (
    medicine_id INTEGER PRIMARY KEY,
    medicine_name VARCHAR(100),
    stock_quantity INTEGER
);

CREATE TABLE dispensing_records (
    dispensing_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    medicine_id INTEGER REFERENCES medicines(medicine_id),
    quantity INTEGER,
    status VARCHAR(20)
);

INSERT INTO medicines (medicine_id, medicine_name, stock_quantity)
VALUES
(401, 'Paracetamol', 50),
(402, 'Amoxicillin', 20),
(403, 'Ibuprofen', 10);


2. IF ELSIF ELSE
 Check whether one medicine is out of stock,
low on stock or sufficiently stocked

DO $$
DECLARE
    stock INTEGER;
BEGIN
    SELECT stock_quantity
    INTO stock
    FROM medicines
    WHERE medicine_id = 403;

    IF stock = 0 THEN
        RAISE NOTICE 'The medicine is OUT OF STOCK.';
    ELSIF stock <= 10 THEN
        RAISE NOTICE 'The medicine is LOW ON STOCK.';
    ELSE
        RAISE NOTICE 'The medicine is SUFFICIENTLY STOCKED.';
    END IF;
END $$;


 3. WHILE loop for three stock review days

DO $$
DECLARE
    review_day INTEGER := 1;
BEGIN
    WHILE review_day <= 3 LOOP
        RAISE NOTICE 'Stock review day %', review_day;
        review_day := review_day + 1;
    END LOOP;
END $$;


 Numeric FOR loop for three shelf inspections

DO $$
BEGIN
    FOR inspection_number IN 1..3 LOOP
        RAISE NOTICE 'Shelf inspection %', inspection_number;
    END LOOP;
END $$;


4. Create dispense_medicine procedure

CREATE OR REPLACE PROCEDURE dispense_medicine(
    p_student_number VARCHAR,
    p_medicine_id INTEGER,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    stock INTEGER;
BEGIN

    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity. Quantity must be greater than zero.';
    END IF;

    SELECT stock_quantity
    INTO stock
    FROM medicines
    WHERE medicine_id = p_medicine_id;

    IF stock IS NULL THEN
        RAISE NOTICE 'Medicine does not exist.';

    ELSIF p_quantity > stock THEN
        RAISE NOTICE 'Dispensing rejected. Only % units are available.', stock;

    ELSE
        UPDATE medicines
        SET stock_quantity = stock_quantity - p_quantity
        WHERE medicine_id = p_medicine_id;

        INSERT INTO dispensing_records
        (student_number, medicine_id, quantity, status)
        VALUES
        (p_student_number, p_medicine_id, p_quantity, 'DISPENSED');

        RAISE NOTICE 'Medicine dispensed successfully.';

    END IF;

END;
$$;


5. Two valid quantities and one quantity exceeding stock

CALL dispense_medicine('202408460', 401, 10);

CALL dispense_medicine('202408461', 402, 5);

CALL dispense_medicine('202408462', 403, 20);


Query medicines and dispensing records

SELECT * FROM medicines;

SELECT * FROM dispensing_records;


 6. Create reverse_dispensing procedure

CREATE OR REPLACE PROCEDURE reverse_dispensing(
    p_dispensing_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    dispensing_status VARCHAR;
    dispensed_quantity INTEGER;
    dispensed_medicine INTEGER;
BEGIN

    SELECT status, quantity, medicine_id
    INTO dispensing_status, dispensed_quantity, dispensed_medicine
    FROM dispensing_records
    WHERE dispensing_id = p_dispensing_id;

    IF dispensing_status IS NULL THEN
        RAISE NOTICE 'Dispensing record does not exist.';

    ELSIF dispensing_status = 'DISPENSED' THEN

        UPDATE medicines
        SET stock_quantity = stock_quantity + dispensed_quantity
        WHERE medicine_id = dispensed_medicine;

        UPDATE dispensing_records
        SET status = 'REVERSED'
        WHERE dispensing_id = p_dispensing_id;

        RAISE NOTICE 'Dispensing record reversed and stock restored.';

    ELSE
        RAISE NOTICE 'Dispensing record has already been reversed. Stock will not be restored again.';
    END IF;

END;
$$;


 Call it twice for the same record

CALL reverse_dispensing(1);

CALL reverse_dispensing(1);


7. Explicit cursor to display medicines below a low-stock threshold

DO $$
DECLARE
    medicine_record RECORD;

    medicine_cursor CURSOR FOR
        SELECT medicine_id, medicine_name, stock_quantity
        FROM medicines
        WHERE stock_quantity < 10;

BEGIN

    OPEN medicine_cursor;

    LOOP
        FETCH medicine_cursor INTO medicine_record;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Medicine: %, Stock remaining: %',
            medicine_record.medicine_name,
            medicine_record.stock_quantity;
    END LOOP;

    CLOSE medicine_cursor;

END $$;


 8. Request a negative dispensing quantity
Handle the invalid input with an EXCEPTION block

DO $$
BEGIN

    BEGIN
        CALL dispense_medicine('202408460', 401, -5);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Invalid quantity handled: %', SQLERRM;
    END;

END $$;

 9. Final queries

SELECT
    medicine_id,
    medicine_name,
    stock_quantity
FROM medicines
ORDER BY medicine_id;

SELECT
    dispensing_id,
    student_number,
    medicine_id,
    quantity,
    status
FROM dispensing_records
ORDER BY dispensing_id;