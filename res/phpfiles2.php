<?php
//https://ideone.com/e01zat
//$dir = substr(dirname($_SERVER['PHP_SELF']),strlen($_SERVER['DOCUMENT_ROOT']));
$dir = "*";
if (!empty($_GET['path'])) {
	$dir = $_GET['path']."/*";
}
$g = glob($dir);
echo "<h2>Index of ".$dir.":</h2>";
usort($g,function($a,$b) {
    if(is_dir($a) == is_dir($b))
        return strnatcasecmp($a,$b);
    else
        return is_dir($a) ? -1 : 1;
});
 
function printElement ($a) {
	if (is_dir($a)) {
		return '<a href="'.$a.'">'.$a.'/</a> <a href="?path='. $a.'">show</a>';
	}
	else
	{
		return '<a href="'.$a.'">'.$a.'</a>';
	}
}
echo implode("<br>",array_map(function($a) {return printElement($a);},$g));
?>
