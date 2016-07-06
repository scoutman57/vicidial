<?

# this is the main frame page for the lead loading section. This is where you would upload a file and have it inserted into vicidial_list


$STARTtime = date("U");
$TODAY = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$FILE_datetime = $STARTtime;

	if ( ($PHP_AUTH_USER == 'lead') and ($PHP_AUTH_PW == 'load') ) {$auth=1;}
	else {$auth=0;}

$fp = fopen ("./project_auth_entries.txt", "a");
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICIDIAL-LEAD-LOADER\"");
    Header("HTTP/1.0 401 Unauthorized");
    echo "Invalid Username/Password: |$PHP_AUTH_USER|$PHP_AUTH_PW|\n";
    exit;
	}
  else
	{
	header ("Content-type: text/html; charset=utf-8");
	if($auth>0)
		{
		$office_no=strtoupper($PHP_AUTH_USER);
		$password=strtoupper($PHP_AUTH_PW);
		fwrite ($fp, "LIST_LOAD|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
		fclose($fp);

		}
	else
		{
		fwrite ($fp, "LIST_LOAD|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
		fclose($fp);
		}
	}

?><HTML>
<HEAD>
<TITLE>VICIDIAL: Lead Loader Module</TITLE>
</HEAD>
<FRAMESET ROWS="300,*" border=0>
<FRAME SRC="listloader.php" NAME="main">
<FRAME SRC="count.htm" NAME="lead_count">
</HTML>