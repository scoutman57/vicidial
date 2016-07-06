ALTER table live_channels MODIFY channel VARCHAR(100) NOT NULL;

ALTER table live_channels MODIFY extension VARCHAR(100);

ALTER table live_inbound MODIFY channel VARCHAR(100) NOT NULL;

ALTER table live_inbound MODIFY extension VARCHAR(100);

ALTER table call_log MODIFY channel VARCHAR(100);

ALTER table vicidial_manager MODIFY channel VARCHAR(100);

ALTER table vicidial_manager MODIFY cmd_line_b VARCHAR(100);
ALTER table vicidial_manager MODIFY cmd_line_c VARCHAR(100);
ALTER table vicidial_manager MODIFY cmd_line_d VARCHAR(100);
ALTER table vicidial_manager MODIFY cmd_line_e VARCHAR(100);
ALTER table vicidial_manager MODIFY cmd_line_f VARCHAR(100);
ALTER table vicidial_manager MODIFY cmd_line_g VARCHAR(100);
ALTER table vicidial_manager MODIFY cmd_line_h VARCHAR(100);
ALTER table vicidial_manager MODIFY cmd_line_i VARCHAR(100);
ALTER table vicidial_manager MODIFY cmd_line_j VARCHAR(100);
ALTER table vicidial_manager MODIFY cmd_line_k VARCHAR(100);

ALTER table park_log MODIFY channel VARCHAR(100);

ALTER table parked_channels MODIFY channel VARCHAR(100);

ALTER table recording_log MODIFY channel VARCHAR(100);

ALTER table vicidial_auto_calls MODIFY channel VARCHAR(100);

ALTER table vicidial_live_agents MODIFY channel VARCHAR(100);

