# Objetivo

Utilizar a estrutura declarativa do terraform para orquestrar a criação de um servidor web linux rodando Nginx ou Apache encapsulados em container Docker;

# Caracteriísticas:

Neste laboratório o terraform fica responsável por gerenciar os seguintes itens:

- Entender o conceito de orquestração utilizando o terraform para configuração de rede;
- Criação do grupo de segurança e regras de Inbound e Outbound;- 
- Criação da instância usando sistema operacional linux;
- Deploy de um template responsável por configurar um container Docker com uma App de exemplo;

# Item 1: Configuração de Rede

Para a configuração de rede, utilizaremos o modulo da AWS:
[https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest);

1.0. Iniciar o ambiente de Desenvolvimento Remoto:

Aceese a console AWS e em seguida selecione o serviço Cloud9, no ambiente **SEGLAB** clique em **OPEN IDE**:

![CLOUD9_04](../cloud9/images/CLOUD9_04.PNG)

1.1. Configure as seguintes variáveis de ambiente com as credênciais de acesso, elas estão disponíveis nos outputs do Cloud9:

```sh
export AWS_ACCESS_KEY_ID=XXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=yyyyyyyyyyyyyyyyyyyyyyyyyyyyy
```

1.2. Utilizando a ferramenta AWS CLI verifique a configuração de rede, subnet e security groups atuais:

```sh
aws ec2 describe-vpcs --query  'Vpcs[].[VpcId, CidrBlock]' --output table
aws ec2 describe-subnets --query  'Subnets[].[VpcId, AvailabilityZone, CidrBlock]' --output table
```

1.3. Acesse o diretório automation/terraform/network e inicialize o serviço:

```sh
cd $HOME/environment/automation/terraform/network
terraform init
```

1.4. Em seguida utilize a instrução plan para verificar a sequência de tarefas que serão executadas pelo terraform:

```sh
terraform plan
```

> Verifique que neste diretório encontram-se as instruções de automação para criação da Virtual Private Network que será usada para hospedar a instância Linux, bem como a configuração dos Grupos de Segurança que serão vinculados a nova instância;

1.5. Após verificar os detalhes do status de execução utilize o terraform para criar os objetos de acordo com o estado esperado:

```sh
terraform apply
```

1.6. As ações que serão executadas durante o processo de automação serão listadas, verifique os items do checklist para entender melhor o que será construido via terraform e em seguida digite "yes" e tecle "Enter" para confirmar a execuçção:

```sh
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

1.7. Após configurar verifique novamente os recursos de rede disponíveis:

```sh
aws ec2 describe-vpcs --query  'Vpcs[].[VpcId, CidrBlock]' --output table
aws ec2 describe-subnets --query  'Subnets[].[VpcId, AvailabilityZone, CidrBlock]' --output table
```

---

# Item 2: Configuração de Security Group

Para esta etapa serão configurados os [grupos de segurança](https://github.com/fiapsecdevops/automation/tree/main/conceitos/SecurityGroups.md) para entrega das instâncias do projeto via terraform, durante o processo de configuração, utilizaremos o modulo da AWS:
[https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest);

2.1. Iniciar o ambiente de Desenvolvimento Remoto:

Aceese a console AWS e em seguida selecione o serviço Cloud9, no ambiente **SEGLAB** clique em **OPEN IDE**;

2.2. No repositório do projeto acesse o diretório firewall e inicialize o terraform:

```sh
cd $HOME/environment/automation/terraform/firewall
terraform init
```

---

##### Fiap - MBA Cyber Security Forensics, Ethical Hacking & DevSecOps
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**
