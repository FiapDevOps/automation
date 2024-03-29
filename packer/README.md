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
cat <<EOF > learn-packer-linux-ubuntu-sample.pkr.hcl

packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "learn-packer-linux-ubuntu-sample"
  instance_type = "t3.medium"
  region        = "us-east-1"
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
  name = "learn-packer-linux-ubuntu-sample"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "shell" {
    inline = [
      "sleep 15",
      "sudo apt-get update",
      "sudo apt-get install nginx -y",
      "sudo systemctl enable nginx",
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
packer build learn-packer-linux-ubuntu-sample.pkr.hcl
```

1.6. Após o processo verifique se a imagem foi criada na [página de AMI da AWS](https://us-east-1.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Images:visibility=owned-by-me;search=learn-packer;sort=name);

1.7. Também é possível identificar a imagem criada utilizando o cliente de linha d comando:

```sh
aws ec2 describe-images --owners self
```

# Testando a imagem gerada

2.1 Criaremos uma instancia com base na imagem criada via packer, para isso primeiro identifique o ID da imagem:

```sh
export IMAGE_ID=$(aws ec2 describe-images --owners self --query "Images[].ImageId" --output text)
echo $IMAGE_ID
```

2.2 Com o Id da imagem dispare a criação de uma nova instância:

```sh
aws ec2 run-instances --image-id $IMAGE_ID \
    --count 1 --instance-type t3.medium --key-name id_lab \
    --tag-specifications \
    'ResourceType=instance,Tags=[{Key=env,Value=lab},{Key=imutable,Value=true}]'
```

---

##### Fiap - MBA DEVOPS Engineering
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**
