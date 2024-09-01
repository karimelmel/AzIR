"""
This script allows you to run a script on a virtual machine (VM) in Azure, AWS, or GCP.

Usage:
    python run_command.py --vm_name <vm_name> --cloud_provider <cloud_provider> --script_path <script_path> [--resource_group <resource_group>] [--instance_id <instance_id>] [--project <project>] [--zone <zone>] [--subscription_id <subscription_id>]

Arguments:
    --vm_name          : Name of the virtual machine.
    --cloud_provider   : Cloud provider (azure, aws, gcp).
    --script_path      : Path to the PowerShell script.
    --resource_group   : Resource group name (required for Azure).
    --instance_id      : Instance ID (required for AWS).
    --project          : Project ID (required for GCP).
    --zone             : Zone (required for GCP).
    --subscription_id  : Subscription ID (required for Azure).

Examples:
    Azure:
        python run_command.py --vm_name myAzureVM --cloud_provider azure --script_path /path/to/script.ps1 --resource_group myResourceGroup --subscription_id mySubscriptionId

    AWS:
        python run_command.py --vm_name myAWSVM --cloud_provider aws --script_path /path/to/script.ps1 --instance_id i-1234567890abcdef0

    GCP:
        python run_command.py --vm_name myGCPVM --cloud_provider gcp --script_path /path/to/script.ps1 --project my-gcp-project --zone us-central1-a
"""

import argparse
import boto3
import logging
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
from google.cloud import compute_v1

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def run_command_azure(vm_name, resource_group, script_path, subscription_id):
    logging.info(f"Starting Azure command execution for VM: {vm_name}")
    credential = DefaultAzureCredential()
    compute_client = ComputeManagementClient(credential, subscription_id)

    with open(script_path, 'r') as file:
        script_content = file.read()

    run_command_parameters = {
        'command_id': 'RunPowerShellScript',
        'script': [script_content]
    }

    async_run_command = compute_client.virtual_machines.begin_run_command(
        resource_group_name=resource_group,
        vm_name=vm_name,
        parameters=run_command_parameters
    )
    result = async_run_command.result()
    logging.info(f"Azure command execution completed for VM: {vm_name}")
    print(result)

def run_command_aws(instance_id, script_path):
    logging.info(f"Starting AWS command execution for instance: {instance_id}")
    ssm_client = boto3.client('ssm')

    with open(script_path, 'r') as file:
        script_content = file.read()

    response = ssm_client.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunPowerShellScript",
        Parameters={'commands': [script_content]}
    )

    command_id = response['Command']['CommandId']
    output = ssm_client.get_command_invocation(
        CommandId=command_id,
        InstanceId=instance_id,
    )
    logging.info(f"AWS command execution completed for instance: {instance_id}")
    print(output)

def run_command_gcp(instance_name, project, zone, script_path):
    logging.info(f"Starting GCP command execution for instance: {instance_name}")
    client = compute_v1.InstancesClient()

    with open(script_path, 'r') as file:
        script_content = file.read()

    request = compute_v1.SendCommandRequest(
        project=project,
        zone=zone,
        instance=instance_name,
        guest_attributes=compute_v1.GuestAttributes(
            query_path="run-powershell-script",
            query_value=script_content
        )
    )

    operation = client.send_command(request=request)
    logging.info(f"GCP command execution completed for instance: {instance_name}")
    print(operation)

def run_command(vm_name, cloud_provider, script_path, resource_group=None, instance_id=None, project=None, zone=None, subscription_id=None):
    logging.info(f"Running command on {cloud_provider} for VM: {vm_name}")
    if cloud_provider.lower() == 'azure':
        if not resource_group or not subscription_id:
            logging.error("Resource group and subscription ID are required for Azure.")
            return
        run_command_azure(vm_name, resource_group, script_path, subscription_id)
    elif cloud_provider.lower() == 'aws':
        if not instance_id:
            logging.error("Instance ID is required for AWS.")
            return
        run_command_aws(instance_id, script_path)
    elif cloud_provider.lower() == 'gcp':
        if not project or not zone:
            logging.error("Project and zone are required for GCP.")
            return
        run_command_gcp(vm_name, project, zone, script_path)
    else:
        logging.error("Unsupported cloud provider. Please specify 'azure', 'aws', or 'gcp'.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run a PowerShell script on a VM in Azure, AWS, or GCP.")
    parser.add_argument('--vm_name', required=True, help='Name of the virtual machine')
    parser.add_argument('--cloud_provider', required=True, choices=['azure', 'aws', 'gcp'], help='Cloud provider (azure, aws, gcp)')
    parser.add_argument('--script_path', required=True, help='Path to the PowerShell script')
    parser.add_argument('--resource_group', help='Resource group name (required for Azure)')
    parser.add_argument('--instance_id', help='Instance ID (required for AWS)')
    parser.add_argument('--project', help='Project ID (required for GCP)')
    parser.add_argument('--zone', help='Zone (required for GCP)')
    parser.add_argument('--subscription_id', help='Subscription ID (required for Azure)')

    args = parser.parse_args()

    run_command(
        vm_name=args.vm_name,
        cloud_provider=args.cloud_provider,
        script_path=args.script_path,
        resource_group=args.resource_group,
        instance_id=args.instance_id,
        project=args.project,
        zone=args.zone,
        subscription_id=args.subscription_id
    )