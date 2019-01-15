$json = @"
{
    "firstName": "John",
    "lastName" : "Smith",
    "age"      : 25,
    "address"  :
    {
        "streetAddress": "21 2nd Street",
        "city"         : "New York",
        "state"        : "NY",
        "postalCode"   : "10021"
     },
     "phoneNumber":
     [
         {
            "type"  : "home",
            "number": "212 555-1234"
         },
         {
            "type"  : "fax",
            "number": "646 555-4567"
         }
     ]
 }
"@
[Reflection.Assembly]::LoadFile("C:\Program Files\WindowsPowerShell\Modules\newtonsoft.json\1.0.1.141\libs\Newtonsoft.Json.dll")
$ROOT = $PSCommandPath | Split-Path
$Environments = "$ROOT\Environments.json"
$envs = get-content $Environments
#$js = [Newtonsoft.Json.JsonConvert]::DeserializeObject($envs)
$jenvs = [Newtonsoft.Json.Linq]::JObject.Parse($envs)




