@echo off
chcp 65001 >nul

echo ================================
echo yml 파일 복사 중...
echo ================================
echo 복사 중: \\swschoolavdazfiles002.file.core.windows.net\aias-language\Env\environment_env_aias_test.yml
echo 목적지: C:\work\environment_env_aias_test.yml
copy /Y "\\swschoolavdazfiles002.file.core.windows.net\aias-language\Env\environment_env_aias_test.yml" "C:\work\environment_env_aias_test.yml"
if %errorLevel% neq 0 (
    echo ❌ yml 파일 복사 실패! 네트워크 연결을 확인해주세요.
    pause
    exit /b
)
echo ✓ yml 파일 복사 완료
echo.

:: 관리자 권한으로 실행 여부 확인
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Conda 환경 업데이를 위해 관리자 권한으로 다시 실행합니다. 
    echo 팝업창이 뜨면 예를 눌러주세요.
    powershell -Command "Start-Process -FilePath '%~f0' -Verb runAs"
    exit /b
)

echo ================================
echo 기존 실행중인 Jupyter lab 및 Jupyter notebook을 실행한 Powershell또는 명령 프롬프트를 모두 정지해주세요.
echo ================================

echo 현재 실행중인 python프로그램을 모두 종료합니다.
rem 모든 python.exe 프로세스 종료 및 트리 구조의 자식 프로세스까지 종료
taskkill /F /IM python.exe /T
if %errorlevel% neq 0 (
echo 경고: 종료 대상이 없거나 종료에 실패했습니다. 실행 중인 Python 프로세스가 남아있을 수 있습니다.
) else (
echo ✓ Python 프로세스가 성공적으로 종료되었습니다.
)

chcp 65001 >nul

REM 환경명 설정
SET ENV_NAME=env_aias_test

REM yml 파일 경로 설정 (현재 폴더의 environment.yml 예시)
SET YML_FILE=C:\work\environment_env_aias_test.yml

echo ================================
echo Conda 환경 업데이트 및 user pip 패키지 정리 
echo 시간이 조금 소요될 수 있습니다. 잠시만 기달려 주세요.
echo ================================

echo 1. yml 파일로 환경 업데이트 중 (--prune 옵션 사용)...
echo 환경: %ENV_NAME%
echo yml 파일: %YML_FILE%
echo.
call pip cache purge

echo ================================
echo Conda 기존환경을 삭제합니다.
echo ================================

call conda env remove -n env_aias_test --yes

echo ================================
echo Conda 환경을 Rollback합니다. 잠시만 기다려주세요
echo ================================

REM call conda env update -f %YML_FILE% --prune --yes
call conda env create -f %YML_FILE% --yes

echo.
echo ✓ Conda environment.yml로 환경 업데이트 완료

echo.
echo ================================
echo User 계정 pip 패키지 확인 중...
echo ================================

call conda activate %ENV_NAME%

echo 현재 user 계정에 설치된 pip 패키지들:
python -m pip freeze --user

echo.
echo ================================
echo pip user 계정 패키지 삭제 시작
echo ================================
    
python -m pip freeze --user > temp_user_requirements.txt

for /f "delims=" %%i in (temp_user_requirements.txt) do (
    echo 삭제 중: %%i
    pip uninstall -y %%i
    echo    ✓ 삭제 완료: %%i
    echo.
)
    
del temp_user_requirements.txt
echo ================================
echo ✓ 모든 pip user 패키지 삭제 완료!
echo ================================

echo.
echo ================================
echo 모든 작업이 완료되었습니다!
echo ================================
pause

