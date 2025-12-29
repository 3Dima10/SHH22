# ================================
# Windows OpenSSH setup (SAFE)
# Run as Administrator
# ================================

Write-Host "[*] Installing OpenSSH Server..." -ForegroundColor Cyan

# Установка OpenSSH Server (если не установлен)
$cap = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($cap.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
}

Write-Host "[*] Enabling and starting sshd service..." -ForegroundColor Cyan

# Включаем и запускаем службу
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

# Разрешаем SSH в брандмауэре
Write-Host "[*] Configuring firewall..." -ForegroundColor Cyan
if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule `
        -Name "OpenSSH-Server-In-TCP" `
        -DisplayName "OpenSSH Server (sshd)" `
        -Enabled True `
        -Direction Inbound `
        -Protocol TCP `
        -Action Allow `
        -LocalPort 22
}

# Минимальный корректный sshd_config
Write-Host "[*] Writing sshd_config..." -ForegroundColor Cyan

$configPath = "C:\ProgramData\ssh\sshd_config"

@"
Port 22
Protocol 2

PasswordAuthentication yes
PubkeyAuthentication yes

Subsystem sftp sftp-server.exe
"@ | Set-Content -Path $configPath -Encoding ascii -Force

# Перезапуск службы
Write-Host "[*] Restarting sshd..." -ForegroundColor Cyan
Restart-Service sshd

# Проверка порта
Write-Host "[*] Checking port 22..." -ForegroundColor Cyan
netstat -ano | findstr :22

# Показ IP
Write-Host "`n[*] SSH is ready!" -ForegroundColor Green
$ips = Get-NetIPAddress | Where-Object {
    $_.AddressFamily -eq "IPv4" -and $_.IPAddress -ne "127.0.0.1"
} | Select-Object -ExpandProperty IPAddress

foreach ($ip in $ips) {
    Write-Host "ssh $env:USERNAME@$ip" -ForegroundColor Yellow
}

Write-Host "`n[!] SSH открыт только для локальной сети. Для интернета — нужна доп. защита." -ForegroundColor Red
