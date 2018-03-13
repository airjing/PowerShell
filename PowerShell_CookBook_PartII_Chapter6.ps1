# Calculations and Math
#6.1 Perform Simple Arithmetic
# + Addition
# - Subtraction
# * Multiplication
# / Division
# % Modulus
# +=, -=, *=, /=, and %= Assignment variations of the previously listed operators
$result = 0
$result = 3/2
$result
$result = [int] (3/2)
$result
$result = 3/2
[Math]::Truncate($result)

#6.2 Perform Complex Arithmetic
[System.Math]::Abs(-10.6)
[System.Math]::Pow(123,6)
[System.Math]::Sqrt(123)
[System.Math]::Sin([System.Math]::PI /2)
[System.Math]::ASin(1)
function Get-Root($number,$root)
{
    [Math]::Pow($number,1/$root)
}
Get-Root 12345 123

#6.3 Measure Statistical Properties of a list
1..10 | Measure-Object -Average -Sum -Maximum -Minimum
Get-ChildItem | Measure-Object -Property Length -Maximum -Minimum -Sum -Average
Get-ChildItem > output.txt
Get-Content ./output.txt | Measure-Object -Character -Word -Line

$mt = Get-ChildItem | ForEach-Object {$_.LastWriteTime}
$results = $mt | Measure-Object Ticks -Average
$ag = $results.Average
New-Object Datetime $results.Average

#6.4 Work with Numbers as Binary
$hexNumber = 0x10 # hexadecimal by 0x
$hexNumber # output as decimal
[System.Convert]::ToString(1234,2)
[System.Convert]::ToInt32("10010001001",2)
$archive = [System.IO.FileAttributes] "Archive"
attrib +a .\output.txt
Get-ChildItem | Where-Object {$_.Attributes -band $archive} | Select-Object FullName
attrib -a .\output.txt
Get-ChildItem | Where-Object {$_.Attributes -band $archive} | Select-Object FullName

# Possible attributes of a file
#[Enum]::GetNames([System.IO.FileAttributes])
$attributes = [Enum]::GetValues([System.IO.FileAttributes])
$attributes | Select-Object `
@{"Name"="Property";"Expression"={$_}},
@{"Name"="Integer";"Expression"={[int] $_}},
@{"Name"="Hexadecimal";"Expression"={[Convert]::ToString([int] $_, 16) } },
@{"Name"="Binary";"Expression"={[Convert]::ToString([int] $_, 2)}} |
Format-Table -AutoSize

$colors = [Enum]::GetValues([System.ConsoleColor])
$colors | Select-Object `
@{"Name"="Color";"Expression"={$_}},
@{"Name"="Integer";"Expression"={[int] $_}},
@{"Name"="Hexadecimal";"Expression"={[Convert]::ToString([int]$_,16)}},
@{"Name"="Binary";"Expression"={[Convert]::ToString([int] $_, 2)}} |
Format-Table -AutoSize

#6.5 Simplify Math with Administrative Constants
10.18mb / 215kb

#6.6 Convert Numbers Between Bases
$errorCode = 0xFE4A
$errorCode
[System.Convert]::ToInt32("100000000000000000",2)
[System.Convert]::ToInt32("1234",8) # convert an octal number into its decimal representation, supply a base of 8.
[System.Convert]::ToString("1234",16)
"{0:x4}" -f 1234
