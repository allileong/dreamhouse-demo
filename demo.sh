#!/bin/bash

txtred='\e[0;31m' # Red
bldgrn='\e[1;32m' # Green
txtrst='\e[0m'    # Text Reset

#trap "exit 1" TERM
#export TOP_PID=$$

prompt() {
	printf "\n$txtred%s: $bldgrn%s$txtrst" "$USER" "$PWD"
	printf "\n-> "
	printf "$@ "
}

dprintf() {
	prompt "$@"
	read cmd
	if [ "$cmd" = "q" ]; then
		#kill -s TERM $TOP_PID
		return 1
	fi
	if [ "$cmd" != "s" ]; then
		eval "$@"
	fi
}

sfdx force:org:list > orglist.json --json

for row in $(cat orglist.json | jq -r .result.scratchOrgs[].alias); do
	if [ $row = "dev_org1" ]; then
		sfdx force:org:delete -p -u $row
		say "deleted org $row"
	fi
	if [ $row = "pkgorg" ]; then
		sfdx force:org:delete -p -u $row
		say "deleted org $row"
	fi
	if [ $row = "sub1" ]; then
		sfdx force:org:delete -p -u $row
		say "deleted org $row"
	fi
done

rm -rf dreamhouse-sfdx

dprintf "git clone https://github.com/dreamhouseapp/dreamhouse-sfdx"
dprintf "cd dreamhouse-sfdx/"
dprintf "git checkout pkg2-beta"
dprintf "git checkout -b mywork pkg2-beta"
dprintf "sfdx force:org:create -f config/enterprise-scratch-def.json -s -a dev_org1 -s"
dprintf "sfdx force:source:push"
dprintf "code ."
dprintf "sfdx force:user:permset:assign -n dreamhouse"
dprintf "sfdx force:data:tree:import -p assets/data/Broker__c-Property__c-plan.json"
dprintf "sfdx force:org:open -p one/one.app"

dprintf "cd force-app/main/"
dprintf "git clone https://github.com/dcarroll/YelpDemo"
dprintf "sfdx force:source:push"

echo -e "\nAfter adding the Yelp component to the flexipage, hit return..."
read

dprintf "sfdx force:source:pull"
dprintf "git add ."
dprintf "git commit -m 'add yelp component'"

dprintf "sfdx force:apex:test:run --json > testResult.json"
testId=$(cat testResult.json | jq -r '.result.testRunId')
rm testResult.json
dprintf "sfdx force:apex:test:report -i $testId -c"

#MDAPI Deploy
dprintf "cd ../../"
dprintf "sfdx force:source:convert -r force-app/ -d mdapi -n Dreamhouse"
dprintf "ls -lR  mdapi"
dprintf "sfdx force:org:create -a pkgorg -f config/enterprise-scratch-def.json"
dprintf "sfdx force:mdapi:deploy -d mdapi -u pkgorg -w 10"
dprintf "sfdx force:user:permset:assign -n dreamhouse -u pkgorg"
dprintf "sfdx force:data:tree:import -p assets/data/Broker__c-Property__c-plan.json -u pkgorg"
dprintf "sfdx force:org:open -u pkgorg -p one/one.app"

#packaging 2
prompt "sfdx force:package2:version:create -d force-app/ -i 0Ho1I000000KyjQSAS -v Hub1 -w 10"
dprintf "sfdx force:org:create -f config/project-scratch-def.json -a sub1 -s"
dprintf "sfdx force:package:install -i 04t1I000001kJWcQAM -u sub1 -w 10"
sfdx force:mdapi:deploy -d assets/mdapi -u sub1 -w 10
dprintf "sfdx force:user:permset:assign -n dreamhouse -u sub1"
dprintf "sfdx force:user:permset:assign -n yelpdemo -u sub1"
dprintf "sfdx force:data:tree:import -p assets/data/Broker__c-Property__c-plan.json -u sub1"
dprintf "sfdx force:org:open -u sub1 -p one/one.app"

exit 0