<?

### welcome.php

$STARTtime = date("U");
$STARTdate = date("Y-m-d H:i:s");

### modify to suite your MySQL server
$link=mysql_connect("10.0.0.10", "cron", "test");
mysql_select_db("asterisk");

	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 6;";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

$fp = fopen ("/home/www/ssldocs/vici/project_auth_entries.txt", "a");
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICI-PROJECTS\"");
    Header("HTTP/1.0 401 Unauthorized");
    echo "Invalid Username/Password: |$PHP_AUTH_USER|$PHP_AUTH_PW|\n";
    exit;
	}
  else
	{

	if($auth>0)
		{
		$office_no=strtoupper($PHP_AUTH_USER);
		$password=strtoupper($PHP_AUTH_PW);
			$stmt="SELECT full_name from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW'";
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGfullname=$row[0];
		fwrite ($fp, "VICIDIAL|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
		fclose($fp);
		}
	else
		{
		fwrite ($fp, "VICIDIAL|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
		fclose($fp);
		}
	}

?>
<html>
<head>
<title>VICIDIAL ADMIN: Welcome</title>
</head>
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>
<CENTER>
<TABLE WIDTH=620 BGCOLOR=#D9E6FE cellpadding=2 cellspacing=0><TR BGCOLOR=#015B91><TD ALIGN=LEFT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B> &nbsp; VICIDIAL ADMIN: Welcome</TD><TD ALIGN=RIGHT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B><? echo date("l F j, Y G:i:s A") ?> &nbsp; </TD></TR>
<TR BGCOLOR=#F0F5FE><TD ALIGN=LEFT COLSPAN=2><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1><B> &nbsp; <a href="./lists.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>VIEW LISTS</a> | <a href="./campaigns.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>VIEW CAMPAIGNS</a> | <a href="./admin.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>ADMINISTRATION</a></TD></TR>



<TR><TD ALIGN=CENTER COLSPAN=2 >

<BR><BR>
<B>
WELCOME TO THE VICIDIAL ADMIN SYSTEM<br><br>
PLEASE CHOOSE A LINK AT THE TOP TO CONTINUE
</B>
<br><br>&nbsp; 
</TD></TR><TABLE>
</body>
</html>

<?
	
exit; 



?>





