from azure.ai.projects import AIProjectClient
from azure.identity import AzureCliCredential
from azure.ai.agents.models import ListSortOrder
from azure.mgmt.automation import AutomationClient
from datetime import datetime

# ---------------------------------------
# Configuration (Update if needed)
# ---------------------------------------
PROJECT_ENDPOINT = "https://aifoundry-rjteh-ais-swce-poc.services.ai.azure.com/api/projects/aifp-uqqnf-ais-swce-poc"
AGENT_ID = "asst_PJGp1mw7VNLpG0Uwy6ZU7mMW"

AZURE_SUBSCRIPTION_ID = "5e31a9fe-8582-4f44-abd5-0a925d25c818"
AZURE_RESOURCE_GROUP = "aoairg"
AUTOMATION_ACCOUNT = "automationagent"

# ---------------------------------------
# Authenticate using Azure CLI
# ---------------------------------------
credential = AzureCliCredential()

# Azure AI agent client
project = AIProjectClient(
    credential=credential,
    endpoint=PROJECT_ENDPOINT
)

# Azure Automation client
automation_client = AutomationClient(
    credential=credential,
    subscription_id=AZURE_SUBSCRIPTION_ID
)

# Load the agent and start a new chat thread
agent = project.agents.get_agent(AGENT_ID)
thread = project.agents.threads.create()
print(f"✅ Connected to agent. Thread created: {thread.id}")
print("💬 Start chatting. Type 'exit' to quit.\n")


# ---------------------------------------
# Function: Execute Runbook
# ---------------------------------------
def execute_runbook(runbook_name):
    try:
        print(f"⚙ Attempting to start runbook: {runbook_name} ...")
        runbooks = automation_client.runbook.list_by_automation_account(
            AZURE_RESOURCE_GROUP, AUTOMATION_ACCOUNT
        )
        available = [rb.name for rb in runbooks]

        if runbook_name not in available:
            return f"❌ Runbook '{runbook_name}' not found in Azure Automation."

        job_name = f"job_{runbook_name}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        job_params = {
            "runbook": {"name": runbook_name},
            "parameters": {}  # Customize if runbook needs parameters
        }

        job = automation_client.job.create(
            AZURE_RESOURCE_GROUP,
            AUTOMATION_ACCOUNT,
            job_name,
            job_params
        )

        return f"✅ Runbook '{runbook_name}' started successfully.\n🔎 Job ID: {job.job_id}"
    except Exception as e:
        return f"❌ Error executing runbook '{runbook_name}': {str(e)}"


# ---------------------------------------
# Function: Send message to agent
# ---------------------------------------
def chat_with_agent(user_input):
    project.agents.messages.create(
        thread_id=thread.id,
        role="user",
        content=user_input
    )

    run = project.agents.runs.create_and_process(
        thread_id=thread.id,
        agent_id=agent.id
    )

    if run.status == "failed":
        return f"❌ Agent run failed: {run.last_error}"

    messages = list(project.agents.messages.list(
        thread_id=thread.id,
        order=ListSortOrder.ASCENDING
    ))

    # Process last response from agent
    for message in reversed(messages):
        if message.role == "assistant" and message.text_messages:
            response_text = message.text_messages[-1].text.value

            # Try to detect runbook keyword in response
            for word in response_text.split():
                if word.startswith(("Azure_", "Fix_", "Runbook_")):
                    runbook_name = word.replace(",", "").strip()
                    runbook_result = execute_runbook(runbook_name)
                    return f"{response_text}\n\n{runbook_result}"

            return response_text

    return "⚠ No response from agent."


# ---------------------------------------
# Chat Loop
# ---------------------------------------
try:
    while True:
        user_input = input("You: ").strip()
        if user_input.lower() in ["exit", "quit"]:
            print("👋 Exiting chat. Goodbye!")
            break

        response = chat_with_agent(user_input)
        print(f"Agent: {response}\n")

except KeyboardInterrupt:
    print("\n👋 Chat interrupted. Goodbye!")




# =========================================

# Problem 1: Create OST Profile

# =========================================
 
param(

    [string]$ProfileName = "DiagOSTProfile"  # <-- Change this to any profile name

)
 
# Outlook executable registry paths (useful if later we need to launch Outlook)

$regPaths = @(

    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE",

    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE"

)
 
# Outlook profile registry path

$profileRoot = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles"

$newProfilePath = Join-Path $profileRoot $ProfileName
 
try {

    # Ensure Outlook Profiles root exists

    if (-not (Test-Path $profileRoot)) {

        Write-Output "No Outlook profile registry path found. Creating root..."

        New-Item -Path "HKCU:\Software\Microsoft\Office\16.0\Outlook" -Name "Profiles" -Force | Out-Null

    }
 
    # Create new profile if it doesn't exist

    if (-not (Test-Path $newProfilePath)) {

        New-Item -Path $profileRoot -Name $ProfileName -Force | Out-Null

        Write-Output "✅ Profile '$ProfileName' created in registry."

    } else {

        Write-Output "ℹ️ Profile '$ProfileName' already exists."

    }
 
    # List all profiles for confirmation

    $profiles = Get-ChildItem $profileRoot | Select-Object -ExpandProperty PSChildName

    Write-Output "📋 Existing Outlook profiles: $($profiles -join ', ')"
 
    Write-Output "👉 To generate OST, launch Outlook interactively with: outlook.exe /profile $ProfileName"

}

catch {

    Write-Output "❌ Error creating OST profile: $_"

}

 
