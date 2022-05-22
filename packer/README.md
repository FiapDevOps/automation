# Packer

![PACKER_01](images/PACKER_01.png)

O Packer da Hashcorp pode ser uma boa alternativa para a construção de ambientes de infraestrutura imutável, trata-se de uma plataforma criada especificamente com a finalidade de provisionamento para construção de imagens de infraestrutura.

Neste laboratório fazeremos a prova de conceito usando o packer para o deploy de uma instancia com [docker compose](https://docs.docker.com/compose/), solução de automação para contaiers, instalado e configurado em uma AMI da AWS.

# Criando a imagem com packer

Para iniciar criaremos um arquivo de packer template, o packer utiliza uma estrutura de templates declarativos baseados na linguagem HCL (Hashicorp Configuration Language) para definir a imagem que será criada e o processo de construção de acordo com os processos a serem executados como a instalaç"ao de pacotes ou invocação de ferramenta de automação como o ansible.

1.1. Crie um diretório em nossa estrutura de IAC:

```sh
mkdir -p ~/environment/iac/packer
cd ~/environment/iac/packer
```

1.2. Dentro do diretório crie um arquivo de template:

```sh
cat <<EOF > aws-ubuntu-docker-compose.pkr.hcl

packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "learn-packer-linux-ubuntu-docker"
  instance_type = "t3.medium"
  region        = "us-west-2"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name = "learn-packer-linux-ubuntu-docker"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "shell" {
    inline = [
      "sleep 15",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
      "sudo usermod -aG docker ubuntu",
      "sudo systemctl enable docker",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
    ]
  }
}

EOF
```

1.3. Após criar o arquivo inicialize o packer:

```sh
packer init .
```

1.4. É possível executar a validação de sua infraestrutura de forma similar ao processo executado usando terraform:

```sh
packer fmt .
packer validate . 
```

1.5. Execute o build utilizando o packer:

```sh
packer build aws-ubuntu-docker-compose.pkr.hcl
```

1.6. Após o processo verifique se a imagem foi criada na [página de AMI da AWS](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Images:visibility=owned-by-me;search=learn-packer-linux-aws;sort=name);

1.7. É possível executar esta verificação usando o cliente de AWS:

```sh
aws list-images
```

---

##### Fiap - MBA DEVOPS Engineering
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**
