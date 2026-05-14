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
call conda env update -f %YML_FILE% --prune

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
set /p USER_CHOICE=위의 user 계정 pip 패키지들을 삭제하시겠습니까? (Y/N): 

if /I "%USER_CHOICE%"=="Y" (
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
) else (
    echo.
    echo pip user 패키지 삭제를 건너뜁니다
)

echo.
echo ================================
echo 모든 작업이 완료되었습니다!
echo ================================
pause

