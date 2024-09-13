# Define your API key and the OpenAI API endpoint
$apiKey = 'sk-RRYtvM8sBb27cEbatqq4pv1O_qBOrvFRLE_29NNoJoT3BlbkFJ-RfwNq2mKgnwhPSejoaP3-PMifaKdWZ3GeLoBw8lkA'
$endpoint = "https://api.openai.com/v1/chat/completions"

function prompt-OpenAI
{
param(
    [string]$model = "gpt-4o-mini",
    $prompt,
    $apiKey,
    $filePath
)
$chatInput = @{
    model = $model
    "messages" = @(
        @{
            "role" = "system"
            "content" = "You are an Automation assistant"
        },
        @{
            "role" = "user"
            "content" = $prompt
        }
    )
} | ConvertTo-Json -Depth 3

# Send the request to OpenAI API
$response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type"  = "application/json"
} -Body $chatInput

# Parse and display the response
$chatResponse = $response.choices[0].message.content
write-host "$chatResponse" 
$chatResponse | Out-File -FilePath $filePath
}
prompt-OpenAI -prompt "Export the your response using comma seperated values, with headers `e
, give me a list of beginner azure cloud engineer projects, security engineer projects, Devops projects. `e
Only give the CSV output with no special characters within the prompt" -apiKey $apiKey -filePath .\ITAzureProjects.CSV