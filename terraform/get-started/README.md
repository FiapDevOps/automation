# Objetivo

![TERRAFORM_01](images/TERRAFORM_01.png)

Apresentar o terraform para estudo de alguns conceitos sobre provisionamento e estado de automação;

A documentação a seguir apresenta alguns conceitos sobre o funcionamento do terraform: [https://learn.hashicorp.com/tutorials/terraform/infrastructure-as-code?in=terraform/aws-get-started](https://learn.hashicorp.com/tutorials/terraform/infrastructure-as-code?in=terraform/aws-get-started);

1. Usando o nosso bastion host (cloud9), crie um novo repositório para iniciar o projeto:

```sh
mkdir ~/environment/iac
cd ~/environment/iac
git init
```

2. Em seguida construa um modelo base de automação usando a estrutura documentada nesta página: [https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started](https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started);

2.1 Crie um arquivo main.tf

```sh
touch main.tf
```

2.1.1 Configure o bloco de provisionamento para entrega de uma instância EC2 de acordo com o link anterior:

```sh
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0708edb40a885c6ee"
  instance_type = "t2.micro"
  key_name      = "id_lab"
  subnet_id     = "my-subnet-id"

  tags = {
    Name = "ExampleAppServerInstance"
    env  = "lab"
  }
}

```

**Alterações em relação ao script original**

- Nesta configuração o campo region foi alterado para a região em uso neste laboratório (us-east-1);
- O campo key_pair foi adicionado com uma referência a chave criada durante a configuração do bastion host;
- No campo tags adicionamos uma tag env = lab criando a tag de controle usada pelo script de remoção de recursos configurado junto com o bastion host;

**Identifcação da AMI**

Para o disparo da automação é necessário a referência sobre a ami ou imagem da instância que será entregue (em nosso exemplo Ubuntu 20.04), essa referência é um id unico baseado na região e pode ser localziada [usando o aws cli](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html#finding-an-ami-aws-cli) ou se preferir usando a [documentação do sistema operacional como neste caso](https://cloud-images.ubuntu.com/locator/ec2/);

2.1.2 Antes de prosseguir identifique qual a subnet atual do projeto:

```sh
aws ec2 describe-subnets \
    --filters Name=tag:Network,Values=Public \
    --query 'Subnets[*].SubnetId' \
    --output table
```

Utilize uma das subnets listadas no campo subnet_id substituindo o valor do parâmetro  **subnet_id** na **"my-subnet-id"** pela subnet identificada conforme modelo abaixo:

```sh
...

resource "aws_instance" "app_server" {
  ami           = "ami-0708edb40a885c6ee"
  instance_type = "t2.micro"
  key_name      = "id_lab"
  subnet_id     = "my-subnet-id"

...

```

2.2 Após salvar as alterações valide e dispare novamente a automação:

```sh
terraform validate
terraform plan
terraform apply
```

2.3 Verifique se a instância foi reconstruída de acordo com os parametros alterados:

```sh
aws ec2 describe-instances     \
   --filters "Name=tag-value,Values=lab"
```

2.4 Em caso afirmativo identifique o endereço da instância:

```sh
TARGET=$(aws ec2 describe-instances     \
   --filters "Name=tag-value,Values=lab"  "Name=instance-state-name,Values=running" \
   --query 'Reservations[*].Instances[*].{Instance:PrivateIpAddress}' \
   --output text)

echo $TARGET
```

2.4.1 Faça uma tentativa de acesso via SSH:

```sh
ssh -l ubuntu $TARGET
```

---

##### Fiap - MBA Cyber Security Forensics, Ethical Hacking & DevSecOps
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**