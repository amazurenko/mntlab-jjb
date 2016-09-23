
/**
The main hash with a predefined parameters for creating jobs:
>> mandatory
id		-#should be unique in "S"-namespace
s		-#set of jobs
git		-#git repo
branch	-#branch of repo
period	-#triggering period
param1	-#main part of maven-building goals
param2	-#additional part of maven-building goals, can be empty - contain no space even
>> optional
scid	-#unique Sauce Connect identifier, use in case when we need SauceConnection
postscr -#optional existing managed script
**/


def set_of_Pjobs = [
  [
    'id':'1',
    's':'1',
    'git':'git@github.com:DigitalInnovation/customer-promise-test-framework.git',
    'branch':'*/develop',
    'period':'0 20 * * 1,2,3,4,5',
    'param1':'-U clean install -Denv=dev-st1-win7-ie-9  -Dcucumber.tags="--tags @complete --tags @P1',
    'param2':'--tags @oms --tags ~@icos" -Pparallel'

  ],
  [
    'id':'2',
    's':'1',
    'git':'git@github.com:DigitalInnovation/customer-promise-test-framework.git',
    'branch':'*/develop',
    'period':'0 22 * * 1,2,3,4,5',
    'param1':'-U clean install -Denv=dev-st1-win7-ie-9  -Dcucumber.tags="--tags @complete --tags @P2',
    'param2':'--tags @oms --tags ~@icos" -Dtunnel.identifier="bdd1" -Psaucelabs',
    'scid':'bb939e92-ad3a-4406-b232-ed24f6736762',
    'postscr':'Killing_script_Stop'
  ],
  [
    'id':'3',
    's':'1',
    'git':'git@github.com:DigitalInnovation/customer-promise-test-framework.git',
    'branch':'*/develop',
    'period':'0 21 * * 1,2,3,4,5',
    'param1':'-U clean install -Denv=dev-st1-win7-ie-9  -Dcucumber.tags="--tags @complete --tags @P3',
    'param2':'--tags @P3 --tags @oms --tags ~@icos" -Pparallel'

  ],
    [
    'id':'1',
    's':'2',
    'git':'git@github.com:DigitalInnovation/shopping-test-framework.git',
    'branch':'*/master',
    'period':'30 04 * * 1,2,3,4,5',
    'param1':'-U clean install -Psaucelabs',
    'param2':'',
    'scid':'529debcb-67fe-453f-9626-860fb7523b97',
    'postscr':'Killing_script_Stop'

  ]
]

/**
We will compine names for our set of jobs from lists below
**/

def postname = ['ORDER-OMS-bdd-st','-win7-ie-9-p','-timed-posttest']
def pname = ['ORDER-OMS-bdd-st','-win7-ie-9-p','-timed-test']


/**
It's a list of parts of scripts for posttest jobs
**/

def common_postshell = ['''
# new configuration for saving in database
CURRENT_DATE=`date +%s`
ARCHIVE_DATE=`date -d @$CURRENT_DATE +%d-%m-%Y_%H:%M`
DURATION=`curl http://${ACCESS_USER}:${ACCESS_PASSWORD}@bdd.jenkins.int.devops.mnscorp.net/job/${UPSTREAM_JOB_NAME}/${UPSTREAM_BUILD_NUMBER}/api/json?pretty=true | grep duration | grep -o "[0-9]*"`
PROJECT="dotcom-order"
COMPONENT="sterling"
ENV="st1-sterling"
BROWSER="ie9"
OS="win7"
BREAKPOINT="medium"
DESCRIPTION="p''',
'''"
DEFAULTUSER="NA"

aws s3 cp s3://mns-devops-repository/app/BDD/cucumber-reports-analytics_2.11-1.0-one-jar.jar ${WORKSPACE}

cd ${WORKSPACE}

#hardcoded user instead of UPSTREAM_BUILD_USER
java -jar cucumber-reports-analytics_2.11-1.0-one-jar.jar -path=${WORKSPACE}/target/cucumber-reports -project=${PROJECT} -component=${COMPONENT} -env=${ENV} -browser=${BROWSER} -os=${OS} -breakpoint=${BREAKPOINT} -description=${DESCRIPTION} -job=${UPSTREAM_JOB_NAME} -buildNumber=${UPSTREAM_BUILD_NUMBER} -datetime=${CURRENT_DATE} -executedBy=${DEFAULTUSER} -duration=${DURATION}

# old configuration

cd ${WORKSPACE}/target/cucumber-html-reports/
mv {feature-overview,index}.html
sed -i 's/feature-overview.html/index.html/g' *.html

aws s3 sync ${WORKSPACE}/target/cucumber-html-reports/ s3://shopping-bdd-prod-shareserver/${UPSTREAM_JOB_NAME}/${UPSTREAM_BUILD_NUMBER}_${ARCHIVE_DATE}/
''']

