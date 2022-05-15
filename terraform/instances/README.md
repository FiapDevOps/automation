
![TERRAFORM_01](../images/TERRAFORM_01.png)

# Item 3: Configuração de Aplicações

Na terceira e última etapa utilizaremos a arquitetura anterior para a entrega de uma aplicação de exemplo;

3.1. Inicialize o terraform no diretório contendo a automação das instancias:

```sh
cd $HOME/environment/automation/terraform/instances
terraform init
```

3.2. Verifique o planejamento das alterações, em resumo a automação deverá recuperar alguns dados sobre a VPC e Subnets para em seguida entrega duas instancias EC2 com um bloco de configuração [usando cloud-init](https://cloudinit.readthedocs.io/en/latest/) para instalar pacotes e subir a aplicação;

3.3. Finalmente execute a ultima etapa configurando a aplicação:

```sh
terraform apply
```

3.4. Ao final do processo liste as instancias criadas

```sh
aws ec2 describe-instances  --filters Name=tag:env,Values=lab --output json
```

3.5. Com ajuda do [cloud-init](https://cloud-init.io/) entregue no diretório templates as instancias foram lançadas com um setup inicial de uma aplicação web, consulte o endereço ip publico e tente o acesso pelo navegador:

```sh
aws ec2 describe-instances  --filters Name=tag:env,Values=lab \
    --query "Reservations[*].Instances[*].PublicIpAddress" \
    --output text 
```

3.6. Para finalizar nosso exemplo utilizaremos o terraform para destruir o setup criado, isso é possível pois como solução de provisionamento o terraform guarda o [estado dos recursos gerenciados](https://www.terraform.io/language/state), essa informação deve preferencialmente ser armazenada em um bucket ou similar pois é utilizada para recuperar o estado atual dos objetos para manipulaçãoou remoção:

```sh
terraform state list
```

3.7. Faça a remoção dos recursos e repita o mesmo processo em sequencia nos diretórios firewall e por fim network:

```sh
terraform destroy
```

---

##### Fiap - MBA Cyber Security Forensics, Ethical Hacking & DevSecOps
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**