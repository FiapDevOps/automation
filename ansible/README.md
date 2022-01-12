# Ansible
## 1. Exemplo de Playbook (Provisionamento)

O arquivo sample.yml possui um exemplo de um playbook usando ansible para provisionar uma instância na AWS utilizando informações extraídas da VPC, para execução deste teste no ambiente configurado em aula siga as seguintes etapas:

Dentro do diretório automation/ansible execute:

```sh
ansible-playbook site.yml -v
```

## 2. Exemplo de Playbook (Gerenciamento de Configuração)

2.1 Para esta etapa utilizaremos o resultado do playbook anterior com a instância configurada na AWS e um playbook do repositório oficial [https://github.com/ansible](https://github.com/ansible);

```sh
git clone https://github.com/ansible/ansible-examples ~/environment/ansible-examples
cd ~/environment/ansible-examples/wordpress-nginx_rhel7
```

Verifique a estrutura de execução com atenção sobre alguns pontos:

- Diretório de roles
- Organização de variaveis em grupos no arquivo all.yml
- Distribuição das tarefas dentro de tasks em cada uma das roles;

O modelo descrito nessse exemploe segue uma documentação de boas práticas para a estrutura de automação disponível na URL [https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#best-practices](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#best-practices);

2.2. Para execução deste playbook duas alterações serão necessárias:

2.1. Verfique e configure as seguintes variáveis de ambiente:

```sh
export AWS_REGION=us-west-1 
export ANSIBLE_HOST_KEY_CHECKING=False
```

2.2. Altere o arquivo roles/php/tasks/main.yml removendo a dependência simplepie:

```sh
cat roles/php-fpm/tasks/main.yml
#
sed -i '/php-simplepie/d' roles/php-fpm/tasks/main.yml
```

> Existe um erro entre essa dependência e a versão de PHP que será entregue pela instalação nesta versão de RHEL7

2.3. Crie um arquivo de inventário adicionando o host de destino (discutiremos em seguida alternativas com base em inventários dinâmicos):

```sh
cat <<EOF > hosts
[wordpress-server]
<Valor do private DNS extraído após o provisionamento da instância via Ansible>
```
##### Fiap - MBA DEVOPS Engineering
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**