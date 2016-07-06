ALTER table phones MODIFY extension VARCHAR(100);
ALTER table phones MODIFY dialplan_number VARCHAR(20);
ALTER table phones ADD protocol ENUM('SIP','Zap','IAX2','EXTERNAL') default 'SIP';

ALTER table live_sip_channels MODIFY channel VARCHAR(100);
ALTER table live_sip_channels MODIFY extension VARCHAR(100);

ALTER table parked_channels MODIFY extension VARCHAR(100);
ALTER table parked_channels MODIFY parked_by VARCHAR(100);

ALTER table conferences MODIFY extension VARCHAR(100);

ALTER table recording_log MODIFY extension VARCHAR(100);

ALTER table call_log MODIFY extension VARCHAR(100);

ALTER table park_log MODIFY extension VARCHAR(100);

ALTER table vicidial_live_agents MODIFY extension VARCHAR(100);
ALTER table vicidial_live_agents MODIFY conf_exten VARCHAR(20);

ALTER table vicidial_conferences MODIFY extension VARCHAR(100);

ALTER table vicidial_campaigns MODIFY auto_dial_level ENUM('0','1','1.1','1.2','1.3','1.4','1.5','1.6','1.7','1.8','1.9','2.0','2.2','2.5','2.7','3.0','3.2','3.5','3.7','4.0','4.2','4.5','4.7','5.0','5.2','5.5','5.7','6.0') default '1';

GRANT SELECT on asterisk.phones TO idcheck@'%' IDENTIFIED BY '1234';
GRANT SELECT on asterisk.phones TO idcheck@localhost IDENTIFIED BY '1234';

ALTER table phones ADD local_gmt TINYINT(2) default '-5';
ALTER table phones ADD ASTmgrUSERNAME VARCHAR(20) default 'cron';
ALTER table phones ADD ASTmgrSECRET VARCHAR(20) default '1234';
ALTER table phones ADD login_user VARCHAR(20);
ALTER table phones ADD login_pass VARCHAR(20);
ALTER table phones ADD login_campaign VARCHAR(10);
ALTER table phones ADD park_on_extension VARCHAR(10) default '8301';
ALTER table phones ADD conf_on_extension VARCHAR(10) default '8302';
ALTER table phones ADD VICIDIAL_park_on_extension VARCHAR(10) default '8303';
ALTER table phones ADD VICIDIAL_park_on_filename VARCHAR(10) default 'conf';
ALTER table phones ADD monitor_prefix VARCHAR(10) default '8612';
ALTER table phones ADD recording_exten VARCHAR(10) default '8309';
ALTER table phones ADD voicemail_exten VARCHAR(10) default '8501';
ALTER table phones ADD voicemail_dump_exten VARCHAR(20) default '85026666666666';
ALTER table phones ADD ext_context VARCHAR(20) default 'default';
ALTER table phones ADD dtmf_send_extension VARCHAR(100) default 'local/8500998@default';
ALTER table phones ADD call_out_number_group VARCHAR(100) default 'Zap/g2/';
ALTER table phones ADD client_browser VARCHAR(100) default '/usr/bin/mozilla';
ALTER table phones ADD install_directory VARCHAR(100) default '/usr/local/perl_TK';
ALTER table phones ADD local_web_callerID_URL VARCHAR(255) default 'http://astguiclient.sf.net/test_callerid_output.php';
ALTER table phones ADD VICIDIAL_web_URL VARCHAR(255) default 'http://astguiclient.sf.net/test_VICIDIAL_output.php';
ALTER table phones ADD AGI_call_logging_enabled ENUM('0','1') default '1';
ALTER table phones ADD user_switching_enabled ENUM('0','1') default '1';
ALTER table phones ADD conferencing_enabled ENUM('0','1') default '1';
ALTER table phones ADD admin_hangup_enabled ENUM('0','1') default '0';
ALTER table phones ADD admin_hijack_enabled ENUM('0','1') default '0';
ALTER table phones ADD admin_monitor_enabled ENUM('0','1') default '1';
ALTER table phones ADD call_parking_enabled ENUM('0','1') default '1';
ALTER table phones ADD updater_check_enabled ENUM('0','1') default '1';
ALTER table phones ADD AFLogging_enabled ENUM('0','1') default '1';
ALTER table phones ADD QUEUE_ACTION_enabled ENUM('0','1') default '1';
ALTER table phones ADD CallerID_popup_enabled ENUM('0','1') default '1';
ALTER table phones ADD voicemail_button_enabled ENUM('0','1') default '1';
ALTER table phones ADD enable_fast_refresh ENUM('0','1') default '0';
ALTER table phones ADD fast_refresh_rate INT(5) default '1000';
ALTER table phones ADD enable_persistant_mysql ENUM('0','1') default '0';
ALTER table phones ADD auto_dial_next_number ENUM('0','1') default '1';
ALTER table phones ADD VDstop_rec_after_each_call ENUM('0','1') default '1';
ALTER table phones ADD DBX_server VARCHAR(15);
ALTER table phones ADD DBX_database VARCHAR(15) default 'asterisk';
ALTER table phones ADD DBX_user VARCHAR(15) default 'cron';
ALTER table phones ADD DBX_pass VARCHAR(15) default '1234';
ALTER table phones ADD DBX_port INT(6) default '3306';
ALTER table phones ADD DBY_server VARCHAR(15);
ALTER table phones ADD DBY_database VARCHAR(15) default 'asterisk';
ALTER table phones ADD DBY_user VARCHAR(15) default 'cron';
ALTER table phones ADD DBY_pass VARCHAR(15) default '1234';
ALTER table phones ADD DBY_port INT(6) default '3306';

CREATE TABLE vicidial_stations (
agent_station VARCHAR(10) PRIMARY KEY UNIQUE NOT NULL,
phone_channel VARCHAR(100),
computer_ip VARCHAR(15) NOT NULL,
server_ip VARCHAR(15) NOT NULL,
DB_server_ip VARCHAR(15) NOT NULL,
DB_user VARCHAR(15),
DB_pass VARCHAR(15),
DB_port VARCHAR(6)
);

ALTER TABLE vicidial_list ADD INDEX(list_id);
ALTER TABLE vicidial_list ADD INDEX(called_since_last_reset);
ALTER TABLE vicidial_list ADD INDEX(status);
ALTER TABLE vicidial_list ADD INDEX(gmt_offset_now);

OPTIMIZE TABLE vicidial_list;

ALTER TABLE vicidial_manager ADD INDEX serverstat(server_ip,status);

ALTER TABLE recording_log ADD INDEX(filename);


 CREATE TABLE vicidial_remote_agents (
remote_agent_id INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY UNIQUE NOT NULL,
user_start VARCHAR(20),
number_of_lines TINYINT UNSIGNED default '1',
server_ip VARCHAR(15) NOT NULL,
conf_exten VARCHAR(20),
status ENUM('ACTIVE','INACTIVE') default 'INACTIVE',
campaign_id VARCHAR(8),
closer_campaigns VARCHAR(255)
);

ALTER TABLE vicidial_campaigns ADD dial_timeout TINYINT UNSIGNED default '60';
ALTER TABLE vicidial_campaigns ADD dial_prefix VARCHAR(20) default '9';

