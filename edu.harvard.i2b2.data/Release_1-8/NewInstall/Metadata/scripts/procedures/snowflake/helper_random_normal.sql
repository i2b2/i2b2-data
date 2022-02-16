-----------------------------------------------------------------------------------------------------------------
/*********************************************************
*         SNOWFLAKE IMPLEMENATION FOR RUNNING random_normal FUNCTION
*         Based on implementation from Postgresql
*         MD SABER HOSSAIN	7/14/2023
/*        University of Missouri-Columbia			
**********************************************************/
CREATE OR REPLACE PROCEDURE random_normal(
    mean FLOAT, 
    stddev FLOAT,
    threshold INTEGER
) 
RETURNS FLOAT NULL
LANGUAGE SQL
AS
DECLARE
    u FLOAT;
    v FLOAT;
    s FLOAT;
BEGIN
LOOP
    u := uniform(-1.0 :: FLOAT, 1.0 :: FLOAT, random());  -- range: -1.0 <= u < 1.0
    v := uniform(-1.0 :: FLOAT, 1.0 :: FLOAT, random());   -- range: -1.0 <= v < 1.0
    s := u*u + v*v;
    IF (s != 0.0 AND s < 1.0) THEN
        s := SQRT(-2 * LN(s) / s);

        IF (stddev * s * u > threshold) THEN 
            RETURN  mean + threshold;
        ELSEIF (stddev * s * u < -1 * threshold) THEN 
            RETURN  mean - threshold;
        ELSE
            RETURN  mean + stddev * s * u;
        END IF;
    END IF;
END LOOP;
END;
