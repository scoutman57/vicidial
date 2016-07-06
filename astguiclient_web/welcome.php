<?

### AST GUI database administration

### welcome.php

$STARTtime = date("U");
$STARTdate = date("Y-m-d H:i:s");

$link=mysql_connect("localhost", "cron", "1234");
mysql_select_db("asterisk");

	$stmt="SELECT count(*) from phones where login='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and active = 'Y';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

$fp = fopen ("./project_auth_entries.txt", "a");
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICI-ASTERISK\"");
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
			$stmt="SELECT fullname from phones where login='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW'";
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGfullname=$row[0];
		fwrite ($fp, "ASTERISK|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
		fclose($fp);
		}
	else
		{
		fwrite ($fp, "ASTERISK|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
		fclose($fp);
		}
	}

?>
<html>
<head>
<title>ASTERISK ADMIN: Welcome</title>
</head>
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>
<CENTER>
<TABLE WIDTH=620 BGCOLOR=#D9E6FE cellpadding=2 cellspacing=0><TR BGCOLOR=#015B91><TD ALIGN=LEFT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B> &nbsp; ASTERISK ADMIN: Welcome</TD><TD ALIGN=RIGHT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B><? echo date("l F j, Y G:i:s A") ?> &nbsp; </TD></TR>
<TR BGCOLOR=#F0F5FE><TD ALIGN=LEFT COLSPAN=2><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1><B> &nbsp; <a href="./lists.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>VIEW LISTS</a> | <a href="./campaigns.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>VIEW CAMPAIGNS</a> | <a href="./admin.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>ADMINISTRATION</a></TD></TR>



<TR><TD ALIGN=CENTER COLSPAN=2 >

<BR><BR>
<B>
WELCOME TO THE ASTERISK ADMIN SYSTEM<br><br>
PLEASE CHOOSE A LINK AT THE TOP TO CONTINUE
</B>
<br><br>&nbsp; 
</TD></TR><TABLE>
</body>
</html>

<?
	
exit; 



?>