/**
part for test job which is used for checking
**/

def common_pshell = '''
java -version
javac -version
echo ${TARGET_OMS_ENVIRONMENT}
echo "STARTING checkServerStatusAndStart"
ssh sterling@10.156.4.79 sh /opt/IBM/bin/checkServerStatusAndStart.sh; sleep 15
'''

/**
list is used for test jobs and it is used for restarting SC
**/


def restart_bash_sc = [ 
'kill': """
#!/bin/bash
echo "Killing old SC"
pkill -f /home/jenkins/rotation_script.sh || true
killall sc
""",
'start': """
echo "Starting new SC"
nohup  /home/jenkins/rotation_script.sh oms_team """,
'end_of_start': ''' bdd1 &
sleep 20
echo "Killing old job_killing scripts"
pkill -f /home/jenkins/killing_script.sh || true
echo "Executing killing script"
ssh 10.156.0.147 "nohup /home/jenkins/killing_script.sh ${JOB_NAME} \
${BUILD_NUMBER} 'match any running tunnel for your account' > /dev/null 2>&1 &"
'''
]




/**
block creates a set of post jobs 
**/

for ( i in  set_of_Pjobs ) {
  job( postname[0]+i['s']+postname[1]+i['id']+postname[2] ){
    logRotator {
      daysToKeep(90)
    }
    label('taf-bdd-posttest')
    wrappers {
      maskPasswordsBuildWrapper {
        varPasswordPairs {
          varPasswordPair {
            var('ACCESS_USER')
            password('somepassword')
          }
          varPasswordPair {
            var('ACCESS_PASSWORD')
            password('somepassword')
          }
        }
      }
      buildUserVars()
      colorizeOutput()
    }
    steps {
      copyArtifacts(pname[0]+i['s']+pname[1]+i['id']+pname[2]) {
        fingerprintArtifacts()
        buildSelector {
          upstreamBuild()
        }
      }
      shell (common_postshell[0]+i['id']+common_postshell[1])
    }
  } 
}

for ( i in  set_of_Pjobs ) {
  mavenJob(pname[0]+i['s']+pname[1]+i['id']+pname[2]) {
    logRotator {
      numToKeep(10)
    }
    label('taf-oms-bdd')
    wrappers {
      buildUserVars()
      colorizeOutput()
      jdk('1.7_45')
    }
    scm {
      git {
        remote {
          url(i['git'])
        }
        branches(i['branch'])
      }
    }
    triggers {
        cron( i['period'] )
    }
    preBuildSteps {
      shell (common_pshell)
      if ( i['scid'] != null ) {
        shell ("${restart_bash_sc.kill} ${restart_bash_sc.start} ${i.scid} ${restart_bash_sc.end_of_start}")
      }
    }   
    rootPOM('pom.xml')
    goals(i['param1']+i['param2'])
    mavenSettingsConfigFile('aws_nexus_base') {
      content readFileFromWorkspace('central-mirror.xml')
    }
    providedSettings('aws_nexus_base')
    postBuildSteps {
      if ( i['postscr'] != null ){
        managedScript(i['postscr'])
      }
    }   
    publishers {
      archiveArtifacts('**/*')      
      downstreamParameterized {
        trigger(postname[0]+i['s']+postname[1]+i['id']+postname[2]) {
          condition('ALWAYS')
          parameters {
            predefinedProps(['UPSTREAM_JOB_NAME':'${JOB_NAME}', 'UPSTREAM_BUILD_NUMBER':'${BUILD_NUMBER}'])
          }
        }
      }
      extendedEmail {
        recipientList('Mohammed.HusainJinnah@marks-and-spencer.com',
                     'Senthilkumar.Saminathan@marks-and-spencer.com',
                     'Ramsankar.Ramaswamy@marks-and-spencer.com',
                     'Devika.Tamilappan@marks-and-spencer.com',
                     'Hariharasudhan.Kalyanasundaram@marks-and-spencer.com',
                     'Sangeetha.Selvaraj@marks-and-spencer.com')
        defaultSubject('$DEFAULT_SUBJECT')
        defaultContent('$DEFAULT_CONTENT')
        replyToList('$DEFAULT_REPLYTO')
      }
    }
  }
}
