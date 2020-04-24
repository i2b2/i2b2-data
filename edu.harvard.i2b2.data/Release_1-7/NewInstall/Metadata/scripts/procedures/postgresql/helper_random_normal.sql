-- https://bugfactory.io/blog/generating-random-numbers-according-to-a-continuous-probability-distribution-with-postgresql/

-- generates `count` normally distributed random numbers
--   with given mean and given standard deviation
CREATE OR REPLACE FUNCTION random_normal(
    count INTEGER DEFAULT 1,
    mean DOUBLE PRECISION DEFAULT 0.0,
    stddev DOUBLE PRECISION DEFAULT 1.0
    ) RETURNS SETOF DOUBLE PRECISION
      RETURNS NULL ON NULL INPUT AS $$
        DECLARE
            u DOUBLE PRECISION;
            v DOUBLE PRECISION;
            s DOUBLE PRECISION;
        BEGIN
            WHILE count > 0 LOOP
                u = RANDOM() * 2 - 1; -- range: -1.0 <= u < 1.0
                v = RANDOM() * 2 - 1; -- range: -1.0 <= v < 1.0
                s = u^2 + v^2;

                IF s != 0.0 AND s < 1.0 THEN
                    s = SQRT(-2 * LN(s) / s);

                    RETURN NEXT mean + stddev * s * u;
                    count = count - 1;

                    IF count > 0 THEN
                        RETURN NEXT mean + stddev * s * v;
                        count = count - 1;
                    END IF;
                END IF;
            END LOOP;
        END;
    $$ LANGUAGE plpgsql;
