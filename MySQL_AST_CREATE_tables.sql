 CREATE TABLE phones (
extension VARCHAR(20),
dialplan_number INT(10),
voicemail_id VARCHAR(10),
phone_ip VARCHAR(15),
computer_ip VARCHAR(15),
server_ip VARCHAR(15),	
login VARCHAR(15),	
pass VARCHAR(10),		
status VARCHAR(10),		
active ENUM('Y','N'),		
phone_type VARCHAR(50),		
fullname VARCHAR(50),	
company VARCHAR(10),	
picture VARCHAR(19),	
messages INT(4),	
old_messages INT(4)	
);

 CREATE TABLE servers (
server_id VARCHAR(10) NOT NULL,
server_description VARCHAR(255),
server_ip VARCHAR(15) NOT NULL,
active ENUM('Y','N')
);

 CREATE TABLE live_channels (
channel VARCHAR(10) NOT NULL,
server_ip VARCHAR(15) NOT NULL,
channel_group VARCHAR(30),
extension VARCHAR(20)
);

 CREATE TABLE live_sip_channels (
channel VARCHAR(30) NOT NULL,
server_ip VARCHAR(15) NOT NULL,
channel_group VARCHAR(30),
extension VARCHAR(40)
);

 CREATE TABLE parked_channels (
channel VARCHAR(10) NOT NULL,
server_ip VARCHAR(15) NOT NULL,
channel_group VARCHAR(30),
extension VARCHAR(20),
parked_by VARCHAR(20),
parked_time DATETIME
);

 CREATE TABLE conferences (
conf_exten INT(7) UNSIGNED NOT NULL,
server_ip VARCHAR(15) NOT NULL,
extension VARCHAR(20)
);

 CREATE TABLE recording_log (
recording_id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
channel VARCHAR(20),
server_ip VARCHAR(15),
extension VARCHAR(20),
start_time DATETIME,
start_epoch INT(10),
end_time DATETIME,
end_epoch INT(10),
length_in_sec INT(10),
length_in_min DOUBLE(8,2),
filename VARCHAR(50),
location VARCHAR(255)
);

 CREATE TABLE live_inbound (
uniqueid DOUBLE(18,7) NOT NULL,
channel VARCHAR(30) NOT NULL,
server_ip VARCHAR(15) NOT NULL,
caller_id VARCHAR(30),
extension VARCHAR(40),
phone_ext VARCHAR(40),
start_time DATETIME,
acknowledged ENUM('Y','N') default 'N',
inbound_number VARCHAR(20),
comment_a VARCHAR(50),
comment_b VARCHAR(50),
comment_c VARCHAR(50),
comment_d VARCHAR(50),
comment_e VARCHAR(50)
);

 CREATE TABLE inbound_numbers (
extension VARCHAR(30) NOT NULL,
full_number VARCHAR(30) NOT NULL,
server_ip VARCHAR(15) NOT NULL,
inbound_name VARCHAR(30)
);

 CREATE TABLE server_updater (
server_ip VARCHAR(15) NOT NULL,
last_update DATETIME
);

 CREATE TABLE call_log (
uniqueid DOUBLE(18,7) PRIMARY KEY UNIQUE NOT NULL,
channel VARCHAR(20),
channel_group VARCHAR(30),
type VARCHAR(10),
server_ip VARCHAR(15),
extension VARCHAR(20),
number_dialed VARCHAR(15),
caller_code VARCHAR(20),
start_time DATETIME,
start_epoch INT(10),
end_time DATETIME,
end_epoch INT(10),
length_in_sec INT(10),
length_in_min DOUBLE(8,2),
	index (caller_code)
);

 CREATE TABLE park_log (
uniqueid DOUBLE(18,7) PRIMARY KEY UNIQUE NOT NULL,
status VARCHAR(10),
channel VARCHAR(20),
channel_group VARCHAR(30),
server_ip VARCHAR(15),
parked_time DATETIME,
grab_time DATETIME,
hangup_time DATETIME,
parked_sec INT(10),
talked_sec INT(10),
extension VARCHAR(20),
user VARCHAR(20),
index (parked_time)
);

 CREATE TABLE vicidial_manager (
man_id INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
uniqueid DOUBLE(18,7),
entry_date DATETIME,
status  ENUM('NEW','QUEUE','SENT','UPDATED','DEAD'),
response  ENUM('Y','N'),
server_ip VARCHAR(15) NOT NULL,
channel VARCHAR(30),
action VARCHAR(20),
callerid VARCHAR(20),
cmd_line_b VARCHAR(50),
cmd_line_c VARCHAR(50),
cmd_line_d VARCHAR(50),
cmd_line_e VARCHAR(50),
cmd_line_f VARCHAR(50),
cmd_line_g VARCHAR(50),
cmd_line_h VARCHAR(50),
cmd_line_i VARCHAR(50),
cmd_line_j VARCHAR(50),
cmd_line_k VARCHAR(50),
index (callerid),
index (uniqueid)
);

 CREATE TABLE vicidial_list (
lead_id INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
entry_date DATETIME,
modify_date TIMESTAMP,
status VARCHAR(6),			
user VARCHAR(20),			
vendor_lead_code VARCHAR(20),		
source_id VARCHAR(6),			
list_id INT(8) UNSIGNED,		
campaign_id VARCHAR(8),			
called_since_last_reset ENUM('Y','N'),	
phone_code VARCHAR(10),			
phone_number VARCHAR(10),		
title VARCHAR(4),
first_name VARCHAR(30),
middle_initial VARCHAR(1),
last_name VARCHAR(30),
address1 VARCHAR(100),
address2 VARCHAR(100),
address3 VARCHAR(100),
city VARCHAR(50),
state VARCHAR(2),
province VARCHAR(50),
postal_code VARCHAR(10),
country_code VARCHAR(3),
gender ENUM('M','F'),
date_of_birth DATE,
alt_phone VARCHAR(10),
email VARCHAR(70),
security_phrase VARCHAR(100),
comments VARCHAR(255),
called_count INT(8) UNSIGNED NOT NULL default '0',
index (phone_number)
);

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

 CREATE TABLE vicidial_log (
uniqueid DOUBLE(18,7) PRIMARY KEY UNIQUE NOT NULL,
lead_id INT(9) UNSIGNED NOT NULL,
list_id INT(8) UNSIGNED,
campaign_id VARCHAR(8),
call_date DATETIME,
start_epoch INT(10) UNSIGNED,
end_epoch INT(10) UNSIGNED,
length_in_sec INT(10),
status VARCHAR(6),
phone_code VARCHAR(10),
phone_number VARCHAR(10),
user VARCHAR(20),
comments VARCHAR(255),
processed ENUM('Y','N'),
index (lead_id),
index (call_date)
);

 CREATE TABLE vicidial_closer_log (
closecallid INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
lead_id INT(9) UNSIGNED NOT NULL,
list_id INT(8) UNSIGNED,
campaign_id VARCHAR(8),
call_date DATETIME,
start_epoch INT(10) UNSIGNED,
end_epoch INT(10) UNSIGNED,
length_in_sec INT(10),
status VARCHAR(6),
phone_code VARCHAR(10),
phone_number VARCHAR(10),
user VARCHAR(20),
comments VARCHAR(255),
processed ENUM('Y','N'),
index (lead_id)
);

 CREATE TABLE vicidial_users (
user_id INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
user VARCHAR(20),
pass VARCHAR(20),
full_name VARCHAR(50),
user_level INT(2),
index (user)
);

 CREATE TABLE vicidial_user_log (
user_log_id INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
user VARCHAR(20),
event VARCHAR(50),
campaign_id VARCHAR(8),
event_date DATETIME,
event_epoch INT(10) UNSIGNED,
index (user)
);

 CREATE TABLE vicidial_campaigns (
campaign_id VARCHAR(8) PRIMARY KEY UNIQUE NOT NULL,
campaign_name VARCHAR(40),
active ENUM('Y','N'),
dial_status_a VARCHAR(6),
dial_status_b VARCHAR(6),
dial_status_c VARCHAR(6),
dial_status_d VARCHAR(6),
dial_status_e VARCHAR(6),
lead_order VARCHAR(20),
park_ext VARCHAR(10),
park_file_name VARCHAR(10),
web_form_address VARCHAR(255),
allow_closers ENUM('Y','N'),
hopper_level ENUM('1','5','10','50','100','200','500') default '1',
auto_dial_level ENUM('0','1','1.1','1.2','1.3','1.4','1.5','1.6','1.7','1.8','1.9','2.0','2.5','3.0') default '0',
next_agent_call ENUM('random','oldest_call_start','oldest_call_finish') default 'oldest_call_start'
);

 CREATE TABLE vicidial_lists (
list_id INT(8) UNSIGNED PRIMARY KEY UNIQUE NOT NULL,
list_name VARCHAR(30),
campaign_id VARCHAR(8),
active ENUM('Y','N')
);

 CREATE TABLE vicidial_statuses (
status VARCHAR(6) PRIMARY KEY UNIQUE NOT NULL,
status_name VARCHAR(30),
selectable ENUM('Y','N')
);

 CREATE TABLE vicidial_conferences (
conf_exten INT(7) UNSIGNED NOT NULL,
server_ip VARCHAR(15) NOT NULL,
extension VARCHAR(20)
);

