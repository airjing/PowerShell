$currentpath = Split-Path -Parent $PSCommandPath
$7z = "E:\Databank\Program Files\7-Zip\7z.exe"
$files= "https://datasets.imdbws.com/name.basics.tsv.gz;https://datasets.imdbws.com/title.akas.tsv.gz;https://datasets.imdbws.com/title.basics.tsv.gz;https://datasets.imdbws.com/title.crew.tsv.gz;https://datasets.imdbws.com/title.episode.tsv.gz;https://datasets.imdbws.com/title.principals.tsv.gz;https://datasets.imdbws.com/title.ratings.tsv.gz"
foreach($f in $files.Split(";"))
{
    $file = $f.split("/")[-1]
    #Invoke-WebRequest -Uri $f -OutFile $currentpath\$file
    & $7z e $file -o"$currentpath\datasource\$file\"
}

