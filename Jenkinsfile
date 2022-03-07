#!groovy

env.BUILD_TAG = "${env.JOB_NAME}-${env.BUILD_NUMBER}".replace('/', '_')

node(label: 'docker') {
    try {

        stage('Checkout') {
            step([$class: 'WsCleanup'])
            checkout scm
            sh('git submodule update --init --remote')
        }

        def BUILD_DATE = sh(returnStdout: true, script: 'date --rfc-3339=seconds').trim()
        def BUILD_TIME = sh(returnStdout: true, script: 'date +%Y%m%d%H%M%S').trim()
        def GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
        def GIT_URL = sh(returnStdout: true, script: 'git remote get-url origin').trim()
        def GIT_TAG = sh(returnStdout: true, script: 'git describe --dirty=+WIP --always').trim()

        IMAGE_LABELS = "--label org.opencontainers.image.created='$BUILD_DATE' " +
            "--label org.opencontainers.image.source='$GIT_URL' " +
            "--label org.opencontainers.image.revision='$GIT_COMMIT' " +
            "--label uk.gov.service.tax.vcs-branch='${env.BRANCH_NAME}' " +
            "--label uk.gov.service.tax.vcs-tag='${GIT_TAG}' " +
            "--label uk.gov.service.tax.build='${env.BUILD_TAG}' "


        stage('build image') {
            ansiColor('xterm') {
                image = docker.build "aws-ecs-kinesis-log-forwarder:${GIT_TAG}-${BUILD_TIME}", IMAGE_LABELS + " ."
            }
        }

        stage('test image') {
            sh("docker run --rm -e ENVIRONMENT=test aws-ecs-kinesis-log-forwarder:${GIT_TAG}-${BUILD_TIME} logstash --config.test_and_exit")
        }

        stage('push to registry') {
            if (env.BRANCH_NAME == "main") {
                sh('aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 419929493928.dkr.ecr.eu-west-2.amazonaws.com')

                sh("docker tag aws-ecs-kinesis-log-forwarder:${GIT_TAG}-${BUILD_TIME} 419929493928.dkr.ecr.eu-west-2.amazonaws.com/aws-ecs-kinesis-log-forwarder:${GIT_TAG}-${BUILD_TIME}")
                sh("docker push 419929493928.dkr.ecr.eu-west-2.amazonaws.com/aws-ecs-kinesis-log-forwarder:${GIT_TAG}-${BUILD_TIME}")
                sh("docker inspect --format='{{index .RepoDigests 0}}' 419929493928.dkr.ecr.eu-west-2.amazonaws.com/aws-ecs-kinesis-log-forwarder:${GIT_TAG}-${BUILD_TIME} > aws-ecs-kinesis-log-forwarder-digest.txt")
                archiveArtifacts 'aws-ecs-kinesis-log-forwarder-digest.txt'
            } else {
                echo "Skipping push as not on main branch"
            }
        }

        stage('build ami') {
            if (env.BRANCH_NAME == "main") {
                build job: 'ami/docker/aws-ami-kinesis-log-forwarder/main',
                    parameters: [
                    string(name: 'docker_image_tag', value: "${GIT_TAG}-${BUILD_TIME}")
                ]
            } else {
                echo "Skipping ami build as not on main branch"
            }
        }

    } catch (e) {
        if (env.BRANCH_NAME == "main") {
            snsPublish(topicArn: 'arn:aws:sns:eu-west-2:419929493928:jenkins_build_notifications',
                subject: env.JOB_NAME,
                message: 'Failed',
                messageAttributes: [
                    'BUILD_URL': env.BUILD_URL
                ]
            )
        }
        throw e
    }
}
