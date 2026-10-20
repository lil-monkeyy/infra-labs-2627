# Lab Report: CICD
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

Docker image pullen en koppelen aan een poort was heel vanzelfsprekend samen met de configuratie, geen problemen gehad en alles verliep vlot.

## 1.3 Use Jenkins to build your application

### job maken op jenkins
![job maken op jenkins](<../Images/Schermafbeelding 2026-10-19 170826.png>)

Nadat je Jenkins verteld waar het je repo met het project kan vinden, geef je een commando mee dat hij moet doen. 
Als je een script maakt moet je altijd weten waar je staat in de directory, in mijn geval zit ik in de rootfolder van mijn gitrepi. Ik verwijs naar een shell script dat staat op een andere folder en daarvoor zet ik 'bash' om het shell script te runnen. Dit gaat dan de sample app bouwen in python en in een container zetten op docker

###resultaat sample app job
![resultaat sample app job](<../Images/Schermafbeelding 2026-10-19 171134.png>)

### checken op welke poort sample app staat
![checken op welke poort sample app staat](<../Images/Schermafbeelding 2026-10-19 171807.png>)

### sample app dat goed runned
![sample app dat goed runned](<../Images/Schermafbeelding 2026-10-19 171504.png>)

## 1.4 Add a job to test the application

Before you begin, you need to know the IP address of both the `sampleapp` and `jenkins_server` container. Find the IP address and ensure that the app is available with `curl http://APP_IP:5050/`. The output should contain a line with the client's IP address:

```text
   <h1>You are calling me from 172.16.0.10</h1>
```

1. On the Jenkins dashboard, click "Create a new job". Enter a suitable name, e.g. *TestSampleApp*. Select a "Free  style project" as job type. Optionally, add a description.
2. Under section "Build Triggers", select checkbox "Build after other projects are built". In the text field "Projects to watch", enter the name of the build job.
3. Under section "Build steps", add a build step of type "Execute shell". Enter the following code:

    ```bash
    curl http://APP_IP:5050/ | grep "You are calling me from JENKINS_IP"
    ```

    replacing `APP_IP` and `JENKINS_IP` with the appropriate IP addresses.
4. Save and run the job to verify if it succeeds

5. The Jenkins dashboard should now list both the build and test job. Stop and remove the `samplerunning` container and then launch the build job. If you encounter an error try figuring out what is going on. There are multiple ways to tackle this issue either in Jenkins with a correct configuration option or by carefully improving the sample-app.sh script.

## 1.5 Create a build pipeline

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

3. Next, start a build. Jenkins will show you how each phase of the pipeline progresses. Check the console output of each phase.
4. If the run succeeds, the application should be running. Verify by opening it in a web browser.

Ik heb dit in het begin zo gedaan maar ben dan overgeschakeld naar een Jenkinsfile omdat dit veel makkelijker te onderhouden valt dan al je scripts op Jenkins zelf te zetten. Als je bijvoorbeeld Jenkins op een andere server gaat zetten, dan kan je in de nieuwe jenkins gewoon verwijzen naar de Jenkinsfile op Github in plaats van het script op Jenkins opnieuw maken.

## 1.6 Use a Jenkinsfile

Dit is een aanpak dat me het meest lag omdat dit persoonlijk het makkelijkst te onderhouden is, in dit script verwijs ik naar mijn publieke gitrepo, daarna toon ik de inhoud van de jenkinsfile op de console en in de laatste stap run ik het.
![pipeline script sample app](<../Images/Schermafbeelding 2026-10-19 172301.png>)

Dit is het script dat in mijn Jenkinsfile staat, in de eerste fase gaat het de huidige container waar de op in runned stoppen en verwijderen. In de 2de stap wordt de Jenkinsjob gerunned dat de app opnieuw maakt en in een container zet en in de laatste stap wordt er een curl gedaan naar de url waar de app staat om te checken of er een antwoord komt.
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

Voor deze stap moest ik terwijl de app actief was de achtergrondkleur van de pagina eens aanpassen, het pipelinescript starten en dan checken of de aanpassing uitgevoerd wordt. Dit was heel vanzelfsprekend en had hier geen problemen mee.
![aanpassing sample app](<../Images/Schermafbeelding 2026-10-19 173109.png>)

![Sample app met andere kleur](<../Images/Schermafbeelding 2026-10-19 173416.png>)

## 1.8 Create a build pipeline for a .Net application

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

De url en credentials verwijzen naar mijn github repo van deze applicatie, aangezien het een private repo is, heb ik credentials moeten instellen op jenkins en een token gemaakt op github. In de github repo staat een docker-compose.yml dat de applicatie maakt, dat door het commando in de 'Build' stap wordt geactiveerd.
Na het runnen van de job wordt de containers met de app en database aangemaakt, als je surft naar de juiste poort zie je dat de app werkt en je todo's kan toevoegen, doorkruisen en verwijderen.

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

![.NETapp job dat succes levert](<../Images/Schermafbeelding 2026-10-19 175837.png>)

![Todo-App result](<../Images/Schermafbeelding 2026-10-19 180037.png>)