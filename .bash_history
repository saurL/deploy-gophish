ls
sudo apt install -y     ca-certificates     curl     gnupg     lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker compose version
vim docker-compose.xml
rm docker-compose.xml 
vim docker-compose.yml
mkdir gophish
cd gophish/
vim config.json
cd ..
mkdir nginx
mkdir html
mkdir conf.d
cd conf.d/
vim gophish.config
cd ..
ls
cd nginx/
mkdir html
mkdir conf.d
ls
vim gophish.config
ls
cd conf.d/
ls
vim gophish.config
cd ..
rm gophish.config
ls
cd ..
ls
rm html/
rm html/ -f
rm -f html
ls
sudo docker compose up
vim docker-compose.yml 
sudo docker compose up
vim docker-compose.yml 
sudo docker compose up
sudo docker ps
sudo docker logs gophish-nginx
ls
sudo docker compose up
sudo docker compose up -d
sudo docker gophish logs
sudo docker logs gophish
sudo docker logs gophish-nginx -f
ls
cd nginx/
cd ..
vim docker-compose.yml 
ls
cd nginx/
ls
cd conf.d/
ls
vim gophish.conf
rm gophish.config 
cd ..
sudo docker compose restart
sudo docker ps
sudo docker logs gophish-nginx
ls
cd conf.d/
ls
vim gophish.conf 
cd ..
sudo docker compose restart
sudo docker logs gophish-nginx
sudo apt update
sudo apt install -y snapd
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
vim docker-compose.yml 
sudo certbot certonly --webroot -w /home/ubuntu/nginx/html -d smort-rh.com -d www.smort-rh.com
sudo netstat -tulpn | grep :80
sudo ss -tulpn | grep :80
sudo ss -tulpn 
sudo certbot certonly --webroot -w /home/ubuntu/nginx/html -d smort-rh.com 
cat /var/log/letsencrypt/letsencrypt.log
sudo cat /var/log/letsencrypt/letsencrypt.log
sudo certbot certonly --webroot -w /home/ubuntu/nginx/html -d www.smort-rh.com 
sudo cat /var/log/letsencrypt/letsencrypt.log
ls
cd nginx/
ls
cd conf.d/
vim gophish.conf 
cd ..
vim docker-compose.yml 
sudo certbot certonly --standalone -d www.smort-rh.com
sudo certbot certonly --standalone -d admin.smort-rh.com
sudo certbot certonly --standalone -d smort-rh.com
sudo docker compose up -d
sudo docker logs gophish-nginx
sudo docker logs gophish
ls
sudo docker logs gophish
sudo docker logs gophish-nginx
sudo docker logs gophish-nginx -f
sudo docker logs --since 10m -f gophish-nginx
ls
cd nginx/
ls
cd conf.d/
ls
vim gophish.conf 
cd ..
mkdir -p /usr/share/nginx/html/static
sudo mkdir -p /usr/share/nginx/html/static
sudo vim /usr/share/nginx/html/static/sensibilisation.html
sudo docker compose ls
sudo docker compose ps
vim docker-compose.yml 
mkdir -p ./nginx/static
vim ./nginx/static/sensibilisation.html
sudo docker compose ps
sudo docker compose up -d nginx
ls
cd gophish/
cd ..
cd nginx/
ls
cd static/
ls
rm sensibilisation.html 
vim sensibilisation.html
