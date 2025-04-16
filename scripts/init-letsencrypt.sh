#!/bin/bash

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Erro: docker-compose não está instalado.' >&2
  exit 1
fi

domains=(petone.site www.petone.site)
rsa_key_size=4096
data_path="./certbot"
email="seu-email@example.com" # Substitua pelo seu e-mail

if [ -d "$data_path" ]; then
  read -p "Certificados existentes encontrados. Continuar e substituir certificados existentes? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

if [ ! -d "$data_path/conf/live/$domains" ]; then
  echo "### Criando diretórios de certificados e arquivos de configuração dummy ..."
  mkdir -p "$data_path/conf/live/$domains"
  docker-compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
      -keyout '/etc/letsencrypt/live/$domains/privkey.pem' \
      -out '/etc/letsencrypt/live/$domains/fullchain.pem' \
      -subj '/CN=localhost'" certbot
fi

echo "### Iniciando nginx ..."
docker-compose up --force-recreate -d nginx
echo

echo "### Solicitando Let's Encrypt certificate para $domains ..."
#Junta todos os domínios em um só parâmetro separado por -d
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Selecione os desafios apropriados para obter os certificados
docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $domain_args \
    --email $email \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal" certbot
echo

echo "### Reiniciando nginx ..."
docker-compose exec nginx nginx -s reload