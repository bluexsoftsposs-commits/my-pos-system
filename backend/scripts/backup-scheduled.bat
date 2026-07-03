@echo off
REM Daily backup script for Windows Task Scheduler
REM Author: BluexSofts POS
REM
REM Task Scheduler setup:
REM   1. Open Task Scheduler > Create Basic Task
REM   2. Trigger: Daily at 3:00 AM
REM   3. Action: Start a program
REM      Program: C:\Windows\System32\cmd.exe
REM      Arguments: /c "C:\bluexsofts-pos\backend\scripts\backup-scheduled.bat"
REM      Start in: C:\bluexsofts-pos\backend
REM
REM   Note: Update the paths above to match your actual project location.

cd /d "%~dp0.."
call npm run db:backup >> backups\backup-log.txt 2>&1
echo [%date% %time%] Backup run complete >> backups\backup-log.txt
