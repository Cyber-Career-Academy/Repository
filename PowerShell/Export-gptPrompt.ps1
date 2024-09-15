$endpoint = "https://api.openai.com/v1/chat/completions"
function prompt-OpenAI
{
param(
    [string]$model = "gpt-4o-mini",
    $prompt,
    $api,
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
    "Authorization" = "Bearer $api"
    "Content-Type"  = "application/json"
} -Body $chatInput

# Parse and display the response
$chatResponse = $response.choices[0].message.content
write-host "$chatResponse" 
$chatResponse | Out-File -FilePath $filePath
}
prompt-OpenAI -prompt "Export the your response using comma seperated values, with headers `e
, give me a list of beginner azure cloud engineer projects, security engineer projects, Devops projects. `e
Only give the CSV output with no special characters within the prompt" -api $api -filePath .\ITAzureProjects.CSV