CREATE DISKGROUP DATA EXTERNAL REDUNDANCY DISK 'ORCL:DATA001'
ATTRIBUTE 'au_size'='1M',
'compatible.asm' = '11.2', 
'compatible.rdbms' = '11.2',
'compatible.advm' = '11.2';


CREATE DISKGROUP FRA EXTERNAL REDUNDANCY DISK 'ORCL:FRA001'
ATTRIBUTE 'au_size'='1M',
'compatible.asm' = '11.2', 
'compatible.rdbms' = '11.2',
'compatible.advm' = '11.2';

--check free space in DG.
SELECT name, total_mb, free_mb,  round(free_mb/total_mb*100,2) as "Free percentage"  FROM v$asm_diskgroup;

Exit;
