insert into vicidial_statuses values('DROP','Agent Not Available','N');
insert into vicidial_statuses values('NA','No Answer AutoDial','N');

ALTER TABLE vicidial_campaigns add hopper_level ENUM('1','5','10','50','100','200','500') default '1';
ALTER TABLE vicidial_campaigns add auto_dial_level ENUM('0','1','1.1','1.2','1.3','1.4','1.5','1.6','1.7','1.8','1.9','2.0','2.5','3.0') default '0';
ALTER TABLE vicidial_campaigns add next_agent_call ENUM('random','oldest_call_start','oldest_call_finish') default 'oldest_call_start';

ALTER TABLE vicidial_list add called_count INT(8) UNSIGNED NOT NULL default '0';
ALTER TABLE vicidial_list add index(phone_number);

ALTER TABLE call_log add index(caller_code);

 CREATE TABLE vicidial_hopper (
hopper_id INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
lead_id INT(9) UNSIGNED NOT NULL,
campaign_id VARCHAR(8),			
status ENUM('READY','QUEUE','INCALL','DONE') default 'READY',
user VARCHAR(20),			
list_id INT(9) UNSIGNED NOT NULL,
index (lead_id)
);

 CREATE TABLE vicidial_live_agents (
live_agent_id INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
user VARCHAR(20),
server_ip VARCHAR(15) NOT NULL,
conf_exten INT(7) UNSIGNED,
extension VARCHAR(20),
status ENUM('READY','QUEUE','INCALL','PAUSED') default 'PAUSED',
lead_id INT(9) UNSIGNED NOT NULL,
campaign_id VARCHAR(8),			
uniqueid DOUBLE(18,7),
callerid VARCHAR(20),
channel VARCHAR(30),
random_id INT(8) UNSIGNED,
last_call_time DATETIME,
last_update_time TIMESTAMP,
last_call_finish DATETIME,
index (random_id),
index (last_call_time),
index (last_update_time),
index (last_call_finish)
);

 CREATE TABLE vicidial_auto_calls (
auto_call_id INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
server_ip VARCHAR(15) NOT NULL,
campaign_id VARCHAR(8),			
status ENUM('SENT','RINGING','LIVE','XFER','PAUSED') default 'PAUSED',
lead_id INT(9) UNSIGNED NOT NULL,
uniqueid DOUBLE(18,7),
callerid VARCHAR(20),
channel VARCHAR(30),
phone_code VARCHAR(10),
phone_number VARCHAR(10),
call_time DATETIME,
index (uniqueid),
index (callerid),
index (call_time)
);


