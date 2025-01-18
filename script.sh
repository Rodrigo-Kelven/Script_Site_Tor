#!/bin/bash

# Função para instalar o Docker
instalar_docker() {
    echo "Docker não encontrado. Instalando o Docker..."
    echo "Atualizando o sistema..."
    sudo apt update && sudo apt upgrade -y

    echo "Instalando dependências..."
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    echo "Adicionando a chave GPG do Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null

    echo "Adicionando o repositório do Docker..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "Atualizando o índice de pacotes novamente..."
    sudo apt update

    echo "Instalando o Docker..."
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    echo "Docker instalado com sucesso!"
}

# Verifica se o Docker está instalado
if ! command -v docker &> /dev/null; then
    instalar_docker
else
    echo "Docker já está instalado."
fi

# Solicitar ao usuário o nome do container
read -p "Digite o nome do container: " container_name

# Criar o arquivo de configuração do Nginx
echo "server {
    listen 62458;
    server_name localhost;

    location / {
        root /var/www/html;
        index index.html index.htm;
    }
}
" > nginx.conf

# Criar o arquivo de configuração do Tor
echo "HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 80 127.0.0.1:62458
" > torrc

# Criar o diretório html e o arquivo index.html
mkdir -p html
cd html
echo "<h1>Bem-vindo ao meu site na rede Onion!</h1>" > index.html
cd ..

# Criar o Dockerfile
echo "# Usar uma imagem base do Debian" > Dockerfile
echo "FROM debian:bullseye" >> Dockerfile
echo "" >> Dockerfile
echo "# Instalar o Tor e um servidor web (Nginx)" >> Dockerfile
echo "RUN apt-get update && \\" >> Dockerfile
echo "    apt-get install -y tor nginx && \\" >> Dockerfile
echo "    apt-get clean" >> Dockerfile
echo "" >> Dockerfile
echo "# Copiar a configuração do Nginx" >> Dockerfile
echo "COPY nginx.conf /etc/nginx/sites-available/default" >> Dockerfile
echo "" >> Dockerfile
echo "# Copiar a configuração do Tor" >> Dockerfile
echo "COPY torrc /etc/tor/torrc" >> Dockerfile
echo "" >> Dockerfile
echo "# Copiar o conteúdo do site" >> Dockerfile
echo "COPY html /var/www/html" >> Dockerfile
echo "" >> Dockerfile
echo "# Expor a porta 62458" >> Dockerfile
echo "EXPOSE 62458" >> Dockerfile
echo "" >> Dockerfile
echo "# Iniciar o Tor e o Nginx" >> Dockerfile
echo "CMD [\"sh\", \"-c\", \"service tor start && nginx -g 'daemon off;'\"]" >> Dockerfile

# Construir a imagem Docker
docker build -t meu_site_onion .

# Executar o container com o nome fornecido pelo usuário
docker run -d -p 62458:62458 --name "$container_name" meu_site_onion

# Listar os containers em execução
docker ps

# Exibir o hostname do serviço Tor
docker exec -it "$container_name" cat /var/lib/tor/hidden_service/hostname
