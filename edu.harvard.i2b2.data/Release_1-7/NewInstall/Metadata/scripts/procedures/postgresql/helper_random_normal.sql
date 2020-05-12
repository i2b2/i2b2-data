-- https://bugfactory.io/blog/generating-random-numbers-according-to-a-continuous-probability-distribution-with-postgresql/

-- generates `count` normally distributed random numbers
--   with given mean and given standard deviation
--   if the noise is greater than threshold (or less than negative threshold), it is replaced by threshold
CREATE OR REPLACE FUNCTION random_normal(
    count INTEGER DEFAULT 1,
    mean DOUBLE PRECISION DEFAULT 0.0,
    stddev DOUBLE PRECISION DEFAULT 1.0,
    threshold integer default 10
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

                    IF stddev * s * u > threshold THEN 
                        RETURN NEXT mean + threshold;
                    ELSIF stddev * s * u < -1 * threshold THEN 
                        RETURN NEXT mean - threshold;
                    ELSE
                        RETURN NEXT mean + stddev * s * u;
                    END IF;
                    
                    count = count - 1;

                    IF count > 0 THEN
                        IF stddev * s * v > threshold THEN 
                            RETURN NEXT mean + threshold;
                        ELSIF stddev * s * v < -1 * threshold THEN 
                            RETURN NEXT mean - threshold;
                        ELSE
                            RETURN NEXT mean + stddev * s * v;
                        END IF;
                    
                        count = count - 1;
                    END IF;
                END IF;
            END LOOP;
        END;
    $$ LANGUAGE plpgsql;
