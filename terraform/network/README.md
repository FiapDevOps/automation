![TERRAFORM_01](../images/TERRAFORM_01.png)

# Item 1: Configuração de Rede

Para a configuração de rede, utilizaremos o modulo da AWS:
[https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest);

1.1. Iniciar o ambiente de Desenvolvimento Remoto:

Aceese a console AWS e em seguida selecione o serviço Cloud9, e o ambiente criado via automação para então clicar na opção **OPEN IDE**:

![CLOUD9_04](../../cloud9/images/CLOUD9_04.PNG)

1.2. Utilizando a ferramenta AWS CLI verifique a configuração de rede, subnet e security groups atuais:

```sh
aws ec2 describe-vpcs --query  'Vpcs[].[VpcId, CidrBlock]' --output table
aws ec2 describe-subnets --query  'Subnets[].[VpcId, AvailabilityZone, CidrBlock]' --output table
```

1.3. Acesse o diretório automation/terraform/network e inicialize o serviço:

```sh
cd ~/environment
git clone https://github.com/FiapDevOps/automation
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

Para continuar siga para a parte 3 onde iremos adicionar grupos de segurança nesta nova rede

[>>> PARTE 3](https://github.com/FiapDevOps/automation/tree/main/terraform/firewall)

---

##### Fiap - MBA
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**
