$currentpath = Split-Path -Parent $PSCommandPath
$ftitlebasics="E:\Development\IMDB\datasource\title.basics.tsv.gz\data.tsv"
function Get-IMDBSourceFiles {
    
    $7z = "E:\Databank\Program Files\7-Zip\7z.exe"
    $files= "https://datasets.imdbws.com/name.basics.tsv.gz;https://datasets.imdbws.com/title.akas.tsv.gz;https://datasets.imdbws.com/title.basics.tsv.gz;https://datasets.imdbws.com/title.crew.tsv.gz;https://datasets.imdbws.com/title.episode.tsv.gz;https://datasets.imdbws.com/title.principals.tsv.gz;https://datasets.imdbws.com/title.ratings.tsv.gz"
    foreach($f in $files.Split(";"))
    {
        $file = $f.split("/")[-1]
        #Invoke-WebRequest -Uri $f -OutFile $currentpath\$file
        & $7z e $file -o"$currentpath\datasource\$file\"
    }    
}
function Get-Title {
    $titlebasics = Get-Content -Path $ftitlebasics -ReadCount 0
    $titlebasics | Where-Object {$_.titletype -eq "movie" -and $_.startyear -gt "2018"} | Select-Object -First 100
    
}

Get-Title
