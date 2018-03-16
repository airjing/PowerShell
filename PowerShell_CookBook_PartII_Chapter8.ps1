#Utility Tasks
#8.1 Get the System Date and Time
$date = Get-Date
$date.AddDays(1)

#8.2 Measure the Duration of a Command
Measure-Command {Start-Sleep -Milliseconds 330}

#8.3 Read and Write from the Windows Clipboard

#8.4 Generate a Random Number or Object
$suits = "Hearts","Clubs","Spades","Diamonds"
$faces = (2..10) + "A","J","Q","K"
$cards = foreach($suit in $suits)
{
    foreach($face in $faces)
    {
        "$face of $suit"
    }
}
$cards.GetType | Get-Random

1..100 | ForEach-Object {(New-Object System.Random).Next(1,100000)} | Format-Table -AutoSize

#8.5 Program : Search the Windows Start Menu
$startMenuPath = [System.Environment]::GetFolderPath("StartMenu")
$shell = New-Object -ComObject WScript.Shell
$allStartMenu = $shell.SpecialFolders.Item("AllUsersStartMenu")
#$escapedMatch = [Regex]::Escape("$pattern")



#8.6 Program : Show Colorized Script Content
