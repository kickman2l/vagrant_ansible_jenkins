node("${env.SLAVE}")
{
    tool name: 'Maven_3.3.9'

    stage("Checkout scm")
    {
        checkout scm
    }

    withEnv(["PATH+MAVEN=${tool 'Maven_3.3.9'}/bin"])
    {
        stage("Build")
        {
            sh '''
                echo "Build time: `date`" > src/main/resources/build-info.txt
                echo "Machine name: `hostname` \n" >> src/main/resources/build-info.txt
                echo "User Name: `whoami` " >> src/main/resources/build-info.txt
                echo "GIT URL: `git config --get remote.origin.url`" >> src/main/resources/build-info.txt
                echo "GIT Commit: `git rev-parse HEAD`" >> src/main/resources/build-info.txt
                echo "GIT Branch: `git rev-parse --abbrev-ref HEAD`" >> src/main/resources/build-info.txt
                mvn clean package -DbuildNumber=${BUILD_NUMBER}
            ''';
        }
    }

    stage("Package")
    {
        sh '''
            cd target/
            tar -czf mnt-exam-${BUILD_NUMBER}.tar.gz mnt-exam.war
            cp mnt-exam-${BUILD_NUMBER}.tar.gz ../ansible/playbooks/
            rm mnt-exam-${BUILD_NUMBER}.tar.gz
            '''
    }

    stage("Roll out Dev VM")
    {
        sh '''
            cd ansible/playbooks
            ansible-playbook createvm.yml
        ''';
    }

    stage("Provision VM")
    {
        sh '''
            cd ansible/playbooks
            ansible-playbook provisionvm.yml -i inv
        ''';
    }

    stage("Deploy Artefact")
    {
        sh '''
            cd ansible/playbooks
            tar -zxf mnt-exam-${BUILD_NUMBER}.tar.gz
            ansible-playbook deploy.yml -e artefact=mnt-exam.war -i inv
            rm mnt-exam-${BUILD_NUMBER}.tar.gz
            rm mnt-exam.war
        '''
    }

    stage("Test Artefact is deployed successfully")
    {
        sh '''
            cd ansible/playbooks
            ansible-playbook application_tests.yml -i inv
        '''
    }

}

