ALTER TABLE server_performance ADD cpu_user_percent SMALLINT(3) UNSIGNED NOT NULL default '0';
ALTER TABLE server_performance ADD cpu_system_percent SMALLINT(3) UNSIGNED NOT NULL default '0';
ALTER TABLE server_performance ADD cpu_idle_percent SMALLINT(3) UNSIGNED NOT NULL default '0';

