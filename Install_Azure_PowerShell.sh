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
