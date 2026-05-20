@echo off
chcp 65001
echo 관리자 권한 확인 중...

:: 관리자 권한 체크 (한 번만)
openfiles >nul 2>&1
if errorlevel 1 (
    echo 관리자 권한이 필요합니다. 재실행합니다...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WorkingDirectory '%~dp0'"
    exit /b
)

:: 4. 크롬/엣지 로컬 네트워크 접근 정책 자동 허용 (www.swschool.net)
echo [1/4] 크롬 로컬 네트워크 접근 정책 자동 허용 (www.swschool.net)...
reg add "HKEY_CURRENT_USER\Software\Policies\Google\Chrome" /v "LocalNetworkAccessAllowedForUrls" /t REG_SZ /d "https://www.swschool.net,*" /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Edge" /v "LocalNetworkAccessAllowedForUrls" /t REG_SZ /d "https://www.swschool.net,*" /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Policies\Google\Chrome" /v "InsecurePrivateNetworkRequestsAllowed" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Edge" /v "InsecurePrivateNetworkRequestsAllowed" /t REG_DWORD /d 1 /f >nul 2>&1
echo ✓ www.swschool.net 로컬 네트워크 권한 팝업 차단 완료

:: 5. 브라우저 종료
echo [2/4] 크롬/엣지 브라우저 종료...
taskkill /IM msedge.exe /F >nul 2>&1
taskkill /IM chrome.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
echo ✓ 완료

:: 6. 브라우저 캐시/쿠키/비밀번호 완전 삭제
echo [3/4] 크롬/엣지 모든 프로필 캐시 삭제 시작...
set "chromeUserData=%LocalAppData%\Google\Chrome\User Data"
set "edgeUserData=%LocalAppData%\Microsoft\Edge\User Data"

for /d %%P in ("%chromeUserData%\*") do (
    if "%%~nxP" NEQ "Crashpad" if "%%~nxP" NEQ "System Profile" (
        echo   크롬 프로필 [%%~nxP] 정리...
        if exist "%%P\Cache" rd /s /q "%%P\Cache" >nul 2>&1
        if exist "%%P\Media Cache" rd /s /q "%%P\Media Cache" >nul 2>&1
        if exist "%%P\GPUCache" rd /s /q "%%P\GPUCache" >nul 2>&1
        if exist "%%P\Application Cache" rd /s /q "%%P\Application Cache" >nul 2>&1
        if exist "%%P\ShaderCache" rd /s /q "%%P\ShaderCache" >nul 2>&1
        if exist "%%P\History" del /q "%%P\History" >nul 2>&1
        if exist "%%P\Cookies" del /q "%%P\Cookies" >nul 2>&1
        if exist "%%P\Web Data" del /q "%%P\Web Data" >nul 2>&1
        if exist "%%P\Preferences" del /q "%%P\Preferences" >nul 2>&1
        if exist "%%P\Site Characteristics Database" del /q "%%P\Site Characteristics Database" >nul 2>&1
        if exist "%%P\Login Data" del /q "%%P\Login Data" >nul 2>&1
    )
)

for /d %%P in ("%edgeUserData%\*") do (
    if "%%~nxP" NEQ "Crashpad" if "%%~nxP" NEQ "System Profile" (
        echo   엣지 프로필 [%%~nxP] 정리...
        if exist "%%P\Cache" rd /s /q "%%P\Cache" >nul 2>&1
        if exist "%%P\Media Cache" rd /s /q "%%P\Media Cache" >nul 2>&1
        if exist "%%P\GPUCache" rd /s /q "%%P\GPUCache" >nul 2>&1
        if exist "%%P\Application Cache" rd /s /q "%%P\Application Cache" >nul 2>&1
        if exist "%%P\ShaderCache" rd /s /q "%%P\ShaderCache" >nul 2>&1
        if exist "%%P\History" del /q "%%P\History" >nul 2>&1
        if exist "%%P\Cookies" del /q "%%P\Cookies" >nul 2>&1
        if exist "%%P\Web Data" del /q "%%P\Web Data" >nul 2>&1
        if exist "%%P\Preferences" del /q "%%P\Preferences" >nul 2>&1
        if exist "%%P\Site Characteristics Database" del /q "%%P\Site Characteristics Database" >nul 2>&1
        if exist "%%P\Login Data" del /q "%%P\Login Data" >nul 2>&1
    )
)

