## 1.1 Initialize the application repositories

You will also need GitHub repositories with the two applications to be deployed. Create a new Git repository (this can be on your physical system, where Git and access to GitHub is already configured). Some starter code is provided in directory [cicd-sample-app](1-cicd/cicd-sample-app/).

1. Copy the starter code from `cicd-sample-app` to some new directory outside this Git repository. Enter the copied directory and initialise it as a Git repository with `git init`. Commit all code (e.g. `git add .; git commit -m "Initial commit of sample application"`).
2. On GitHub, create a new **public** repository and record the URL, probably something like `https://github.com/USER/cicd-sample-app/` (with USER your GitHub username).
3. Link your local repository with the one you created on GitHub: `git remote add origin git@github.com:USER/cicd-sample-app.git` (The GitHub page of your repository will show you the exact command needed for this).
4. Push the locally committed code to GitHub: `git push -u origin main`. Take extra care on this command and the option main. If you receive an error, read the git error message carefully.


Dit is allemaal heel goed verlopen en botste tegen geen enkel probleem.

## 1.2 Download and run the Jenkins Docker image

1. Download the Jenkins image with `docker pull jenkins/jenkins:lts`
2. Start the Jenkins Docker container:

    ```console
    docker run -p 8080:8080 -u root \
      -v jenkins-data:/var/jenkins_home \
      -v $(which docker):/usr/bin/docker \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "$HOME":/home \
      --name jenkins_server jenkins/jenkins:lts
    ```

1. Open a browser tab and point it to <http://172.16.0.10:8080/>. You are asked to enter the administrator password that you recorded in the previous step. Next, Jenkins will ask which plugins you want to have installed. Choose to install the recommended plugins. After this, Jenkins will initialize, which takes some time. You can follow the progress on the web page.
2. When the initialization process finishes, you are redirected to a page that asks you to create an admin user. For now, you can skip this and continue as admin by following the link at the bottom.
3. On the next page, titled "Instance Configuration", just click "Save and Finish" and then "Start using Jenkins".

Docker image pullen en koppelen aan een poort was heel vanzelfsprekend samen met de configuratie, geen problemen gehad en alles verliep vlot.

## 1.3 Use Jenkins to build your application

1. On the Jenkins dashboard, click "Create a new job". Enter a suitable name, e.g. *BuildSampleApp*. Select a "Freestyle project" as job type.
2. The following page allows you to configure the new job. There are a lot of options, so you may be overwhelmed at first.
    - Optionally, enter a description
    - In the section "Source Code Management", select the radio button "Git" and enter the https-URL to your GitHub project, `https://github.com/USER/cicd-sample-app.git`
    - Since your repository is public it is not necessary to enter credentials.
    - The branch to be built should be `*/main` instead of the default `*/master`
    - In the section "Build Steps", click "Add a build step" and select "Execute shell" from the dropdown list. enter `bash ./sample-app.sh`
    - Click "Save". You are redirected to the Jenkins dashboard
3. The dashboard shows an overview of all build jobs. Click the job you just created and in the menu on the left, start a new build job (*"Build Now"*).
    - Hopefully, the build succeeds. Use the overview of build attempts to view the console output of the build process to. If the build process failed this is where you can find error messages that can help to determine the cause.
4. Ensure the sample application is running by reloading the appropriate browser tab.
![job maken op jenkins](<../Images/Schermafbeelding 2026-10-19 170826.png>)
![sample app job script](<../Images/Schermafbeelding 2026-10-19 171134.png>)

![resultaat sample app job](<../Images/Schermafbeelding 2026-10-19 171134.png>)

![checken op welke poort sample app staat](<../Images/Schermafbeelding 2026-10-19 171807.png>)

![sample app dat goed runned](<../Images/Schermafbeelding 2026-10-19 171504.png>)
## 1.4 Add a job to test the application

We will now create another job that runs an acceptance test after the build process has finished.

Before you begin, you need to know the IP address of both the `sampleapp` and `jenkins_server` container. Find the IP address and ensure that the app is available with `curl http://APP_IP:5050/`. The output should contain a line with the client's IP address:

```text
   <h1>You are calling me from 172.16.0.10</h1>
```

Remark that 172.16.0.10 is the IP address of the Docker host, i.e. your `infra010` VM. Our acceptance test will consist of running the curl command from the Jenkins server, which will have a different IP address.

1. On the Jenkins dashboard, click "Create a new job". Enter a suitable name, e.g. *TestSampleApp*. Select a "Free  style project" as job type. Optionally, add a description.
2. Under section "Build Triggers", select checkbox "Build after other projects are built". In the text field "Projects to watch", enter the name of the build job.
3. Under section "Build steps", add a build step of type "Execute shell". Enter the following code:

    ```bash
    curl http://APP_IP:5050/ | grep "You are calling me from JENKINS_IP"
    ```

    replacing `APP_IP` and `JENKINS_IP` with the appropriate IP addresses.
4. Save and run the job to verify if it succeeds

    Jenkins can determine whether the job succeeded or failed using the exit status of the command given. When `grep` finds a matching line in the standard output of `curl`, it will finish with exit status 0 (indicating success). If not, it will have exit status 1 (indicating failure). If the command returns a nonzero exit status, it will consider the job to be failed.

    Remark that this is not exactly a full-fledged acceptance test. In a real-life application, you would probably launch a test suite that has to be installed on the Jenkins server.

    You could write a bash script that's a bit more useful than the command specified above. For example, if the job fails, the console output will not give you any clue as to why. In case of a failure to find the expected IP address in the output of `curl`, you could print the actual output on the console.

