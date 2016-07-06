ALTER TABLE vicidial_campaign_statuses DROP PRIMARY KEY;
ALTER TABLE vicidial_campaign_statuses DROP INDEX status;
ALTER TABLE vicidial_campaign_statuses MODIFY status VARCHAR(6) NOT NULL;

 CREATE TABLE vicidial_campaign_hotkeys (
status VARCHAR(6) NOT NULL,
hotkey VARCHAR(1) NOT NULL,
status_name VARCHAR(30),
selectable ENUM('Y','N'),
campaign_id VARCHAR(8),
index (campaign_id)
);

ALTER TABLE phones ADD outbound_cid VARCHAR(20);
ALTER TABLE phones MODIFY dialplan_number VARCHAR(20);
