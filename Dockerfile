FROM nginx:alpine

# 1. Configuração otimizada para Single Page App (Flutter)
# O try_files é vital para que o F5 (refresh) funcione no navegador
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
    # Configuração para cache de assets (melhora a velocidade)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|otf)$ { \
        root /usr/share/nginx/html; \
        expires 30d; \
        add_header Cache-Control "public, no-transform"; \
    } \
}' > /etc/nginx/conf.d/default.conf

# 2. Copia os arquivos da pasta build/web que você enviou via SCP
# O Docker vai pegar o CONTEÚDO de build/web e colocar na raiz do Nginx
COPY ./build/web /usr/share/nginx/html

# 3. Garante que o Nginx tenha permissão para ler os arquivos
RUN chmod -R 755 /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]