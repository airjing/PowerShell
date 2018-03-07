# ChAPTER 4 Looping and Flow Control
$temperature = 90
if($temperature -lt 0)
{
    "Balmy Canadian Summer"
}
elseif($temperature -le 32)
{
    "Freezing"
}
elseif ($temperature -le 50) 
{
    "Cold"    
}
elseif ($temperature -le 70) 
{
    "Warm"
}
else 
{
    "Hot"
}
$result = if(Get-Process powershell) {"running"} else {"Not running"}
$result

$temperature = 20
switch($temperature)
{
    {$_ -lt 32} {"Below Freezing";break}
    32 {"Exactly Freezing";break}
    {$_ -le 50} {"Cold";break}
    {$_ -le 70} {"Warm";break}
    default {"Hot"}
}
$input = Read-Host "Input"
if($input -contains "Q"){ Write-Host $input}

$LoopDelayMilliseconds = 650
while($true)
{
    $startTime = Get-Date
    & ping www.google.com 
    $endTime = Get-Date
    $loopLength = ($endTime-$startTime).TotalMilliseconds
    $timeRemaining = $LoopDelayMilliseconds - $loopLength
    if($timeRemaining -gt 0)
    {
        Start-Sleep -Milliseconds $timeRemaining
    }
}