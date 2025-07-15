# Требует запуска от Администратора!
# setup_ssh.ps1

# Установка OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Запуск и настройка службы
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Разрешение порта 22 в брандмауэре
New-NetFirewallRule -Name "OpenSSH-Server" `
    -DisplayName "OpenSSH Server (sshd)" `
    -Enabled True `
    -Direction Inbound `
    -Protocol TCP `
    -Action Allow `
    -LocalPort 22

# Настройка конфигурации SSH для минимальной безопасности
$configFile = "$env:ProgramData\ssh\sshd_config"
(Get-Content $configFile) | ForEach-Object {
    $_ -replace '#PermitRootLogin.*', 'PermitRootLogin yes' `
       -replace '#PasswordAuthentication.*', 'PasswordAuthentication yes' `
       -replace 'Match Group administrators', '#Match Group administrators' `
       -replace 'AuthorizedKeysFile __PROGRAMDATA__', '#AuthorizedKeysFile __PROGRAMDATA__'
} | Set-Content $configFile -Force

# Добавление правила авторизации для всех пользователей
Add-Content $configFile "`n# Allow all users"
Add-Content $configFile "AllowUsers *"

# Перезапуск службы
Restart-Service sshd

# Показать IP-адреса
$ipAddresses = Get-NetIPAddress | Where-Object { 
    $_.AddressFamily -eq 'IPv4' -and $_.IPAddress -ne '127.0.0.1' 
} | Select-Object -ExpandProperty IPAddress

Write-Host "`nSSH сервер настроен!" -ForegroundColor Green
Write-Host "Подключайтесь с помощью:" -ForegroundColor Cyan
foreach ($ip in $ipAddresses) {
    Write-Host "ssh $env:USERNAME@$ip" -ForegroundColor Yellow
}
Write-Host "`nВнимание: Открыт полный доступ без ограничений безопасности!" -ForegroundColor Red