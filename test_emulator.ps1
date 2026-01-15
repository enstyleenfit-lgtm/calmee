# Firebase Functions Emulator テスト用スクリプト
# Callable Function: analyzeMealImage

$projectId = "calmee-8011c"
$region = "us-central1"
$functionName = "analyzeMealImage"
$emulatorUrl = "http://127.0.0.1:5001/$projectId/$region/$functionName"

# テスト用の画像URL（仮）
$imageUrl = "https://example.com/test-image.jpg"

# リクエストボディ（Callable Function形式）
# エミュレータのCallable Functionは data フィールドでラップ
$requestBody = @{
    data = @{
        imageUrl = $imageUrl
    }
}
$body = $requestBody | ConvertTo-Json -Depth 10

# ヘッダー
$headers = @{
    "Content-Type" = "application/json"
}

# エミュレータでは認証をバイパスできる場合があるが、認証が必要な場合は以下を追加
# $auth = FirebaseAuth.instance.currentUser
# $idToken = await $auth.getIdToken()
# $headers["Authorization"] = "Bearer $idToken"

try {
    Write-Host "Calling: $emulatorUrl"
    Write-Host "Body: $body"
    Write-Host ""
    
    $response = Invoke-RestMethod -Method Post `
        -Uri $emulatorUrl `
        -Headers $headers `
        -Body $body `
        -ErrorAction Stop
    
    Write-Host "Success!"
    Write-Host "Response: $($response | ConvertTo-Json -Depth 10)"
    
    if ($response.result) {
        $level = $response.result.level
        Write-Host "Level: $level"
    }
} catch {
    Write-Host "Error: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody"
    }
}

