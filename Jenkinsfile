pipeline {

    agent {
        label "linux"
    }
    parameters {
        booleanParam(name: 'TagLatest', defaultValue: false, description: 'Tag this image as latest')
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '30'))
        timestamps()
        disableConcurrentBuilds()
    }
    environment {
        projectName  = "XSA_OCTOPUS"
        deployTo = "sit"
        version = "1.0.0.${env.BUILD_NUMBER}"
        suffix = "${env.GIT_COMMIT}-${env.GIT_BRANCH.replace('/', '-')}"
        packageVersion = "${version}-${suffix}"
        jobName = "XSA_OCTOPUS"
        artifactoryServerId = "artifactory"   
    }

    stages {
        stage ("Stash files") {
            steps {
                stash includes: "*.ps1", name: "RootPSscripts", useDefaultExcludes: false
                stash includes: "src/Cloners/*.ps1", name: "ClonersPSscripts", useDefaultExcludes: false
                stash includes: "src/Core/*.ps1", name: "CorePSscripts", useDefaultExcludes: false
                stash includes: "src/DataAccess/*.ps1", name: "DataAccessPSscripts", useDefaultExcludes: false
            }
        }
        
        stage ("Publish Artifacts") {
            agent {
                docker {
                    image "octopusdeploy/octo"
                    args '--entrypoint=\'\''
                }
		    }
                steps {
                unstash "RootPSscripts"
                unstash "ClonersPSscripts"
                unstash "CorePSscripts"
                unstash "DataAccessPSscripts"
                
                sh "rm -rf dataART.${projectName}.${version}"
                fileOperations([ 
                        fileCopyOperation(
                                flattenFiles: true,
                                includes: "*.ps1",
                                targetLocation: "$WORKSPACE/dataART.${projectName}.${version}/"),
                        fileCopyOperation(
                                flattenFiles: true,
                                includes: "src/Cloners/*.ps1",
                                targetLocation: "$WORKSPACE/dataART.${projectName}.${version}/src/Cloners/"),
                        fileCopyOperation(
                                flattenFiles: true,
                                includes: "src/Core/*.ps1",
                                targetLocation: "$WORKSPACE/dataART.${projectName}.${version}/src/Core/"),
                        fileCopyOperation(
                                flattenFiles: true,
                                includes: "src/DataAccess/*.ps1",
                                targetLocation: "$WORKSPACE/dataART.${projectName}.${version}/src/DataAccess/")])

                sh """ octo pack --id="dataART.${projectName}" --version="${packageVersion}" --basepath="$WORKSPACE/dataART.${projectName}.${version}" --outFolder=$WORKSPACE """
                
                rtUpload(
                    spec: '''{ "files": [
                        {
                            "pattern": "dataART.${projectName}.${packageVersion}.nupkg",
                            "target": "octopus/"
                        }
                    ] }''',
                    buildNumber: "${packageVersion}", buildName: "dataART.${projectName}",
                    serverId: "${artifactoryServerId}"
                )
                rtPublishBuildInfo(buildNumber: "${packageVersion}", buildName: "dataART.${projectName}", serverId: "${artifactoryServerId}")
             }
        }  
        stage ("Octopus sit") {
            agent {
                docker {
                    image "octopusdeploy/octo"
                    args '--entrypoint=\'\''
                }
		    }
            options { skipDefaultCheckout true }
            environment {
                deployTo = "sit"
                releaseversion = "${version}"
                apiKey = credentials("Octopus-Api")
                octopusURL = "https://octopus.azure.dsb.dk"
                hostargs = "--server ${octopusURL} --apiKey ${apiKey} --project ${jobName} --version=${releaseversion}"
            }
            steps {
                addBadge(text: "octopus", icon: "/userContent/octopus_16x16.png", id: "octopus", link: "${octopusURL}/app#/Spaces-1/projects/${jobName}/deployments/releases/${releaseversion}")
                sh """
                    octo create-release  $hostargs --defaultpackageversion=${packageVersion}
                    octo deploy-release $hostargs --deployto=${deployTo} --waitfordeployment --deploymentTimeout=00:20:00
                """
            }
        }        

    }
}