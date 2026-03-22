# Jenkins в Docker + автовыгрузка расширения 1С

## Что уже настроено
- `docker-compose.jenkins.yml` поднимает Jenkins-контроллер в контейнере.
- При старте применяется JCasC-конфигурация и создаётся job `1c-extension-dump`.
- `Jenkinsfile` содержит cron-триггер, выгрузку расширения и автокоммит в `main`.

## Важно по архитектуре
- Jenkins-контроллер работает в Docker (Linux).
- Выгрузка 1С выполняется на Windows-ноде Jenkins с label `windows-1c`, где установлен `1cv8` и доступен `.1c-devbase.bat`.

## 1. Подготовка переменных
1. Скопируйте `jenkins.env.example` в `jenkins.env`.
2. Заполните `GITHUB_USERNAME` и `GITHUB_TOKEN` (token с правом `repo`).
3. При необходимости смените `JENKINS_ADMIN_ID` / `JENKINS_ADMIN_PASSWORD`.

## 2. Запуск Jenkins
```powershell
docker compose -f docker-compose.jenkins.yml --env-file jenkins.env up -d --build
```

Jenkins будет доступен на `http://localhost:8080`.

## 3. Подключение Windows-ноды `windows-1c`
1. В Jenkins откройте: `Manage Jenkins` -> `Nodes` -> `New Node`.
2. Имя: `windows-1c`, тип: `Permanent Agent`.
3. Добавьте label: `windows-1c`.
4. Remote root directory укажите, например: `C:\Jenkins\workspace`.
5. Launch method: `Launch agent by connecting it to the controller`.
6. На Windows-хосте скачайте `agent.jar` по ссылке из карточки ноды и запустите команду подключения (JNLP), которую покажет Jenkins.

## 4. Что делает job
Job `1c-extension-dump` по расписанию `H 3 * * *`:
1. Клонирует `main`.
2. Выполняет:
```bat
src\1c-batch\scripts\unlock-and-dump-extension.bat "src\cfe\batch_1c" "batch_1c" update
```
3. Если есть изменения — делает commit и push в `main`.

## 5. Ручной запуск
Откройте job `1c-extension-dump` и нажмите `Build Now`.

## 6. Проверка
- В консоли job должен появиться шаг `Dump Extension` без ошибок.
- При изменениях должен появиться commit вида `Автовыгрузка расширения yyyy-MM-dd_HH-mm`.

