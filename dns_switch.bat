@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul


:: Created by andreytokaref

:: ====================================================================
:: НАСТРОЙКИ (при необходимости измените под себя)
:: ====================================================================
set "INTERFACE_NAME=Беспроводная сеть"        :: Имя сетевого подключения (см. ниже как узнать)
set "DNS1=111.88.96.50"
set "DNS2=111.88.96.51"
set "DOH_TEMPLATE=https://xbox-dns.ru/dns-query"

:: ====================================================================
:: ПРОВЕРКА ПРАВ АДМИНИСТРАТОРА
:: ====================================================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Ошибка: Скрипт нужно запускать от имени Администратора!
    echo Нажмите правой кнопкой мыши по файлу и выберите "Запуск от имени администратора".
    pause
    exit /b 1
)

:: ====================================================================
:: МЕНЮ
:: ====================================================================
:MENU
cls
echo ==================================================
echo          Управление частным DNS (DoH)
echo ==================================================
echo.
echo   Текущее имя интерфейса: %INTERFACE_NAME%
echo.
echo   [1] Включить частный DNS (Static + DoH)
echo   [2] Переключить на Авто (DHCP)
echo   [3] Выход
echo.
set /p choice="Сделайте выбор (1-3): "

if "%choice%"=="1" goto ENABLE_DNS
if "%choice%"=="2" goto RESET_DHCP
if "%choice%"=="3" exit /b 0
echo Неверный ввод. Попробуйте снова.
timeout /t 2 >nul
goto MENU

:: ====================================================================
:: ВКЛЮЧЕНИЕ ЧАСТНОГО DNS И DoH
:: ====================================================================
:ENABLE_DNS
cls
echo [*] Настройка статического DNS...

:: Удаляем старые статические настройки
netsh interface ip set dns name="%INTERFACE_NAME%" source=static address=none >nul 2>&1

:: Устанавливаем первый (основной) DNS
netsh interface ip set dns name="%INTERFACE_NAME%" source=static address=%DNS1% register=primary validate=no >nul

:: Добавляем второй (резервный) DNS
netsh interface ip add dns name="%INTERFACE_NAME%" address=%DNS2% index=2 validate=no >nul

echo [*] Настройка протокола DNS-over-HTTPS (DoH)...
echo [*] Регистрация серверов DoH...

:: Добавляем настройки шифрования для первого DNS
netsh dnsclient add encryption server=%DNS1% dohtemplate=%DOH_TEMPLATE% autoupgrade=yes udpfallback=no >nul 2>&1

:: Добавляем настройки шифрования для второго DNS
netsh dnsclient add encryption server=%DNS2% dohtemplate=%DOH_TEMPLATE% autoupgrade=yes udpfallback=no >nul 2>&1

:: Включаем глобальный DoH (auto - использовать для распознанных серверов)
netsh dnsclient set global doh=auto >nul 2>&1

echo.
echo [+] Настройки применены!
echo     DNS: %DNS1%, %DNS2%
echo     DoH: %DOH_TEMPLATE%
ipconfig /flushdns >nul
echo.
pause
goto MENU

:: ====================================================================
:: СБРОС НА АВТО (DHCP)
:: ====================================================================
:RESET_DHCP
cls
echo [*] Переключение на автоматическое получение DNS...

:: Удаляем настройки шифрования для наших серверов (чтобы не мешали)
netsh dnsclient delete encryption server=%DNS1% >nul 2>&1
netsh dnsclient delete encryption server=%DNS2% >nul 2>&1

:: Удаляем статические DNS и ставим DHCP
netsh interface ip set dns name="%INTERFACE_NAME%" source=dhcp >nul

:: Сбрасываем глобальный DoH (если он был включен принудительно)
netsh dnsclient set global doh=no >nul 2>&1

echo.
echo [+] DNS переключен на Авто (DHCP)!
ipconfig /flushdns >nul
echo.
pause
goto MENU
