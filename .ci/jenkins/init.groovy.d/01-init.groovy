import jenkins.model.Jenkins

Jenkins.instance.setNumExecutors(2)
println("Jenkins init: executors set to 2")
