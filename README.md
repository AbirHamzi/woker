Run ubuntu VM using Vagrant

        vagrant up
        
Access VM via SSH

        vagrant ssh
        
Execute nodejs app

        cp -r /vagrant/nodejs /tmp
        cd /tmp/nodejs
        npm install
        pm2 start app.js --name jscommunity
        
Follow instructions in container.sh to create a container linked to host via a Linux Bridge Network


