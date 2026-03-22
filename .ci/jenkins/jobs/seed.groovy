pipelineJob('1c-extension-dump') {
  description('Scheduled 1C extension dump with auto-commit and push')

  definition {
    cpsScm {
      scm {
        git {
          remote {
            url('https://github.com/haranton/batch_1c.git')
            credentials('github-http')
          }
          branch('*/main')
        }
      }
      scriptPath('Jenkinsfile')
      lightweight(true)
    }
  }
}
