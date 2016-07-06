ALTER TABLE vicidial_live_agents ADD call_server_ip VARCHAR(15);

ALTER TABLE vicidial_users ADD phone_login VARCHAR(20);
ALTER TABLE vicidial_users ADD phone_pass VARCHAR(20);
ALTER TABLE vicidial_users ADD delete_users ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD delete_user_groups ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD delete_lists ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD delete_campaigns ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD delete_ingroups ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD delete_remote_agents ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD load_leads ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD campaign_detail ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD ast_admin_access ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD ast_delete_phones ENUM('0','1') default '0';
ALTER TABLE vicidial_users ADD delete_scripts ENUM('0','1') default '0';

 CREATE TABLE vicidial_scripts (
script_id VARCHAR(10) PRIMARY KEY UNIQUE NOT NULL,
script_name VARCHAR(50),
script_comments VARCHAR(255),
script_text TEXT,
active ENUM('Y','N')
);

ALTER TABLE vicidial_campaigns ADD campaign_script VARCHAR(10);
ALTER TABLE vicidial_campaigns ADD get_call_launch ENUM('NONE','SCRIPT','WEBFORM') default 'NONE';

ALTER TABLE vicidial_inbound_groups ADD ingroup_script VARCHAR(10);
ALTER TABLE vicidial_inbound_groups ADD get_call_launch ENUM('NONE','SCRIPT','WEBFORM') default 'NONE';

ALTER TABLE vicidial_campaigns ADD am_message_exten VARCHAR(20);

 CREATE TABLE phone_favorites (
extension VARCHAR(100),
server_ip VARCHAR(15),
extensions_list TEXT
);