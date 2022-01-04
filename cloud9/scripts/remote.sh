#!/bin/bash

printf "Criando chave para o acesso remoto \n"

test -f $HOME/environment/info/id_seglab.pem || cat /dev/zero | ssh-keygen  -C "ubuntu@remote" -q -N "" -b 4096 -f $HOME/environment/info/id_seglab.pem && chown ubuntu: $HOME/environment/info/id*
export PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
export PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)

printf "Configurando a chave publica"
file $HOME/environment/info/id_seglab.pem.pub && cat $HOME/environment/info/id_seglab.pem.pub >> $HOME/.ssh/authorized_keys


printf "Identificando o SecurityGroup do projeto"
aws ec2 describe-security-groups --filters Name=group-name,Values=*aws-cloud9* --query "SecurityGroups[*].[GroupName]" --output table


# Recording Security Group as Variable
SG_NAME=$(aws ec2 describe-security-groups --filters Name=group-name,Values=*aws-cloud9* --query "SecurityGroups[*].[GroupName]" --output text)

printf "Qual o end. de rede publico de sua oriem para acesso remoto? Coloque apenas o endereço sem a mascara de rede \n"
read REMOTE_PUBLIC_IP

aws ec2 authorize-security-group-ingress --group-name $SG_NAME --protocol tcp --port 0-65535 --cidr $REMOTE_PUBLIC_IP/32

cat $HOME/environment/info/id_seglab.pem
echo ""
printf "Copie a chave privada para sua maquina local e utilize no acesso remoto ao ip $PUBLIC_IP ou $PUBLIC_DNS \n"