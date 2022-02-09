#!/bin/bash

# Referencia:
# https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html
# https://docs.aws.amazon.com/cli/latest/reference/ec2/authorize-security-group-ingress.html
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#retrieving-the-public-key

printf "Criando chave para o acesso remoto \n"

test -f $HOME/environment/info/id_lab.pem || aws ec2 create-key-pair --key-name id_lab --key-type rsa | jq -r ".KeyMaterial" > $HOME/environment/info/id_lab.pem && chmod 600 $HOME/environment/info/id* | cp -p $HOME/environment/info/id_lab.pem $HOME/.ssh/id_rsa 
test -f $HOME/environment/info/id_lab.pub || ssh-keygen -y -f $HOME/environment/info/idlab.pem > $HOME/environment/info/id_lab.pub && chmod 600 $HOME/.ssh/id_rsa

export PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
export PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)

printf "Configurando a chave publica"
file $HOME/environment/info/id_lab.pem.pub && cat $HOME/environment/info/id_lab.pem.pub >> $HOME/.ssh/authorized_keys


printf "Identificando o SecurityGroup do projeto"
aws ec2 describe-security-groups --filters Name=group-name,Values=*aws-cloud9* --query "SecurityGroups[*].[GroupName]" --output table

# Definindo os SGs
CURRENT_SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=*aws-cloud9* --query "SecurityGroups[*].[GroupName]" --output text)
DEFAULT_SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=default --query "SecurityGroups[*].[GroupName]" --output text)



printf "Qual o end. de rede publico de sua origem para acesso remoto? Coloque apenas o endereço sem a mascara de rede \n"
read REMOTE_PUBLIC_IP

# Regras para SSH
aws ec2 authorize-security-group-ingress --group-name $CURRENT_SG --protocol tcp --port 0-65535 --cidr $REMOTE_PUBLIC_IP/32
aws ec2 authorize-security-group-ingress --group-name $DEFAULT_SG --protocol tcp --port 0-65535 --cidr $REMOTE_PUBLIC_IP/32
aws ec2 authorize-security-group-ingress --group-name $DEFAULT_SG --protocol tcp --port 0-65535 --source-group $CURRENT_SG

# Regras para ICMP
aws ec2 authorize-security-group-ingress --group-name $CURRENT_SG --protocol icmp --port -1 --cidr $REMOTE_PUBLIC_IP/32
aws ec2 authorize-security-group-ingress --group-name $DEFAULT_SG --protocol icmp --port -1 --cidr $REMOTE_PUBLIC_IP/32
aws ec2 authorize-security-group-ingress --group-name $DEFAULT_SG --protocol icmp --port -1 --source-group $CURRENT_SG


cat $HOME/environment/info/id_lab.pem
echo ""
printf "Copie a chave privada para sua maquina local e utilize no acesso remoto ao ip $PUBLIC_IP ou $PUBLIC_DNS \n"