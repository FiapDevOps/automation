
## 1. Estrutura e execução de tarefas:

Esta automação foi desenhada seguindo as orientações da documentação de boas práticas para a execução do Ansible e a estrutura recomendada de diretórios descrita na URL [https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#best-practices](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#best-practices);

### 1.1. Organização de diretórios e pastas

```sh
inventories/
    production/
        group_vars/         # Atribuição de variáveis ​​a grupos particulares;
        host_vars/          # Atribuição de variáveis ​​a instancias (apenas se necessário);

    staging/
        group_vars/         # Atribuição de variáveis ​​a grupos particulares;
        host_vars/          # Atribuição de variáveis ​​a instancias (apenas se necessário);

playbooks           # Diretório para organizar nossos playbooks, (Esta pasta não está na relação de Best Practices);
roles               # Onde toda a mágica acontece com o ansible interando sobre as instâncias após sua criação;

site.yml            # master playbook
```