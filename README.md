# Export-NSG

Exports NSG files to a CSV file including all rules within that NSG

use:  .\.\Export-NSGRules.ps1 -CsvPathToSave c:\export

thats it.. 

multiple CSV files are created based on <NSG Name>-nsg.csv
  
  can also use -Selectsubscription to select the subscription you want to run it against.. as well as -Login to login to Azure and -ResourceGroup to limit the scope


# Credits
original function found on: https://thomasthornton.cloud/2020/02/24/network-security-group-ruleset-to-csv/
