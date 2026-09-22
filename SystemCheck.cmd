@echo off
setlocal enabledelayedexpansion

:: Tentukan lokasi direktori penyimpanan laporan (di tempat file .cmd dijalankan)
set "ScriptDir=%~dp0"
if "%ScriptDir%"=="" set "ScriptDir=%CD%"

:: Buat format timestamp untuk nama file
for /f "tokens=2 delims==" %%a in ('wmic OS get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%"
set "YYYY=%dt:~0,4%"
set "MM=%dt:~4,2%"
set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%"
set "Min=%dt:~10,2%"
set "Sec=%dt:~12,2%"
set "Timestamp=%YYYY%%MM%%DD%_%HH%%Min%%Sec%"
set "ReportPath=%ScriptDir%Laporan_Kesehatan_Sistem_%Timestamp%.txt"

:: Fungsi internal untuk mencetak ke Layar dan sekaligus ke File Laporan
> "%ReportPath%" (
    echo ============================================================
    echo  LAPORAN KESEHATAN SISTEM WINDOWS (CMD UNIVERSAL)
    echo ============================================================
    echo Waktu Pengecekan : %DATE% %TIME%
    echo Nama Komputer    : %COMPUTERNAME%
    echo Pengguna Aktif   : %USERNAME%
    echo.
)

call :LogMsg "============================================================"
call :LogMsg " 1. INFORMASI ^& KINERJA CPU"
call :LogMsg "============================================================"
for /f "tokens=*" %%i in ('wmic cpu get Name /value 2^>nul') do (
    echo %%i | findstr /r "=" >nul && call :LogMsg "  - %%i"
)
for /f "tokens=*" %%i in ('wmic cpu get NumberOfCores /value 2^>nul') do (
    echo %%i | findstr /r "=" >nul && call :LogMsg "  - %%i"
)
for /f "tokens=*" %%i in ('wmic cpu get LoadPercentage /value 2^>nul') do (
    echo %%i | findstr /r "=" >nul && call :LogMsg "  - Beban CPU: %%i"
)
call :LogMsg ""

call :LogMsg "============================================================"
call :LogMsg " 2. KAPASITAS ^& PENGGUNAAN RAM"
call :LogMsg "============================================================"
for /f "tokens=*" %%i in ('wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /value 2^>nul') do (
    echo %%i | findstr /r "=" >nul && call :LogMsg "  - %%i"
)
call :LogMsg ""

call :LogMsg "============================================================"
call :LogMsg " 3. KAPASITAS PENYIMPANAN (DISK/SSD)"
call :LogMsg "============================================================"
for /f "tokens=*" %%i in ('wmic logicaldisk where "DriveType=3" get DeviceID,FreeSpace,Size,VolumeName /format:list 2^>nul') do (
    echo %%i | findstr /r "=" >nul && call :LogMsg "  %%i"
)
call :LogMsg ""

call :LogMsg "============================================================"
call :LogMsg " 4. KESEHATAN DISK (STATUS HARDWARE)"
call :LogMsg "============================================================"
for /f "tokens=*" %%i in ('wmic diskdrive get Model,Status,Size /format:list 2^>nul') do (
    echo %%i | findstr /r "=" >nul && call :LogMsg "  %%i"
)
call :LogMsg ""

call :LogMsg "============================================================"
call :LogMsg " 5. STATUS WINDOWS UPDATE (SERVICE CHECK)"
call :LogMsg "============================================================"
sc query wuauserv | findstr /i "STATE" >nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('sc query wuauserv ^| findstr /i "STATE"') do call :LogMsg "  - %%i"
) else (
    call :LogMsg "  - Service Windows Update tidak ditemukan atau dibatasi."
)
call :LogMsg ""

call :LogMsg "============================================================"
call :LogMsg " 6. STATUS ANTIVIRUS ^& KEAMANAN"
call :LogMsg "============================================================"
wmic /namespace:\\root\SecurityCenter2 path AntiVirusProduct get displayName 2>nul | findstr /r /v "^$" >nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('wmic /namespace:\\root\SecurityCenter2 path AntiVirusProduct get displayName 2^>nul') do (
        call :LogMsg "  - Antivirus terdeteksi: %%i"
    )
) else (
    call :LogMsg "  - Tidak ada antivirus pihak ketiga di SecurityCenter2 (Windows Defender aktif)."
)
call :LogMsg ""

call :LogMsg "============================================================"
call :LogMsg " 7. STATUS SERVICE KRITIKAL"
call :LogMsg "============================================================"
for %%s in (W32Time Spooler WSearch WinDefend Audiosrv) do (
    sc query "%%s" 2>nul | findstr /i "STATE" >nul
    if %errorlevel% equ 0 (
        for /f "tokens=*" %%i in ('sc query "%%s" ^| findstr /i "STATE"') do call :LogMsg "  Service: %%s -> %%i"
    ) else (
        call :LogMsg "  Service: %%s tidak ditemukan / tidak aktif."
    )
)
call :LogMsg ""

call :LogMsg "============================================================"
call :LogMsg " 8. STATUS JARINGAN (NETWORK)"
call :LogMsg "============================================================"
ipconfig /ipv4 2>nul | findstr /i "IPv4 Default Gateway" >nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('ipconfig ^| findstr /i "IPv4 Subnet Default"') do call :LogMsg "  %%i"
) else (
    call :LogMsg "  - Gagal mengambil konfigurasi IP melalui ipconfig."
)
call :LogMsg ""

call :LogMsg "============================================================"
call :LogMsg " 9. DAFTAR APLIKASI UTAMA (REGISTRY)"
call :LogMsg "============================================================"
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2>nul | findstr /i "DisplayName" >nul
if %errorlevel% equ 0 (
    call :LogMsg "  - Daftar aplikasi berhasil ditarik dari Registry (Sebagian besar terdaftar)."
    :: Membatasi output agar tidak terlalu panjang di file
    reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2>nul | findstr /i "DisplayName" | findstr /v "ParentKeyName"
) else (
    call :LogMsg "  - Gagal membaca data aplikasi dari registry."
)
call :LogMsg ""

call :LogMsg "============================================================"
call :LogMsg " AKHIR LAPORAN"
call :LogMsg "============================================================"

echo.
echo ============================================================
echo  SUKSES: Laporan berhasil dibuat!
echo  Lokasi File : %ReportPath%
echo ============================================================
pause
goto :eof

:: Subrutin untuk menulis ke layar konsol dan file teks sekaligus
:LogMsg
echo %~1
echo %~1 >> "%ReportPath%"
goto :eof