ALTER TABLE call_log ADD INDEX(server_ip);
ALTER TABLE call_log ADD INDEX(channel);

ALTER TABLE phones ADD INDEX(server_ip);

 CREATE TABLE vicidial_campaign_statuses (
status VARCHAR(6) PRIMARY KEY UNIQUE NOT NULL,
status_name VARCHAR(30),
selectable ENUM('Y','N'),
campaign_id VARCHAR(8)
);

ALTER TABLE vicidial_inbound_groups ADD fronter_display ENUM('Y','N') default 'Y';

ALTER TABLE vicidial_campaigns ADD campaign_cid VARCHAR(10) default '0000000000';

 CREATE TABLE live_inbound_log (
uniqueid DOUBLE(18,7) NOT NULL,
channel VARCHAR(100) NOT NULL,
server_ip VARCHAR(15) NOT NULL,
caller_id VARCHAR(30),
extension VARCHAR(100),
phone_ext VARCHAR(40),
start_time DATETIME,
acknowledged ENUM('Y','N') default 'N',
inbound_number VARCHAR(20),
comment_a VARCHAR(50),
comment_b VARCHAR(50),
comment_c VARCHAR(50),
comment_d VARCHAR(50),
comment_e VARCHAR(50),
index (uniqueid),
index (phone_ext),
index (start_time)
);

ALTER TABLE live_channels ADD channel_data VARCHAR(100);
ALTER TABLE live_sip_channels ADD channel_data VARCHAR(100);

 CREATE TABLE web_client_sessions (
extension VARCHAR(100) NOT NULL,
server_ip VARCHAR(15) NOT NULL,
program ENUM('agc','vicidial','monitor','other') default 'agc',
start_time DATETIME NOT NULL,
session_name VARCHAR(40) UNIQUE NOT NULL
);

 CREATE TABLE server_performance (
start_time DATETIME NOT NULL,
server_ip VARCHAR(15) NOT NULL,
sysload INT(6) NOT NULL,
freeram SMALLINT(5) UNSIGNED NOT NULL,
usedram SMALLINT(5) UNSIGNED NOT NULL,
processes SMALLINT(4) UNSIGNED NOT NULL,
channels_total SMALLINT(4) UNSIGNED NOT NULL,
trunks_total SMALLINT(4) UNSIGNED NOT NULL,
clients_total SMALLINT(4) UNSIGNED NOT NULL,
clients_zap SMALLINT(4) UNSIGNED NOT NULL,
clients_iax SMALLINT(4) UNSIGNED NOT NULL,
clients_local SMALLINT(4) UNSIGNED NOT NULL,
clients_sip SMALLINT(4) UNSIGNED NOT NULL,
live_recordings SMALLINT(4) UNSIGNED NOT NULL
);

ALTER TABLE vicidial_users ADD user_group VARCHAR(20);

 CREATE TABLE vicidial_user_groups (
user_group VARCHAR(20) NOT NULL,
group_name VARCHAR(40) NOT NULL
);
