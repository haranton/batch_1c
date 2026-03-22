pipeline {
  agent { label 'windows-1c' }

  triggers {
    cron('H 3 * * *')
  }

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    EXTENSION_DIR = 'src\\cfe\\batch_1c'
    EXTENSION_NAME = 'batch_1c'
    GIT_AUTHOR_NAME = 'Jenkins Bot'
    GIT_AUTHOR_EMAIL = 'jenkins-bot@local'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Dump Extension') {
      steps {
        bat 'call src\\1c-batch\\scripts\\unlock-and-dump-extension.bat "%EXTENSION_DIR%" "%EXTENSION_NAME%" update'
      }
    }

    stage('Commit And Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-http', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_TOKEN')]) {
          bat '''
            git config user.name "%GIT_AUTHOR_NAME%"
            git config user.email "%GIT_AUTHOR_EMAIL%"
            git add -A

            git diff --cached --quiet
            if %ERRORLEVEL%==0 (
              echo No changes detected after dump.
              exit /b 0
            )

            for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set TS=%%i
            git commit -m "Автовыгрузка расширения %TS%"
            git push https://%GIT_USERNAME%:%GIT_TOKEN%@github.com/haranton/batch_1c.git HEAD:main
          '''
        }
      }
    }
  }
}
