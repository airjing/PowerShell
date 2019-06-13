az vm create \
--name Win2016 \
--resource-group da46483e-0712-4f63-ac91-bb9062b5406a \
--image Win2016Datacenter \
--size Standard_DS2_v2 \
--location eastus \
--admin-username azureuser

az vm get-instance-view \
  --name myVM \
  --resource-group da46483e-0712-4f63-ac91-bb9062b5406a \
  --output table

az vm extension set \
  --resource-group e1433d7c-8c66-4099-a1ad-b42db01841d6 \
  --vm-name myVM \
  --name CustomScriptExtension \
  --publisher Microsoft.Compute \
  --settings '{"fileUris":["https://raw.githubusercontent.com/MicrosoftDocs/mslearn-welcome-to-azure/master/configure-iis.ps1"]}' \
  --protected-settings '{"commandToExecute": "powershell -ExecutionPolicy Unrestricted -File configure-iis.ps1"}'
