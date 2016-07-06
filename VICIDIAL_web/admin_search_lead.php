<?
### admin_search_lead.php
### 
### Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
###

require("dbconnect.php");

$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
$PHP_SELF=$_SERVER['PHP_SELF'];
if (isset($_GET["vendor_id"]))				{$vendor_id=$_GET["vendor_id"];}
	elseif (isset($_POST["vendor_id"]))		{$vendor_id=$_POST["vendor_id"];}
if (isset($_GET["phone"]))				{$phone=$_GET["phone"];}
	elseif (isset($_POST["phone"]))		{$phone=$_POST["phone"];}
if (isset($_GET["lead_id"]))				{$lead_id=$_GET["lead_id"];}
	elseif (isset($_POST["lead_id"]))		{$lead_id=$_POST["lead_id"];}
if (isset($_GET["submit"]))				{$submit=$_GET["submit"];}
	elseif (isset($_POST["submit"]))		{$submit=$_POST["submit"];}
if (isset($_GET["SUBMIT"]))				{$SUBMIT=$_GET["SUBMIT"];}
	elseif (isset($_POST["SUBMIT"]))		{$SUBMIT=$_POST["SUBMIT"];}

### AST GUI database administration search for lead info
### admin_modify_lead.php

# this is the administration lead information modifier screen, the administrator just needs to enter the leadID and then they can view and modify the information in the record for that lead


$STARTtime = date("U");
$TODAY = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");


	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 7;";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

if ($WeBRooTWritablE > 0)
	{$fp = fopen ("./project_auth_entries.txt", "a");}

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
			$stmt="SELECT full_name,modify_leads from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW'";
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGfullname				=$row[0];
			$LOGmodify_leads			=$row[1];

		if ($WeBRooTWritablE > 0)
			{
			fwrite ($fp, "VICIDIAL|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
			fclose($fp);
			}
		}
	else
		{
		if ($WeBRooTWritablE > 0)
			{
			fwrite ($fp, "VICIDIAL|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
			fclose($fp);
			}
		}
	}

?>
<html>
<head>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">
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
	echo "<input type=submit name=submit value=SUBMIT></b>\n";
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
