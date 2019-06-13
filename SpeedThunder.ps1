function main{
    $totalbyte = 0
    while(1 -gt 0)
    {
        $bond0 = Get-NetAdapterStatistics -Name bond0
        $recbyte0 = $bond0.ReceivedBytes
        & "F:\Applications\Thunder Network\Thunder\Program\Thunder.exe"    
        sleep -Seconds 300
        Get-Process "Thunder" | ForEach-Object {Stop-Process $_}
        $bond0 = Get-NetAdapterStatistics -Name bond0
        $recbyte1 = $bond0.ReceivedBytes
        $recbyte = $recbyte1-$recbyte0
        $totalbyte+=$recbyte
        sleep -Seconds 30
        $totalbyteinG = $totalbyte/1GB
        Write-Host "This round totally downloaded $totalbyteinG bytes data"
    }
}
function isProcessIdle{
    param(        
        [Parameter(Mandatory)]
        [string]
        $Process
    )
    $p = Get-Process $Process -ErrorAction SilentlyContinue
    if($p)
    {
        $persamples = Get-counter -Counter "\Process($Process)\IO Read Bytes/sec","\Process($Process)\IO Write Bytes/sec" -SampleInterval 10 -MaxSamples 6
        foreach($p in $persamples)
        {
            foreach($s in $p.CounterSamples)
            {
                $s.Path
                $s.RawValue/1MB
            }
        }
    }
    
}
main