# ESTÁGIO 1: Build da Aplicação
FROM debian:bookworm-slim AS build-env

RUN apt-get update && apt-get install -y \
    curl git wget unzip ca-certificates libglu1-mesa \
    && apt-get clean

# Configura o Flutter SDK (Branch Stable)
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter config --enable-web
RUN flutter doctor

WORKDIR /app
COPY . .

RUN flutter pub get
# Build usando CanvasKit para melhor fidelidade visual na assinatura
RUN flutter build web --release --web-renderer canvaskit

# ESTÁGIO 2: Servidor Nginx de Produção
FROM nginx:alpine

# Configuração para suportar Single Page Application (SPA) e evitar erro 404
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Copia os arquivos do build anterior
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]