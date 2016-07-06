ALTER TABLE vicidial_campaigns ADD amd_send_to_vmx ENUM('Y','N') default 'N';
ALTER TABLE vicidial_campaigns ADD xferconf_a_dtmf VARCHAR(50);
ALTER TABLE vicidial_campaigns ADD xferconf_a_number VARCHAR(50);
ALTER TABLE vicidial_campaigns ADD xferconf_b_dtmf VARCHAR(50);
ALTER TABLE vicidial_campaigns ADD xferconf_b_number VARCHAR(50);

ALTER TABLE vicidial_inbound_groups ADD xferconf_a_dtmf VARCHAR(50);
ALTER TABLE vicidial_inbound_groups ADD xferconf_a_number VARCHAR(50);
ALTER TABLE vicidial_inbound_groups ADD xferconf_b_dtmf VARCHAR(50);
ALTER TABLE vicidial_inbound_groups ADD xferconf_b_number VARCHAR(50);

ALTER TABLE vicidial_users ADD modify_leads ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD hotkeys_active ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD change_agent_campaign ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD agent_choose_ingroups ENUM('0','1') default '1';
ALTER TABLE vicidial_users ADD closer_campaigns TEXT;

ALTER TABLE vicidial_campaigns MODIFY next_agent_call ENUM('random','oldest_call_start','oldest_call_finish','overall_user_level') default 'oldest_call_finish';

ALTER TABLE vicidial_inbound_groups MODIFY next_agent_call ENUM('random','oldest_call_start','oldest_call_finish','overall_user_level') default 'oldest_call_finish';

ALTER TABLE vicidial_live_agents ADD user_level INT(2) default '0';

ALTER TABLE vicidial_live_agents MODIFY closer_campaigns TEXT;

ALTER TABLE vicidial_remote_agents MODIFY closer_campaigns TEXT;


 CREATE TABLE vicidial_callbacks (
callback_id INT(9) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
lead_id INT(9) UNSIGNED,
list_id INT(8) UNSIGNED,		
campaign_id VARCHAR(8),			
status VARCHAR(10),
entry_time DATETIME,
callback_time DATETIME,
modify_date TIMESTAMP,
user VARCHAR(20),
recipient ENUM('USERONLY','ANYONE'),	
comments VARCHAR(255),
index (lead_id),
index (status),
index (callback_time)
);


ALTER TABLE vicidial_hopper ADD gmt_offset_now DECIMAL(4,2) DEFAULT '0.00';

ALTER TABLE vicidial_campaigns MODIFY campaign_rec_filename VARCHAR(50) default 'FULLDATE_CUSTPHONE';
