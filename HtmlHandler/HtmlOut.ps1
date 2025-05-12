$ProcessSet = Get-Process | Select-Object -First 25 -Property Name,Id,CommandLine,WorkingSet

$HtmlDocHeader = @"
<!DOCTYPE html>
<html>
<head>
<title>$HtmlDocTitle</title>
</head>
<body>
"@

$HtmlTableHeadTemplate = @"
<table>
<thead>
<tr>
<th>ProcessName</th><th>ProcessId</th><th>CommandLine</th><th>WorkingSet</th>
</tr>
</thead>
<tbody>
"@

$HtmlTableRowTemplate = @"
<tr>
<td>$ProcessName</td><td>$ProcessId</td><td>$ProcessCmdLine</td><td>$ProcessWorkingSet</td>
</tr>
"@

$HtmlTableFooterTemplate = @"
</tbody>
<tfoot></tfoot>
</table>
"@