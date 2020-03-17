  
#!/bin/bash

#sudo systemctl stop tomcat.service

#sudo rm -rf /opt/tomcat/webapps/docs  /opt/tomcat/webapps/examples /opt/tomcat/webapps/host-manager  /opt/tomcat/webapps/manager /opt/tomcat/webapps/ROOT

#sudo chown tomcat:tomcat /opt/tomcat/webapps/ROOT.war

# cleanup log files
#sudo rm -rf /opt/tomcat/logs/catalina*
#sudo rm -rf /opt/tomcat/logs/*.log
#sudo rm -rf /opt/tomcat/logs/*.txt
cd home/centos

sudo npm install
#sudo npm install forever -g
sudo npm install pm2@2.4 -g
sudo npm install dotenv --save

#cd home/centos
#forever stopall
#pm2 stop all
#sudo npm install pm2@2.4.0 -g