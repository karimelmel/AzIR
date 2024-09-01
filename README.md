# AzIr
Azure Incident Response and Collection

### Azure Example
python run_command.py --vm_name myAzureVM --cloud_provider azure --script_path /path/to/script.ps1 --resource_group myResourceGroup --subscription_id 

### AWS Example
python run_command.py --vm_name myAWSVM --cloud_provider aws --script_path /path/to/script.ps1 --instance_id i-1234567890abcdef0

### GCP Example
python run_command.py --vm_name myGCPVM --cloud_provider gcp --script_path /path/to/script.ps1 --project my-gcp-project --zone us-central1-a


# To do
- Rewrite the IR script to check which cloud provider from instance metadata
- Support providing a SAS key for Azure Blob? 