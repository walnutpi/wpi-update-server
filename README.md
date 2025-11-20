# wpi-update-server
用于wpi-update使用的服务端

# 项目使用方式
## 1. 配置nginx
安装nginx
```
sudo apt install nginx
```

打开配置文件
```bash
sudo  vim /etc/nginx/sites-enabled/default
```
在`server`中添加一个`location`项，将路径指向本项目的`web`文件夹
```
    location / {
        alias /xxx/wpi-update-server/web;
        autoindex on;
    }
```

重启nginx服务
```bash
sudo systemctl restart nginx.service
```

## 3. 配置apt源
打开用于设置apt源的配置文件
```
sudo vim /etc/apt/sources.list
```
插入源，把其中的xxxx改成自己的ip地址
```bash
deb [trusted=yes] http://xxxxx/debian/ bookworm main
```