   
#!/bin/bash

cd home/centos
pwd
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/home/centos/cloudwatch-agent-config.json -s

#runuser -l centos -c 'PASSWORD=foobarbaz HOST=csye6225-fall2019.cg0uh3t56xbu.us-east-1.rds.amazonaws.com node server.js'
#runuser -l centos -c 'pm2 list'

#runuser -l centos -c 'pm2 start server.js'
#runuser -l centos -c 'pm2 list'
ls --all
ls --all
#forever start server.js
pm2 start server.js -f
#pm2 server.js