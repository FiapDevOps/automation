
#!/bin/bash
test -d $HOME/environment/info || install -d -m 0700 -o ec2-user -g ec2-user $HOME/environment/info

# Identificando o endereco pub da instancia:
curl -s http://169.254.169.254/latest/meta-data/public-ipv4 -o $HOME/environment/info/PUBLIC_IP.txt && chown ec2-user: $HOME/environment/info/PUBLIC_IP.txt
curl -s http://169.254.169.254/latest/meta-data/public-hostname -o $HOME/environment/info/PUBLIC_DNS.txt && chown ec2-user: $HOME/environment/info/PUBLIC_DNS.txt


# Resizing para o disco local do ambiente:
sh $HOME/environment/codecommit/scripting/resize.sh 20 > /dev/null

# Instalação de componentes:
printf "\n Configurando Dependencias \n"
sudo yum install -y tmux jq

# Instalando o docker + docker-compose
printf "\n Instalando o docker-compose \n"
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Download e instalação do kubectl
printf "\n Instalando o cliente do Kubernetes \n"
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

printf "\n Instalando o ansible via pip \n"
# https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
sudo python -m pip install --upgrade pip
pip install ansible boto3 boto

printf "\n Configurando Enviroment Env \n"
echo "AWS_REGION=us-east-2" >> $HOME/.bashrc
source $HOME/.bashrc