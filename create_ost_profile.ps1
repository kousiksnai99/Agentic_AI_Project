from azure.ai.projects import AIProjectClient
from azure.identity import AzureCliCredential
from azure.ai.agents.models import ListSortOrder

# ---------------------------------------
# Initialize Project and Agent
# ---------------------------------------
project = AIProjectClient(
    credential=AzureCliCredential(),
    endpoint="https://aifoundry-rjteh-ais-swce-poc.services.ai.azure.com/api/projects/aifp-uqqnf-ais-swce-poc"
)

agent = project.agents.get_agent("asst_PJGp1mw7VNLpG0Uwy6ZU7mMW")

# Create a thread (conversation session)
thread = project.agents.threads.create()
print(f"✅ Connected. Conversation thread created: {thread.id}")
print("💬 You can now chat with your agent. Type 'exit' to quit.\n")


def chat_with_agent(user_message: str):
    """Send user message to Azure Agent and return response."""
    # Send user message
    project.agents.messages.create(
        thread_id=thread.id,
        role="user",
        content=user_message
    )

    # Trigger agent processing
    run = project.agents.runs.create_and_process(
        thread_id=thread.id,
        agent_id=agent.id
    )

    if run.status == "failed":
        return f"❌ Agent run failed: {run.last_error}"

    # Retrieve messages
    messages = list(project.agents.messages.list(
        thread_id=thread.id,
        order=ListSortOrder.ASCENDING
    ))

    # Return the latest assistant response
    for message in reversed(messages):
        if message.role == "assistant" and message.text_messages:
            return message.text_messages[-1].text.value

    return "⚠ No response received from agent."


# ---------------------------------------
# Chat Loop in Terminal
# ---------------------------------------
try:
    while True:
        user_input = input("You: ").strip()
        if user_input.lower() in ["exit", "quit"]:
            print("👋 Ending chat session. Goodbye!")
            break

        response = chat_with_agent(user_input)
        print(f"Agent: {response}\n")

except KeyboardInterrupt:
    print("\n👋 Chat session interrupted. Goodbye!")




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

 
