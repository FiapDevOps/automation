
![TERRAFORM_01](../images/TERRAFORM_01.png)

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

2.3. Esta etapa da automação será usada para configurar regras de grupos de segurança fornecendo os seguintes acessos:

| Nome                          | Perfil                                                  |
|-------------------------------|---------------------------------------------------------|
| allow_web_server_access       | Acesso liberado para a porta 80                         |
| allow_access_from_cloud9_sg   | Acesso do grupo do Cloud9 para o VPC main               |
| allow_access_to_mysql_backend | Accesso das VPC publicas para as privadas na porta 3306 |

2.4. Usando o terraform aplique o modelo configurando as regras e grupos:

```sh
terraform apply
```

2.5. Verifique o resultado usando aws cli:

```sh
aws ec2 describe-security-groups  --filters Name=tag:env,Values=lab --output json
```

---


Para finalizar siga para a parte 4 nela adicionaremos um exemplo de workload a essa infraestrutura

[>>> PARTE 4](https://github.com/FiapDevOps/automation/tree/main/terraform/instances)

---

##### Fiap - MBA
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**
