user  root;
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    gzip  on;
    sendfile        on;

    keepalive_timeout  65;

    server {
        listen       3000;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
            {{- if eq (datasource "values").appType "Single-Page App" }}
            try_files $uri $uri/ /index.html;
            {{- end}}
        }
        
        error_page 404 {{ (datasource "values").path404 }};

        location = {{ (datasource "values").path404 }} {
            root   /usr/share/nginx/html;  
        }
    }
}