5. The Jenkins dashboard should now list both the build and test job. Stop and remove the `samplerunning` container and then launch the build job. If you encounter an error try figuring out what is going on. There are multiple ways to tackle this issue either in Jenkins with a correct configuration option or by carefully improving the sample-app.sh script.

## 1.5 Create a build pipeline

The build process in a real-life application is usually much more complex. A full-fledged Continuous Integration/Delivery (CI/CD) pipeline will usually consist of more steps than the ones discussed here (e.g. linting, static code analysis, unit tests, integration tests, acceptance tests, performance tests, packaging and deployment in a production environment). This lab assignment, probably your first encounter with a CI/CD tool is a bit simpler, but should give you an idea of what's possible.

In the next step, we will set up a complete build pipeline that, if the build and test steps succeed, will launch your application as a Docker container.

1. Go to the Jenkins dashboard and create a new item. Enter an appropriate name (e.g. SampleAppPipeline) and select "Pipeline" as job type. Press OK.
2. Optionally, enter a description and in the Pipeline section, enter the following code:

    ```text
    node {
        stage('Preparation') {
            catchError(buildResult: 'SUCCESS') {
                sh 'docker stop samplerunning'
                sh 'docker rm samplerunning'
            }
        }
        stage('Build') {
            build 'BuildSampleApp'
        }
        stage('Results') {
            build 'TestSampleApp'
        }
    }
    ```

    This build pipeline consists of 3 stages:

    - The container currently running is stopped and removed
    - The build job is launched
    - The acceptance job is launched

    Be sure to enter the correct names of the jobs if you have chosen your own names! Finally, save the pipeline.
3. Next, start a build. Jenkins will show you how each phase of the pipeline progresses. Check the console output of each phase.
4. If the run succeeds, the application should be running. Verify by opening it in a web browser.
## 1.6 Use a Jenkinsfile

You can automate the configuration of the build pipeline by adding a `Jenkinsfile` to the root of the application Git repository. For this case, you can use the code for the the pipeline definition in the previous step. Add the jenkinsfile to the root of the Git repository, remove the pipeline from the Jenkins dashboard, create a new pipeline for the Git repository and launch it. The pipeline should run as before!
![pipeline script sample app](<../Images/Schermafbeelding 2026-10-19 172301.png>)

Jenkinsfile:
	node {

    stage('Preparation') {
        catchError(buildResult: 'SUCCESS') {
            sh 'docker stop samplerunning'
            sh 'docker rm samplerunning'
        }
    }
	}
    stage('Build') {
        build job: 'BuildSampleApp'
    }
    stage('Results') {
        build job: 'TestSampleApp'
    }

![resultaat sample app job](<../Images/Schermafbeelding 2026-10-19 172548.png>)


## 1.7 Make a change in the application

In this final step, we will make a change in the application, re-launch the build pipeline and view the result in the browser.

1. Go to your local copy of the Git repository with the sample application. Open file `static/style.css` and change the page background color from "lightsteelblue" into whatever you want.
2. Save the file, commit your changes and push them to GitHub.
3. In the Jenkins dashboard, launch the build pipeline.
4. Reload the application in the web browser, it should have a different background colour now!
![aanpassing sample app](<../Images/Schermafbeelding 2026-10-19 173109.png>)

![Sample app met andere kleur](<../Images/Schermafbeelding 2026-10-19 173416.png>)

## 1.8 Create a build pipeline for a .Net application

The steps above should have given you a good idea of how to set up a build pipeline for a simple application. Now do the same for one of the following .Net applications:

- A demo todo application with a MariaDB backend: <https://github.com/HoGentTIN/dotnet-demo-app>
- The RISE project template application: <https://github.com/HOGENT-RISE/2526-dotnet-template>. It has a SQLite backend by default, but you can change it to a different database backend.

Build instructions can be found in the README file of the GitHub repository.

In vergelijking met de cicd-sampleapp, had ik met de .NET todo-app een groter probleem waarvoor ik grote omweg moest nemen om het op te lossen. Bij het bouwen van de pipeline lukte het niet om 'docker compose-up' te doen, de container waar jenkins op staat kende het commando niet waardoor de builds continu faalden. De oplossing was om op de jenkins container, de compose plugin te installeren samen met dezelfde plugin op jenkins zelf.

- In de jenkinscontainer
	 docker exec -u root jenkins_server bash -c '
	mkdir -p /usr/local/lib/docker/cli-plugins &&
	curl -SL https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-linux-x86_64 \
	  -o /usr/local/lib/docker/cli-plugins/docker-compose &&
	chmod +x /usr/local/lib/docker/cli-plugins/docker-compose'

- Op jenkins: (settings -> plugins -> available plugins)
![plugin op jenkins](<../Images/Schermafbeelding 2026-10-19 174622.png>)

- Pipeline script .NET app:
	pipeline {
    agent any
    stages {
        stage('Preparation') {
            steps {
                git url: 'https://github.com/lil-monkeyy/dotnet-demo-app.git', branch: 'main',
                credentialsId: '5a6a802e-3a3f-46df-afd2-6fd471788307'
            }
        }
        stage('Build') {
            steps {
                  sh 'docker compose up -d --build'
	            }
	        }
	    }
	}

De url en credentials verwijzen naar mijn github repo van deze applicatie, aangezien het een private repo is, heb ik credentials moeten instellen op jenkins en een token gemaakt op github. In de github repo staat een docker-compose.yml dat de applicatie maakt.
![.NETapp job dat succes levert](<../Images/Schermafbeelding 2026-10-19 175837.png>)

![Todo-App result](<../Images/Schermafbeelding 2026-10-19 180037.png>)

Na het runnen van de job wordt de containers met de app en database aangemaakt, als je surft naar de juiste poort zie je dat de app werkt en je todo's kan toevoegen, doorkruisen en verwijderen.