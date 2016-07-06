 CREATE TABLE vicidial_list_pins (
pins_id INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
entry_time DATETIME,
phone_number VARCHAR(10),
lead_id INT(9) UNSIGNED,
campaign_id VARCHAR(20),			
product_code VARCHAR(20),
user VARCHAR(20),
digits VARCHAR(20),
index (lead_id),
index (phone_number),
index (entry_time)
);

UPDATE vicidial_phone_codes set DST='Y', DST_range='FSA-LSO' where state='IN';

ALTER TABLE vicidial_list MODIFY list_id BIGINT(14) UNSIGNED;
ALTER TABLE vicidial_lists MODIFY list_id BIGINT(14) UNSIGNED;
ALTER TABLE vicidial_hopper MODIFY list_id BIGINT(14) UNSIGNED NOT NULL;
ALTER TABLE vicidial_log MODIFY list_id BIGINT(14) UNSIGNED;
ALTER TABLE vicidial_closer_log MODIFY list_id BIGINT(14) UNSIGNED;
ALTER TABLE vicidial_xfer_log MODIFY list_id BIGINT(14) UNSIGNED;
ALTER TABLE vicidial_callbacks MODIFY list_id BIGINT(14) UNSIGNED;

 CREATE TABLE vicidial_lead_filters (
lead_filter_id VARCHAR(10) PRIMARY KEY NOT NULL,
lead_filter_name VARCHAR(30) NOT NULL,
lead_filter_comments VARCHAR(255),
lead_filter_sql TEXT
);

ALTER TABLE vicidial_campaigns ADD alt_number_dialing ENUM('Y','N') default 'N';
ALTER TABLE vicidial_campaigns ADD scheduled_callbacks ENUM('Y','N') default 'N';
ALTER TABLE vicidial_campaigns ADD lead_filter_id VARCHAR(10) default 'NONE';

ALTER TABLE vicidial_users ADD scheduled_callbacks ENUM('0','1') default '1';
ALTER TABLE vicidial_users ADD agentonly_callbacks ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD agentcall_manual ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD vicidial_recording ENUM('0','1') default '1';
ALTER TABLE vicidial_users ADD vicidial_transfers ENUM('0','1') default '1';
ALTER TABLE vicidial_users ADD delete_filters ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD alter_agent_interface_options ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD closer_default_blended ENUM('0','1') default '0';
