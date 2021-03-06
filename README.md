#### This documentation assumes that you already have docker installed. I recoommend to use Hypriot OS (https://blog.hypriot.com/getting-started-with-docker-on-your-arm-device/)
#### Also, this documentation shows how to use host local folders for persistence. You can mount a NFS/CIFS/ISCSI file system to your host and use that instead. There are plenty resources on how to mount NAS storage on the internet.

Main idea is - your external domain name --> your external provider assigned ip address -> your router port forward ports 80 and 443 to your raspberry pi where you plan to run nginx-proxy container. You may set multiple external donain names pointing to your external ip address. Nginx will figure it out based on the external name and forward your requests to proper service inside. This means that you do not need to expose different hosts/ports via port forwarding. Everything will go via single nginx docker container running on raspberry pi. Nginx will be used for SSL terminationas well which means that you do not need to secure each internal site eventhough you still can do that if you want. By default it will be:<br> 
```
[INTERNET]<-->HTTPS/HTTP2<-->[your router]<-->HTTPS/HTTP2<-->[your nginx container]<-->HTTP1.1/HTTP2/HTTPS<-->[your internal host].
```
### Steps:
for the purpose of this documentation I assume that you use default hypriot OS user is <b>pirate</b> if you use raspbian jessie and your user id is <b>pi</b> or anything else - adjust steps below accordingly.
Also my assumtion is that you know how to copy files to unix box or how to create and edit files using either 'vi' or 'nano' editors


1. login to rasperry pi as user pirate
2. navigate to home directory 
  ```
  cd $HOME
  ```
3. clone this repository by executing:

```
git clone https://github.com/tfatykhov/wnr-nginx-proxy.git
```
4. navigate to wnr-nginx-proxy directory by executing:
```
cd wnr-nginx-proxy
```
5. make init.sh and build.sh executables using following command:
```
chmod +x init.sh
chmod +x build.sh
```
6. execute init.sh by running:
```
./init.sh
```
#### this will take some time as it will generate several required RSA keys for strong SSL support
7. Now you need to select and register your external host name. Assumtion is you should know how to do it using popular dynDns services like no-ip.org or dyndns.org. Alternatively you might register your own domain but all we need at the end - proper domain name routed to your home external ip address.
8. Edit docker-compose.yaml, find line starting with -DOMAINS= and put your external domain name after '='. For example if we assume that your external domain name is 'wnr.mydomain.com' then that line in yaml file should look like:
``` 
- DOMAINS=wnr.mydomain.com
```
If you want to serve multiple external domain names you should add them using ';' as separator. 
```
- DOMAINS=wnr.mydomain.com;myanotherhost.mydomain.com
```
9. Save modified file and navigate to configs folder
10. in configs folder you should see 2 subfolders named http and https. https subfolder will hold configuration files for each host you want to serve via nginx-proxy thhat should be accessible by its own external domain. Each host should have its own config file. I would recommend to name these files using as <externaldomain>.conf. For example wnr.mydomain.com.conf. http subfolder will hold configuration for an externally accessible status page for nginx.
11. Let start with http folder. In that folder you will find a sample config file. you should rename this file based on your internal ip address of nginx server. Once you renamed the file, open it for edit and put your actual internal ip address in the line starting with "server_name". Save the file
12. go up one level and then navigate to https subfolder. There you should see a sample config file that you should rename based on an info mentioned in pp. 10.
13. Open renamed file for edit. In that file, you should look for "server_name", ssl_certificate, and proxy_pass lines and fill it with your actual values. If we assume that your external domain name is wnr.mydomain.com and your internal wnr ip is 192.168.1.12 and your internal wnr port is 1880 and wnr itself is server via https then your config file name in https folder should be <b>wnr.mydomain.com.</b> and contents of the file should be:
```
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name wnr.mydomain.com;
    client_max_body_size 2048m;
    ssl_certificate /etc/nginx/certs/wnr.mydomain.com-chained.pem;
    ssl_certificate_key /etc/secrets/wnr.mydomain.com.key;
    ssl_dhparam /etc/secrets/dhparams.pem;

   ssl_ciphers EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH+aRSA+RC4:EECDH:EDH+aRSA:RC4:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS:!CAMELLIA;
   ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
   ssl_prefer_server_ciphers on;

    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;
    add_header Strict-Transport-Security max-age=15768000;

    location / {
   	proxy_pass https://192.168.1.12:1880;
	proxy_set_header Upgrade $http_upgrade;
        proxy_set_header   X-Forwarded-For $remote_addr;
        proxy_set_header   Host $http_host;
    	proxy_set_header Connection "upgrade";
    }
}
```
###### If you want to serve multiple external domains you need to copy file above and make changes accordingly. Each new external domain name should have it's own configuration file.

14. Save the file and navigate back to wnr-nginx-proxy:
```
cd $HOME/wnr-nginx-proxy
```
15. Now you need to copy generated privatekey.key as <you-external-domain-name>.key by executing following command assuming that your external domain name is <b>wnr.mydomain.com</b>:
```
cp $HOME/secrets/privatekey.key $HOME/secrets/wnr.mydomain.com.key
````

16. ### Now make sure that your external domain name is actually registered and your router forwarding port 80 & 443 to your raspberry pi internal ip address. Without that you will not be able to generate SSL cert!

17. Ok, it is time to start your nginx container by executing:
```
./build.sh
```
18. if everything is OK you should see nginx logs. you can interrupt those by Ctrl-C
19. make sure your container is running by executing:
```
docker container ls
```

#### If you need to make any changes - start from step 8 and add/modify files as needed. Executing ./build.sh will stop/regenerate/start nginx-proxy service.
