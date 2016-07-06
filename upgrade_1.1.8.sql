ALTER TABLE vicidial_campaigns ADD campaign_rec_exten VARCHAR(20) default '8309';
ALTER TABLE vicidial_campaigns ADD campaign_recording ENUM('NEVER','ONDEMAND','ALLCALLS') default 'ONDEMAND';
ALTER TABLE vicidial_campaigns ADD campaign_rec_filename VARCHAR(50) default 'FULLDATE_AGENT';


 CREATE TABLE vicidial_agent_log (
agent_log_id INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
user VARCHAR(20),
server_ip VARCHAR(15) NOT NULL,
event_time DATETIME,
lead_id INT(9) UNSIGNED,
campaign_id VARCHAR(8),			
pause_epoch INT(10) UNSIGNED,
pause_sec SMALLINT(5) UNSIGNED default '0',
wait_epoch INT(10) UNSIGNED,
wait_sec SMALLINT(5) UNSIGNED default '0',
talk_epoch INT(10) UNSIGNED,
talk_sec SMALLINT(5) UNSIGNED default '0',
dispo_epoch INT(10) UNSIGNED,
dispo_sec SMALLINT(5) UNSIGNED default '0',
status VARCHAR(6)
);
