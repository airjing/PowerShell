$path = "D:\;E:\VHD;F:\"
foreach ($a in $path.Split(";"))
{
    $files += Get-ChildItem $a -ErrorAction SilentlyContinue
    Write-Host $a, $files.Count
}
Write-Host $files.Count


foreach ($p in $($LabConfig.VHDStore).Split(";"))
{
    $ParentDisks += Get-ChildItem "p\ParentDisks" -ErrorAction SilentlyContinue -Include "*.vhdx" -Recurse
    if ($ParentDisks -ne $null)
    {
        WriteInfo "Find VHD template $ParentDisks in $p"
        exit
    }
    else
    {
        WriteInfo "Cannot find VHD template in $p"

    }
}


#Start Log



