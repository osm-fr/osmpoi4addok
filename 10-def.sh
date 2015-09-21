psql < def.sql
psql -c "COPY def FROM STDIN CSV HEADER" < def.csv
