ALTER table vicidial_auto_calls MODIFY status ENUM('SENT','RINGING','LIVE','XFER','PAUSED','CLOSER') default 'PAUSED';

ALTER table vicidial_campaigns MODIFY auto_dial_level ENUM('0','1','1.1','1.2','1.3','1.4','1.5','1.6','1.7','1.8','1.9','2.0','2.2','2.5','2.7','3.0') default '0';
ALTER table vicidial_campaigns ADD voicemail_ext VARCHAR(10);

ALTER table vicidial_live_agents ADD closer_campaigns VARCHAR(255);
ALTER table vicidial_live_agents MODIFY status ENUM('READY','QUEUE','INCALL','PAUSED','CLOSER') default 'PAUSED';

ALTER table vicidial_auto_calls MODIFY campaign_id VARCHAR(20);

ALTER table vicidial_closer_log MODIFY campaign_id VARCHAR(20);
ALTER TABLE vicidial_closer_log ADD INDEX(call_date);

 CREATE TABLE vicidial_inbound_groups (
group_id VARCHAR(20) PRIMARY KEY UNIQUE NOT NULL,
group_name VARCHAR(30),
group_color VARCHAR(7),
active ENUM('Y','N'),
web_form_address VARCHAR(255),
voicemail_ext VARCHAR(10),
next_agent_call ENUM('random','oldest_call_start','oldest_call_finish') default 'oldest_call_start'
);

 CREATE TABLE vicidial_xfer_log (
xfercallid INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
lead_id INT(9) UNSIGNED NOT NULL,
list_id INT(8) UNSIGNED,
campaign_id VARCHAR(20),
call_date DATETIME,
phone_code VARCHAR(10),
phone_number VARCHAR(10),
user VARCHAR(20),
closer VARCHAR(20),
index (lead_id),
index (call_date)
);

