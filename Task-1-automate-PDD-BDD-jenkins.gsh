/*
start jobs on taf-bdd-prod7	
Docker container			| Clean local images
poll scm					| git@github.com:DigitalInnovation/shop-UX.git master branch
Advanced clone behaviours	| Shallow clone
Build periodically			| 00 07 * * *
Abort the build if it's stuck| Absolute
Color ANSI Console Output	| xterm
>> Provide Node & npm bin/ folder to PATH | NodeJS 0.12.0
>> Sauce Labs Support			| demand - SL creds
>> SL options					| Set jenkins user build variables
>> Execute shell 

	cd src/fear/test/e2e_integrated
	npm install
	npm run e2e-ci -- --s large --t "PD-Chrome-Win7-Large-Cloud" --platform="WINDOWS 7"
*/




def set_for_jobs = [
  "PD-Chrome-Win7-Large-Cloud":'''--s large --t "PD-Chrome-Win7-Large-Cloud" --platform="WINDOWS 7"''',
  "PD-Chrome-Win7-Large-shiftyShark":'''--s large --p shark --t "PD-Chrome-Win7-Large-shiftyShark" --platform="WINDOWS 7"''',
  "PD-Chrome-Win7-Large-Sit2":'''--s large --t "PD-Chrome-Win7-Large-Sit2" --p sit2 --platform="WINDOWS 7" --suite e2e''',
  "PD-Chrome-Win7-Medium-Cloud":'''-s medium --t "PD-Chrome-Win7-Medium-Cloud" --platform="WINDOWS 7"''',
  "PD-Chrome-Win7-Small-Cloud":'''--s small --t "PD-Chrome-Win7-Small-Cloud" --platform="WINDOWS 7"''',
  "PD-Chrome-Win7-Xsmall-Cloud":'''--t "PD-Chrome-Win7-Xsmall-Cloud" --platform="WINDOWS 7"''',
  "PD-Chrome-Win7-Large-Sit2":'''--t "PD-Chrome-Win7-Large-Sit2" --p sit2 --platform="WINDOWS 7" --suite e2e''',
  "PD-Firefox-Win7-Large-Cloud":'''--browser=firefox --capabilities.version 45.0 --s large --t "PD-Firefox-Win7-Large-Cloud" --platform="WINDOWS 7"''',
  "PD-IE11-Win7-Large-Cloud":'''--browser='internet explorer' --s large --t "PD-IE11-Win7-Large-Cloud" --platform="WINDOWS 7"''',
  "PD-Safari-Mac-Large-Cloud":'''--browser=safari --s large --t "PD-Safari-Mac-Large-Cloud" --platform=MAC'''

]

for ( i in  set_for_jobs.keySet() ) {
  
  job( i ) {
    logRotator {
        numToKeep(15)
    }
    label('taf-bdd-prod7')
    wrappers {
      colorizeOutput()
      nodejs('0.12.0')
      timeout {
          absolute('30')
        }
      sauceOnDemand {
        credentials("INPUT YOUR CREDS, PLEASE")
        useGeneratedTunnelIdentifier(true)
        verboseLogging(true)
        options('-F foresee_trigger.js,fs.trigger.js,edr.js  ')
        useLatestVersion(true)
        launchSauceConnectOnSlave(true)
        enableSauceConnect(true)
        }
    }
    scm {
      git {
        remote {
          url('git@github.com:DigitalInnovation/shop-UX.git')
        }
        branches('*/master')
        extensions {
          cloneOptions {
            shallow(true)
          }
        }
        
      }
    }
    triggers {
        scm('00 07 * * *')
    }
    steps {
        shell('''
#!/bin/bash 
if [[ $(docker ps -a -q) != "" ]]
  then (docker rm $(docker ps -a -q))
fi
if [[ $(docker images -q) != "" ]]
  then (docker rm $(docker images -q))
fi;
cd src/fear/test/e2e_integrated
npm install
npm run e2e-ci  -- '''+set_for_jobs[i] )
    }
  }
}
/*
Paralell test jobs, added #${BUILD_NUMBER}, changed git branch on parallel-tests, NodeJS 6.2.1
>>npm run e2e-ci-cloud
>>npm run e2e-ci-sit2
*/
def set_for_paral_jobs = [
  'Protractor-Parallel':'''e2e-ci-cloud''',
  'Protractor-sit2-Parallel':'''e2e-ci-sit2'''
]

for ( i in  set_for_paral_jobs.keySet() ) {
  job( i ) {
    logRotator {
        numToKeep(15)
    }
    label('taf-bdd-prod7')
    wrappers {
      colorizeOutput()
      nodejs('6.2.1')
      timeout {
          absolute('30')
        }
      sauceOnDemand {
        credentials("INPUT YOUR CREDS, PLEASE")
        useGeneratedTunnelIdentifier(true)
        verboseLogging(true)
        options('-F foresee_trigger.js,fs.trigger.js,edr.js  ')
        useLatestVersion(true)
        launchSauceConnectOnSlave(true)
        enableSauceConnect(true)
        buildName('#${BUILD_NUMBER}')
        }
    }
    scm {
      git {
        remote {
          url('git@github.com:DigitalInnovation/shop-UX.git')
        }
        branches('*/parallel-tests')
        extensions {
          cloneOptions {
            shallow(true)
          }
        }
        
      }
    }
    triggers {
        scm('00 07 * * *')
    }
    steps {
        shell('''
#!/bin/bash 
if [[ $(docker ps -a -q) != "" ]]
  then (docker rm $(docker ps -a -q))
fi
if [[ $(docker images -q) != "" ]]
  then (docker rm $(docker images -q))
fi;
cd src/fear/test/e2e_integrated
npm install
npm run '''+set_for_paral_jobs[i] )
    }
  }  

}
