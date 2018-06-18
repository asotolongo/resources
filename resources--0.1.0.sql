CREATE SCHEMA resources;




CREATE SERVER fs
   FOREIGN DATA WRAPPER file_fdw;






CREATE FOREIGN TABLE resources.cpu_loadavg
   (one_min text ,
    five_min text ,
    ten_min text )
   SERVER fs
   OPTIONS (delimiter ',', program 'cat /proc/loadavg | awk ''{print $1 "," $2 "," $3 }''');


COMMENT ON FOREIGN TABLE resources.cpu_loadavg
  IS 'CPU use on last 1, 5 y 10 minutes';



CREATE FOREIGN TABLE resources.cpu_use
   (cpu text ,
    cpu_use text )
   SERVER fs
   OPTIONS (program 'top -bn 2 -d 1  | grep "Cpu(s)" | awk ''FNR==2''', delimiter ':');

COMMENT ON FOREIGN TABLE resources.cpu_use
  IS 'CPU use by user, sys, nice, idle, wait';



CREATE FOREIGN TABLE resources.distribution
   (version text )
   SERVER fs
   OPTIONS (delimiter ';', program 'cat /proc/version');

COMMENT ON FOREIGN TABLE resources.distribution
  IS 'SO distribution';


CREATE FOREIGN TABLE resources.lscpu
   (value text )
   SERVER fs
   OPTIONS (delimiter ';', program 'lscpu');

COMMENT ON FOREIGN TABLE resources.lscpu
  IS 'CPU characteristics';

CREATE FOREIGN TABLE resources.meminfo
   ( value text )
   SERVER fs
   OPTIONS (delimiter ';', program ' awk ''{$2=($2/1024)/1024;$3="GB";} 1'' /proc/meminfo | column -t');
ALTER FOREIGN TABLE resources.meminfo
  OWNER TO postgres;
COMMENT ON FOREIGN TABLE resources.meminfo
  IS 'RAM use';


CREATE FOREIGN TABLE resources.partitions
   (fs character varying ,
    size character varying ,
    used character varying ,
    available character varying ,
    percent_used character varying ,
    mount_in character varying )
   SERVER fs
   OPTIONS (program 'df -h | awk ''{print $1 ":" $2 ":" $3 ":" $4 ":" $5 ":" $6}''', delimiter ':');

COMMENT ON FOREIGN TABLE resources.partitions
  IS 'Disc partitions use';




CREATE FOREIGN TABLE resources.ps_postgres
   (users character varying ,
    pid character varying ,
    cpu_percent character varying ,
    mem_percent character varying )
   SERVER fs
   OPTIONS (program 'ps -u postgres -o uname,pid,pcpu,pmem | awk ''{print $1 "," $2 "," $3 "," $4 }''', delimiter ',');

COMMENT ON FOREIGN TABLE resources.ps_postgres
  IS 'PG process data to build v_ps_postgre view';




CREATE OR REPLACE VIEW resources.v_ps_postgres AS 
 SELECT a.pid,
    a.datname,
    ps_postgres.cpu_percent,
    ps_postgres.mem_percent,
    a.client_addr,
    a.state,
    a.query,
    a.backend_type
   FROM resources.ps_postgres,
    pg_stat_activity a
  WHERE ps_postgres.pid::integer = a.pid AND ps_postgres.pid::text <> 'PID'::text;

ALTER TABLE resources.v_ps_postgres
  OWNER TO postgres;
COMMENT ON VIEW resources.v_ps_postgres
  IS 'View to show PG process (PID, CPU_percent, mem_percent, IP, state, query, backend type)';