if exist "%edgeUserData%\Local State" del /q "%edgeUserData%\Local State" >nul 2>&1
echo ✓ 모든 브라우저 데이터 삭제 완료

:: 7. RDPClient 자격증명 삭제
echo [4/4] RDPClient 자격증명 검색 및 삭제...
echo ==================================================
cmdkey /list | findstr /i "RDPClient"
echo.
echo 삭제 중...
powershell -NoProfile -Command ^
"$output = cmdkey /list; $lines = $output -split '\r?\n'; foreach ($line in $lines) { if ($line -match '^\s*Target:\s*(.+)$') { $target = $matches[1]; if ($target -match 'RDPClient') { Write-Host ('[삭제] ' + $target); cmdkey /delete:\"$target\" } } }"


@echo off
REM ============================================================
REM  RDP / AVDClientAgent 정리 + RDP 비트맵 캐시 삭제 스크립트
REM  - msrdc.exe, mstsc.exe 등 RDP 관련 프로세스 강제 종료
REM  - MediterraneanWorks AVDClientAgent 서비스 중지
REM  - 현재 사용자 RDP 비트맵 캐시 삭제:
REM    C:\Users\<사용자>\AppData\Local\Microsoft\Terminal Server Client\Cache
REM ============================================================

echo [1/3] 관리자 권한 확인 중...

REM 관리자 권한 체크
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 관리자 권한이 필요합니다. "관리자 권한으로 실행" 후 다시 시도하세요.
    pause
    exit /b 1
)

echo [2/3] RDP 및 AVDClientAgent 프로세스 종료 중...

REM --- RDP / AVD 관련 프로세스 강제 종료 ---
REM 표준 RDP 클라이언트
taskkill /IM mstsc.exe /F /T >nul 2>&1

REM 새 Microsoft Remote Desktop 클라이언트(msrdc 기반)
taskkill /IM msrdc.exe /F /T >nul 2>&1

echo  - mstsc.exe / msrdc.exe 프로세스를 종료했습니다.

REM --- MediterraneanWorks AVDClientAgent 프로세스 종료 ---
REM 프로세스 이름: AvdClientAgent
taskkill /IM AvdClientAgent.exe /F /T >nul 2>&1

echo  -AvdClientAgent.exe 프로세스를 종료했습니다.


echo.
echo [3/3] 현재 사용자 RDP 비트맵 캐시 삭제 중...

REM 현재 로그인 사용자 기준 비트맵 캐시 폴더
set "RDP_CACHE_PATH=%LOCALAPPDATA%\Microsoft\Terminal Server Client\Cache"

if exist "%RDP_CACHE_PATH%" (
    echo  - 캐시 폴더 삭제: "%RDP_CACHE_PATH%"
    rmdir /S /Q "%RDP_CACHE_PATH%"
) else (
    echo  - 캐시 폴더가 존재하지 않습니다: "%RDP_CACHE_PATH%"
)

echo.
echo [1/5] 프록시 자동 검색 끄는 중...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect /t REG_DWORD /d 0 /f >nul
echo 완료

echo.
echo [2/5] 설정 스크립트 사용 끄는 중...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /f >nul 2>&1
echo 완료

echo.
echo [3/5] 프록시 서버 사용 끄는 중...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
echo 완료

echo.
echo [4/5] WinHTTP 프록시 초기화 중...
netsh winhttp reset proxy >nul 2>&1
echo 완료

echo.
echo [5/5] Windows 방화벽(도메인/개인/공용) 끄는 중...
netsh advfirewall set allprofiles state off >nul
echo 완료

echo.
echo [결과 확인]
echo --- AutoDetect ---
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect

echo.
echo --- AutoConfigURL ---
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL

echo.
echo --- ProxyEnable ---
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable

echo.
echo --- WinHTTP Proxy ---
netsh winhttp show proxy

echo.
echo --- Firewall Profiles ---
netsh advfirewall show allprofiles


echo.
echo ==================================================
echo ✓ 프록시, 방화벽 포함 모든 작업 완료!
echo ==================================================

pause
