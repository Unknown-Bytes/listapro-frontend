#!/bin/bash

domains=(petone.site www.petone.site)
rsa_key_size=4096
data_path="./certbot"
email="backupnobre62@gmail.com"

# Cria diretórios para certificados
mkdir -p "$data_path/conf/live/$domains"
mkdir -p "$data_path/www"

# Verifica se os certificados dummy já existem
if [ -d "$data_path/conf/live/$domains" ]; then
  read -p "Certificados existentes para $domains encontrados. Continue e substitua-os? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

# Baixa certificados temporários para que o nginx possa iniciar
echo "### Criando certificados dummy ..."
openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1 \
  -keyout $data_path/conf/live/$domains/privkey.pem \
  -out $data_path/conf/live/$domains/fullchain.pem \
  -subj '/CN=localhost'

echo "### Iniciando nginx ..."
docker-compose up -d nginx

# Remove certificados anteriores
docker-compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$domains && \
  rm -Rf /etc/letsencrypt/archive/$domains && \
  rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot

# Solicita os certificados reais
echo "### Solicitando certificados Let's Encrypt ..."
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Selecione o modo adequado: webroot ou standalone
docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $domain_args \
    --email $email \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal" certbot

# Reinicia o nginx para aplicar os novos certificados
echo "### Reiniciando nginx ..."
docker-compose restart nginx

echo "### Concluído! Os certificados foram emitidos com sucesso."