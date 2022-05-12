# Ansible

![ANSIBLE_01](images/ANSIBLE_01.png)

O Ansible é uma ferramenta de automação que ganhou popularidade na última década devido a sua flexibilidade, facilidade de manipulação e modelo "masterless" sem a necessidade de um controlador primário de execução, além de uma estrutura bem documentada e apoiada por comunidades e projetos de Tecnologia;

Os principais objetivos do Ansible são simplicidade e facilidade de uso apresentando um mínimo de peças móveis, a partir de uma implantação simples,  utilizando o OpenSSH como principal mecanismo de acesso autorização e autenticação é possível configurar sistemas, instalar pacotes e orquestrar tarefas complexas;

Para o funcionamento das tarefas desta prova de conceito é importante que o ambiente com o Cloud9 tenha sido [devidamente configurado](https://github.com/FiapDevOps/automation/tree/main/cloud9) com a criação da chave de acesso usando o script remote;

---

## 1. Exemplo de Playbook (Gerenciamento de Configuração)

O objetivo desta etapa é explorar uma amostra simples do que provavelmente tem sido a principal função e uso dado a ferramenta ansible, gerenciar configurações em ambientes remotos:

1.1 Para esta etapa utilizaremos um playbook simples para gerenciar a instância entregue no laboratório com terraform, para isso crie um novo diretório no projeto:

```sh
mkdir ~/environment/iac/ansible
cd ~/environment/iac/ansible
```

1.2. No acesso remoto via ssh utilizaremos o usuário ubuntu, para isso crie um arquivo de idenitifação e agrupamento dos hosts de destino da automação:

1.2.1 Identifique o end. de rede da instância provisionada, faça isso usando o CLI da AWS:

```sh
export TARGET=$(aws ec2 describe-instances   --filters "Name=tag:env,Values=lab" --query 'Reservations[].Instances[].PrivateIpAddress' --output text)
echo $TARGET
```

1.2.2 Com o endereço crie o nosso arquivo de inventário estático:

```sh
cat <<EOF > hosts
[webserver]
$TARGET

```

1.2.3 Por enquanto este será o nosso *Inventário estático** para que o ansible identifique onde rodar o proximo palybook:

```sh
cat hosts
```

1.2.4 Faça um teste validando o acesso a instância via ansible:

```sh
ansible all -m ping -i hosts
```

1.2.5 Após a conclusão do inventário crie nosso playbook simples para entrega do pacote do nginx:

```sh
cat <<EOF > webserver.yml

- hosts: webserver
  become: yes
  user: ubuntu
  tasks:

    - name: update
      apt: update_cache=yes   
   
    - name: Install Nginx
      apt: name=nginx state=latest


      notify:
        - restart nginx

  handlers:
    - name: restart nginx
      service: name=nginx state=reloaded

EOF
```

1.2.6 Após a alteração execute o playbook para gerenciar a configuração na instância criada na etapa anterior:

```sh
ansible-playbook webserver.yml -i hosts -v
```

Existe uma documentação bem completa sobre boas práticas para a estruturar automação em ansible disponível na URL [https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#best-practices](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#best-practices);

---

2. Configurar e utilizar um inventário dinâmico é uma ótima prática para usuários de ansible já que não há um controlador para garantir o estado ou um cliente para executar um processo de discovery para novas instâncias, essa configuração é feita de acordo com o Cloud Provider a partir da tags ou outras informações extraídas da infraestrutura;

2.1. Nesta configuração determinaremos quais instâncias serão utilziadas com base em um [inventário gerado dinamicamente](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html) ao executar o ansible, o inventário foi construdio com base na tag 'env' utilizada na criação da instância, para isso crie um arquivo de inventário:

```sh
cd ~/environment/iac/ansible

cat <<EOF > inventory_aws_ec2.yml
plugin: aws_ec2
regions:
  - "$AWS_REGION"

hostnames:
  - private-dns-name

keyed_groups:
  - key: tags.env
  
  - key: instance_type
    prefix: size

EOF

```

2.1.1 Para validar o inventário execute:

```sh
ansible-inventory -i inventory_aws_ec2.yml --graph
```

2.1.2 Altere o arquivo site.yml para que o playbook faça referência ao grupo staging para determinar os hosts que serão configurados;

```sh
sed -i 's/webserver/_lab/g' webserver.yml
```

2.1.3 Em seguida execute novamente o playbook usando o inventário dinâmico:

```sh
ansible-playbook webserver.yml -i inventory_aws_ec2.yml -v
```

2.1.4 Com esta configuração o ansible deve iterar sobre as duas instâncias inventariadas de acordo com a tag env:staging, para validar o comportamento volte na etapa anterior e execute o playbook ansible para criar uma segunda instância;

---
## 3. Exemplo de Playbook (Provisionamento)

O arquivo ec2-create.yml possui um exemplo de um playbook usando ansible para provisionar uma instância na AWS utilizando informações extraídas da VPC, para execução deste teste no ambiente configurado em aula configure um ambiente de provisionamento usando o Cloud9 de acordo com as [etapas documentadas neste repositório](https://github.com/fiapdevops/automation/tree/main/cloud9) e em seguida siga as seguintes etapas:


3.1 Dentro do diretório automation/ansible (Uma cópia deste repositório) execute:

```sh
cd ~/environment/automation/ansible
ansible-playbook ec2.yml -v
```

> As etapas para a instalação do ansible estão documentadas na página [Installing Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible), para o nosso ambiente este processo já foi executado durante a configuração do Cloud9;

Esta configuração conta com um unico playbook com tasks para o provisionamento da instância, no arquivo sample.yml está a estrutura de cada etapa e a documentação de referência para as funções e recursos explorados com alguns pontos relevantes:

* Como é uma tarefa de provisionamento utilizamos módulos do ansible para o nosso cloud provider com o objetivo de identificar e filtrar dados sobre a conta de testes na aws, esses módulos foram respectivamente:

    * [ec2_ami_info_module](https://docs.ansible.com/ansible/latest/collections/amazon/aws/ec2_ami_info_module.html) para filtrar e identificar as imagens de AMI determinando qual delas seria usada no provisionamento;

    * [ec2_vpc_net_info_module](https://docs.ansible.com/ansible/latest/collections/amazon/aws/ec2_vpc_net_info_module.html) para selecionar uma vpc dentro da AWS;

    * [ec2_vpc_subnet_info_module](https://docs.ansible.com/ansible/latest/collections/amazon/aws/ec2_vpc_subnet_info_module.html) para selecionar uma subnet a partir dos fatos aramazenados da vpc escolhida na tarefas anterior;

    * [ec2_module](https://docs.ansible.com/ansible/latest/collections/amazon/aws/ec2_module.html) e finalmente o módulo ec2 para o disparo de automação na criação da instância;

> Embora seja viável e bem documentado a criação e provisionamento de instâncias ou recursos de núvem usando soluções de gerenciamento de configuração costuma ser uma alternativa menos popular e com certeza menos eficiente que o uso de um mecanismo de orquestração como o [CloudFormation](https://github.com/FiapDevOps/automation/blob/main/cloud9/templates/C9.yaml) usado para criar o Cloud9 deste laboratório ou o Terraform que utilizaremos em testes futuros;

---

##### Fiap - MBA DEVOPS Engineering
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**
