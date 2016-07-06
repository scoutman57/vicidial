

UPDATE vicidial_statuses set selectable='Y' where status='NEW';

ALTER TABLE vicidial_campaigns DROP lead_order;
ALTER TABLE vicidial_campaigns ADD lead_order VARCHAR(20);
ALTER TABLE vicidial_campaigns ADD park_ext VARCHAR(10);
ALTER TABLE vicidial_campaigns ADD park_file_name VARCHAR(10);
ALTER TABLE vicidial_campaigns ADD web_form_address VARCHAR(255);
ALTER TABLE vicidial_campaigns ADD allow_closers ENUM('Y','N');

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

