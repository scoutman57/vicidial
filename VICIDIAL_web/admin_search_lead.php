<?

require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
//$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
//$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
//$ADD=$_GET["ADD"];
### AST GUI database administration
### admin_modify_lead.php

# this is the administration lead information modifier screen, the administrator just needs to enter the leadID and then they can view and modify the information in the record for that lead


$STARTtime = date("U");
$TODAY = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$FILE_datetime = $STARTtime;

$ext_context = 'demo';
if (!$begin_date) {$begin_date = $TODAY;}
if (!$end_date) {$end_date = $TODAY;}

#$link=mysql_connect("localhost", "cron", "1234");
#mysql_select_db("asterisk");

	if ( ($PHP_AUTH_USER == 'over') and ($PHP_AUTH_PW == 'ride') ) {$auth=1;}
	else {$auth=0;}

$fp = fopen ("./project_auth_entries.txt", "a");
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICIDIAL-CLOSER\"");
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
		fwrite ($fp, "VD_CLOSER|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
		fclose($fp);

		}
	else
		{
		fwrite ($fp, "VD_CLOSER|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
		fclose($fp);
		}
	}

?>
<html>
<head>
<title>VICIDIAL ADMIN: Lead Search</title>
</head>
<title>Lead Lookup</title>
</head>
<body bgcolor=white>

<? 

if ( (!$vendor_id) and (!$phone)  and (!$lead_id) ) 
	{
	echo date("l F j, Y G:i:s A");
	echo "\n<br><br><center>\n";
	echo "<form method=post name=search action=\"$PHP_SELF\">\n";
	echo "<b>Please enter a:<br> Vendor ID(vendor lead code): <input type=text name=vendor_id size=10 maxlength=10> or \n";
	echo "<br><b>a Home Phone Number: <input type=text name=phone size=10 maxlength=10> or\n";
	echo "<br><b>a lead ID: <input type=text name=lead_id size=10 maxlength=10> <br><br>\n";
	echo "<input type=submit name=submit value=submit></b>\n";
	echo "</form>\n</center>\n";
	echo "</body></html>\n";
	exit;
	}

else
	{

	if ($vendor_id)
		{
		$stmt="SELECT * from vicidial_list where vendor_lead_code='$vendor_id'";
		}
	else
		{
		if ($phone)
			{
			$stmt="SELECT * from vicidial_list where phone_number='$phone'";
			}
		else
			{
			if ($lead_id)
				{
				$stmt="SELECT * from vicidial_list where lead_id='$lead_id'";
				}
			else
				{
				print "ERROR: you must search for something! Go back and search for something";
				exit;
				}
			}
		}
	if (eregi('10.10.10.2',$ip))
		{
		echo "\n\n$stmt\n\n";
		}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	if ( (strlen($row[0]) < 3) && (strlen($row[1]) < 3) )
		{
		echo date("l F j, Y G:i:s A");
		echo "\n<br><br><center>\n";
		echo "<b>The search variables you entered are not active in the system</b><br><br>\n";
		echo "<b>Please go back and double check the information you entered and submit again</b>\n";
		echo "</center>\n";
		echo "</body></html>\n";
		exit;
		}
	else
		{
		echo "\n<PRE>\n\n";
		echo "lead ID: $row[0]\n";
		echo "status: $row[3]\n";
		echo "vendor_id: $row[5]\n";
		echo "last rep called: $row[4]\n";
		echo "list_id: $row[7]\n";
		echo "phone: $row[11]\n";
		echo "Name: $row[13] $row[15]\n";
		echo "City: $row[19]\n";
		echo "Security: $row[28]\n";
		echo "Comments: $row[29]\n\n";
		echo "\n";
		echo "</PRE>\n";
		
	#	https://www.vicimarketing.com/internal/back_end_sys/uk_cust_serv/index.php?person_id=$row[7]&people_packages_id=&secure_lvl=2&display=2&username=$username&passwd=$passwd

		echo "<a href=\"admin_modify_lead.php?lead_id=$row[0]\">Click here to see the Lead Details</a>\n";
		}
	}




$ENDtime = date("U");

$RUNtime = ($ENDtime - $STARTtime);

echo "\n\n\n<br><br><br>\n<a href=\"$PHP_SELF\">NEW SEARCH</a>";


echo "\n\n\n<br><br><br>\nscript runtime: $RUNtime seconds";


?>



</body>
</html>
