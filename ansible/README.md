# Ansible

![ANSIBLE_01](images/ANSIBLE_01.png)

O Ansible é uma ferramenta de automação que ganhou popularidade na última década devido a sua flexibilidade, facilidade de manipulação e modelo "masterless" sem a necessidade de um controlador primário de execução, além de uma estrutura bem documentada e apoiada por comunidades e projetos de Tecnologia;

Os principais objetivos do Ansible são simplicidade e facilidade de uso apresentando um mínimo de peças móveis, a partir de uma implantação simples,  utilizando o OpenSSH como principal mecanismo de acesso autorização e autenticação é possível configurar sistemas, instalar pacotes e orquestrar tarefas complexas;

Para o funcionamento das tarefas desta prova de conceito é importante que o ambiente com o Cloud9 tenha sido [devidamente configurado](https://github.com/FiapDevOps/automation/tree/main/cloud9) com a criação da chave de acesso usando o script remote;

---
## 1. Exemplo de Playbook (Provisionamento)

O arquivo sample.yml possui um exemplo de um playbook usando ansible para provisionar uma instância na AWS utilizando informações extraídas da VPC, para execução deste teste no ambiente configurado em aula configure um ambiente de provisionamento usando o Cloud9 de acordo com as [etapas documentadas neste repositório](https://github.com/fiapdevops/automation/tree/main/cloud9) e em seguida siga as seguintes etapas:

No ambiente com Cloud9 o ansible já foi instalado, a partir desta etapa configure as seguintes variáveis de ambiente com as credênciais de acesso, elas estão disponíveis nos outputs do Cloud9:

```sh
export AWS_ACCESS_KEY_ID=XXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=yyyyyyyyyyyyyyyyyyyyyyyyyyyyy
```

Com a configuração finalizada dentro do diretório automation/ansible (Uma cópia deste repositório) execute:

```sh
cd ~/environment/automation/ansible
ansible-playbook site.yml -v
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
## 2. Exemplo de Playbook (Gerenciamento de Configuração)

O objetivo desta etapa é explorar uma amostra simples do que provavelmente tem sido a principal função e uso dado a ferramenta ansible, gerenciar configurações em ambientes remotos:

2.1 Para esta etapa utilizaremos o resultado do playbook anterior com a instância configurada na AWS e um playbook do repositório oficial [https://github.com/ansible](https://github.com/ansible), faça uma cópia deste repositório na instância de cloud9:

```sh
git clone https://github.com/ansible/ansible-examples ~/environment/ansible-examples
cd ~/environment/ansible-examples/wordpress-nginx_rhel7
```

Verifique a estrutura de execução com atenção sobre alguns pontos:

- Diretório de roles
- Organização de variaveis em grupos no arquivo all.yml
- Distribuição das tarefas dentro de tasks em cada uma das roles;

O modelo descrito nessse exemplo segue uma documentação de boas práticas para a estrutura de automação disponível na URL [https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#best-practices](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#best-practices);

**Caso tenha configurado as credenciais de acesso na etapa anterior pule para o item 2.3**

2.2. Configure as seguintes variáveis de ambiente com as credênciais de acesso, elas estão disponíveis nos outputs do Cloud9:

```sh
export AWS_ACCESS_KEY_ID=XXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=yyyyyyyyyyyyyyyyyyyyyyyyyyyyy
```

2.3. Para execução deste playbook algumas alterações serão necessárias:

2.3.1. Altere o arquivo roles/php/tasks/main.yml removendo a dependência simplepie:

```sh
cat roles/php-fpm/tasks/main.yml
sed -i '/php-simplepie/d' roles/php-fpm/tasks/main.yml
```

> Existe um erro entre essa dependência e a versão de PHP que será entregue pela instalação nesta versão de RHEL7

2.3.2. Adicione uma linha de execução na role common:

```sh
cat <<EOF >> ~/environment/ansible-examples/wordpress-nginx_rhel7/roles/common/tasks/main.yml
#
- name: Disable SELinux
  selinux: state=disabled
EOF
```

> Essa alteração ocorre devido a um erro na liberação do mariadb no firewall de contexto SELINUX do Rhel 7


2.4. No acesso remoto via ssh utilizaremos o usuário ec2-user, para isso edite o arquivo site.yml de acordo com o padrão abaixo:

```sh
cat <<EOF > site.yml
- name: Install WordPress, MariaDB, Nginx, and PHP-FPM
  hosts: wordpress-server
  remote_user: ec2-user
  become: yes

  roles:
    - common
    - mariadb
    - nginx
    - php-fpm
    - wordpress
EOF
```

2.4.1. As diferenças podem ser avaliadas usando o proprio git:

```sh
git diff
```

2.5.1. Crie um arquivo de inventário adicionando o host de destino (discutiremos em seguida alternativas com base em inventários dinâmicos):

Será necessário extrair o endereço da instância provisionada, faça isso usado o CLI da AWS:

```sh
export TARGET=$(aws ec2 describe-instances   --filters "Name=tag:env,Values=staging" --query 'Reservations[].Instances[].PrivateIpAddress' --output text)
echo $TARGET
```

2.5.2. Com o endereço IP crie o nosso arquivo de inventário estático:

```sh
cat <<EOF > hosts
[wordpress-server]
$TARGET

EOF
```

2.5.3. Por enquanto este será o nosso *Inventário estático** para que o ansible identifique onde rodar o proximo palybook:

```sh
cat hosts
```

2.6. Após a alteração execute o playbook para gerenciar a configuração na instância criada na etapa anterior:

```sh
ansible-playbook site.yml -i hosts -v
```

*Caso ocorra um erro durante a reinicialização do banco de dados basta rodar novamente o mesmo playbook repetindo o comando anterior*

2.7. Pontos interessantes:

* a. Esta automação utiliza uma estrutura mais complexa de tarefas e por isso foi divida em roles de acordo com a finalidade;

```sh
roles
├── common
│   ├── files
│   │   ├── epel.repo
│   │   ├── nginx.repo
│   │   ├── remi.repo
│   │   ├── RPM-GPG-KEY-EPEL-7
│   │   ├── RPM-GPG-KEY-NGINX
│   │   └── RPM-GPG-KEY-remi
│   └── tasks
│       └── main.yml
├── mariadb
│   ├── handlers
│   │   └── main.yml
│   ├── tasks
│   │   └── main.yml
│   └── templates
│       └── my.cnf.j2
```
* b. O formato permite que uma role geral seja reaproveitada na construção de outros playbooks bastando que ela seja declarada no arquivo princial;

```sh
...

  roles:
    - common
    - mariadb
    - nginx
    - php-fpm
    - wordpress
```

* c. A role mariadb utiliza o conceito de [Handler](https://docs.ansible.com/ansible/latest/user_guide/playbooks_handlers.html) para lidar com a reinicialização do banco, com o handler a partir da task "main.yml" podemos forçar a reinicialização do serviço quando uma etapa for entregue (neste caso a alteração do arquivo de configuração)

```sh
  notify:
  - restart mariadb
```

* d. Já a role do Nginx utiliza o preechimento dinâmico de valores via template na configuração do arquivo default.conf, os templates flexibilizam muito a configuração e permitem o uso de arquivos de invetário para popular e alterar dados usando uma unica fonte de informações;

```sh
...
        listen       {{ nginx_port }} default_server;
        server_name  {{ server_hostname }};
        root /srv/wordpress/ ;
...
```

---

3. Configurar e utilizar um inventário dinâmico é uma ótima prática para usuários de ansible já que não há um controlador para garantir o estado ou um cliente para executar um processo de discovery para novas instâncias, essa configuração é feita de acordo com o Cloud Provider a partir da tags ou outras informações extraídas da infraestrutura;

3.1. Nesta configuração determinaremos quais instâncias serão utilziadas com base em um [inventário gerado dinamicamente](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html) ao executar o ansible, o inventário foi construdio com base na tag 'env' utilizada na criação da instância, para isso crie um arquivo de inventário:

```sh
cd ~/environment/ansible-examples/wordpress-nginx_rhel7

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

Para validar o inventário execute:

```sh
ansible-inventory -i inventory_aws_ec2.yml --graph
```

Altere o arquivo site.yml para que o playbook faça referência ao grupo staging para determinar os hosts que serão configurados;

```sh
sed -i 's/wordpress-server/_staging/g' site.yml
```

Em seguida execute novamente o playbook usando o inventário dinâmico:

```sh
ansible-playbook site.yml -i inventory_aws_ec2.yml -v
```

Com esta configuração o ansible deve iterar sobre as duas instâncias inventariadas de acordo com a tag env:staging, para validar o comportamento volte na etapa anterior e execute o playbook ansible para criar uma segunda instância;

---

##### Fiap - MBA DEVOPS Engineering
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**
