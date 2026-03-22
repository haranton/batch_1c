# Автовыгрузка расширения по расписанию (без Jenkins)

## 1) Ручной запуск (проверка)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File src\1c-batch\scripts\dump-extension-and-push.ps1 -ExtensionName "ИМЯ_РАСШИРЕНИЯ" -ExtensionDir "src\cfe\ИМЯ_РАСШИРЕНИЯ"
```

## 2) Регистрация ежедневной задачи
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File src\1c-batch\scripts\register-extension-dump-task.ps1 -TaskName "OneC_ExtensionDump" -At "03:00" -ExtensionName "ИМЯ_РАСШИРЕНИЯ"
```

Если нужен свой каталог выгрузки:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File src\1c-batch\scripts\register-extension-dump-task.ps1 -TaskName "OneC_ExtensionDump" -At "03:00" -ExtensionName "ИМЯ_РАСШИРЕНИЯ" -ExtensionDir "src\cfe\МОЙ_КАТАЛОГ"
```

## 3) Запуск задачи вручную
```powershell
Start-ScheduledTask -TaskName "OneC_ExtensionDump"
```

## 4) Проверка результата
```powershell
Get-ScheduledTaskInfo -TaskName "OneC_ExtensionDump"
```

## 5) Удаление задачи
```powershell
Unregister-ScheduledTask -TaskName "OneC_ExtensionDump" -Confirm:$false
```

## Как работает скрипт
- вызывает `unlock-and-dump-extension.bat`;
- режим выгрузки: `Auto` (первая выгрузка полная, далее инкрементальная);
- если в Git нет изменений, commit/push не делает;
- если изменения есть, делает commit и `git push origin main`.

## Важно
Если в логах ошибка вида `расширение ... не найдено`, значит передано неверное имя `-ExtensionName`.
