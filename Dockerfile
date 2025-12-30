# ESTÁGIO 1: Build da Aplicação
# Usamos uma imagem que já possui o Flutter instalado e configurado
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Define o diretório de trabalho
WORKDIR /app

# OTIMIZAÇÃO DE CACHE: Copiamos apenas os arquivos de dependências primeiro
# Isso faz com que o 'pub get' só rode se você mudar as bibliotecas
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Agora copiamos o restante do código
COPY . .

# Build otimizado
# --no-pub: pula a verificação de pacotes pois já fizemos acima
# --web-renderer canvaskit: mantém a alta fidelidade da assinatura
RUN flutter build web --release --web-renderer canvaskit --no-pub

# ESTÁGIO 2: Servidor Nginx (Execução)
FROM nginx:alpine

# Configuração SPA para evitar erro 404 ao atualizar a página
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Copia apenas os arquivos necessários do estágio de build
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]