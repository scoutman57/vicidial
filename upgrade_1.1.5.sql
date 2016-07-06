ALTER TABLE servers ADD asterisk_version VARCHAR(20) default '1.0.8';
ALTER TABLE servers ADD max_vicidial_trunks SMALLINT(4) default '96';
ALTER TABLE servers ADD telnet_host VARCHAR(20) NOT NULL default 'localhost';
ALTER TABLE servers ADD telnet_port INT(5) NOT NULL default '5038';
ALTER TABLE servers ADD ASTmgrUSERNAME VARCHAR(20) NOT NULL default 'cron';
ALTER TABLE servers ADD ASTmgrSECRET VARCHAR(20) NOT NULL default '1234';
ALTER TABLE servers ADD ASTmgrUSERNAMEupdate VARCHAR(20) NOT NULL default 'updatecron';
ALTER TABLE servers ADD ASTmgrUSERNAMElisten VARCHAR(20) NOT NULL default 'listencron';
ALTER TABLE servers ADD ASTmgrUSERNAMEsend VARCHAR(20) NOT NULL default 'sendcron';
ALTER TABLE servers ADD local_gmt TINYINT(2) default '-5';
ALTER TABLE servers ADD voicemail_dump_exten VARCHAR(20) NOT NULL default '85026666666666';
ALTER TABLE servers ADD answer_transfer_agent VARCHAR(20) NOT NULL default '8365';
ALTER TABLE servers ADD ext_context VARCHAR(20) NOT NULL default 'default';

