# Stop all services for Spring Boot Learning Kit
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 正在停止 Spring Boot Learning Kit 全套服务..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. 停止运行中的 Spring Boot 应用（释放 8080 端口）
Write-Host "`n[1/3] 检查并关闭占用 8080 端口的应用进程..." -ForegroundColor Yellow
$port8080 = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($port8080) {
    foreach ($pidNum in $port8080) {
        try {
            $p = Get-Process -Id $pidNum -ErrorAction SilentlyContinue
            if ($p) {
                Write-Host "  正在终止进程 $($p.ProcessName) (PID: $pidNum)..." -ForegroundColor White
                Stop-Process -Id $pidNum -Force -ErrorAction SilentlyContinue
                Write-Host "  ✓ 进程 $pidNum 已终止" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ! 无法停止 PID ${pidNum}: $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ✓ 8080 端口未被占用" -ForegroundColor Green
}

# 2. 停止 Gradle 后台守护进程（释放文件锁）
Write-Host "`n[2/3] 停止 Gradle 守护进程..." -ForegroundColor Yellow
try {
    if (Test-Path "$PSScriptRoot\gradlew.bat") {
        & "$PSScriptRoot\gradlew.bat" --stop | Out-Null
        Write-Host "  ✓ Gradle Daemons 已停止" -ForegroundColor Green
    }
} catch {
    Write-Host "  ! 停止 Gradle 失败: $_" -ForegroundColor Red
}

# 3. 停止 Docker Compose 容器（PostgreSQL、RabbitMQ、ActiveMQ）
Write-Host "`n[3/3] 停止 Docker 容器..." -ForegroundColor Yellow
try {
    Set-Location $PSScriptRoot
    docker compose down
    Write-Host "  ✓ 所有 Docker 容器已停止" -ForegroundColor Green
} catch {
    Write-Host "  ! 执行 docker compose down 失败: $_" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " 所有服务已成功停止！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
