# Export-NSG

Exports NSG files to a CSV file including all rules within that NSG

use:  .\.\Export-NSGRules.ps1 -CsvPathToSave c:\export

thats it.. 

multiple CSV files are created based on <NSG Name>-nsg.csv
  
  can also use -Selectsubscription to select the subscription you want to run it against.. as well as -Login to login to Azure and -ResourceGroup to limit the scope
