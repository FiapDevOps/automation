# Prometheus e Timeseries

Apresentando o conceito de timeseries usando o prometheus;

![alt tag](https://raw.githubusercontent.com/FiapDevOps/observability/f8ccc0419face4b2b99aea68536d21551c699bc7/img-src/prometheus_logo.png)


## Setup do Prometheus

O prometheus é uma plataforma de monitoração modular baseada em uma linguagem de consulta chamada [PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics/), em nosso cenário entregaremos uma instancia do prometheus em docker como microserviço para monitorar uma aplicação simples;

1.1. Neste cenário usaremos um bucket remoto para armazenar e posteriormente recuperar o estado da automação, para isso execute:

```sh
aws s3api create-bucket --bucket terraform-$C9_PID --region us-east-1 
```

1.2. Com base no resultado do comando anterior utilize o nome do bucket para configurar o backend do terraform na automação:

```sh
cd $HOME/environment/automation/prometheus/iac

# Substitua a linha abaixo pelo bucket identificado no STDOUT do comando anterior
sed -i s/mybucket/terraform-xxxxxxxxxxxxxxxxxxxxxxx/g main.tf
```

1.3. Inicie o terraform:

```sh
terraform init
terraform plan
```

1.2. Verifique a partir do plan que o modelo fara a entrega de uma instancia ubuntu com base no template de [cloud-init](https://cloudinit.readthedocs.io/en/latest/) alocado no diretório "iac/templates" bem como as regras de liberação dos grupos de segurança para comunicacão entre o prometheus e as aplicações

```sh
terraform apply
```

> Será configurada uma nova instancia via terraform com o prometheus em listen na porta 80 e a aplicação em listen na porta 8080 de acordo com o padrão abaixo:

| descrição                       | path                             |
|---------------------------------|----------------------------------|
| Interface do prometheus                     | \<prometheus_public_ip>:80                             |
| Acesso na App de testes                     | \<prometheus_public_ip>:8080                           |
| Scrape de métricas                          | \<prometheus_public_ip>:8080/metrics                   |
| Scrape de métricas do sistema operacional   | \<prometheus_public_ip>:9100/metrics                   |


---

## Como configurar um exporter dentro da aplicação

Para testar o modelo de timeseries e sua flexibilidade considere os seguintes pontos:

A versão original da aplicação é um projeto python usando flask preparado para construção em container, um modelo de construção similar pode ser obtido para estudo no portal Real Python: [https://realpython.com/flask-by-example-part-1-project-setup/](https://realpython.com/flask-by-example-part-1-project-setup/);

Nesta versão da aplicação foi adicionada uma biblioteca para construção das métricas no prometheus, o [prometheus-flask-exporter](https://pypi.org/project/prometheus-flask-exporter/), acessível a partir do endpoit /metrics ele será um dos responsáveis por gerar pontos de timeseries;

Uma cópia deste padrão pode ser consultada no diretório build da pasta prometheus:

```sh
ls $HOME/environment/automation/prometheus/iac/build
cat $HOME/environment/automation/prometheus/iac/build/src/app.py
```

Para gerar a app será utilizado uma imagem criada com base neste build disponível no Dockerhub [https://hub.docker.com/r/devfiap/python-flask-app](https://hub.docker.com/r/devfiap/python-flask-app);

---

# Desbravando métricas sobre o uso recursos:

Para monitorar o uso de recursos usando timeseries, no caso do prometheus o node-exporter é geralmente escolha para fornecimento dos dados, ele foi implementado em nosso ambiente com scrape de metricas para a porta 9100 na path /metrics;

Um  exemplo simples seria uma consulta direta aos pontos usando a função rate do prometheus para obter a média:

```sh
rate(node_cpu_seconds_total{mode="system"}[1m])
```

Outra possibilidade agora para avaliação sobre o uso de memória seria o ponto node_memory_MemAvailable_bytes:

```sh
node_memory_MemAvailable_bytes/1024/1024
```

> Como o valor original foi configurado na métrica em bytes existe um processo de conversão, por isso a divisão por 1024 duas vezes;

Toda métrica de timeseries é baseada em uma informação de um momento no tempo, por isso em casos onde o histórico é importante é comum transformar esses dados em gráficos, mas é possível executar consultas usando funções para tratar esses dados como o [offset](https://prometheus.io/docs/prometheus/latest/querying/basics/#offset-modifier);

```sh
node_memory_MemAvailable_bytes/1024/1024 offset 10m
```

Outros exemplo interessantes podem ser consultados nos endereços abaixo:

Métricas sobre o uso de CPU: [Understanding Machine CPU usage](https://www.robustperception.io/understanding-machine-cpu-usage)

Métricas sobre o uso de Filesystem: [Filesystem metrics from the node exporter](https://www.robustperception.io/filesystem-metrics-from-the-node-exporter)

---

# Testando métricas de aplicação:

No modelo entregue temos uma aplicação web, respondendo a requisições HTTP e exportando métricas, dados que serão usados para produzir alguns exemplos de SLI, acesse a URL da sua stack na porta 8080:

3.1 Considere uma métrica simples filtrando requisições http com base no status code:

```sh
flask_http_request_total{status=~"2.."}
```

Nesta métrica usamos a função [rate()](https://prometheus.io/docs/prometheus/latest/querying/functions/#rate) que considera um intervalo de tempo e um contador como parâmetros para calcular uma "taxa por segundo";

3.2 Melhorando a estratégia poderíamos filtrar apenas requisições com status code 500, o que provavelmente se aproximaria mais de um cenário onde a falha relativa ao serviço é vinculada a comportamento inesperado em um backend.

```sh
rate(flask_http_request_total{status=~"5.."}[5m])
```

> Para o teste anterior a função rate foi utilizada para calcular a quantidade de requisições com retorno 5xx em um intervalo de 5 minutos, para simular alguns erros faça uma tentativa de acesso usando a URL /fail (http://X.X.X.X:8080/fail)

---

## Disponibilidade e Latência

Este exemplo utiliza um formato similar ao anterior porém adicionando um calculo matemático no cenário:

O objetivo é calcular a taxa de sucesso das requisições HTTP, com base no status code diferente de 5xx nos últimos 10 minutos, esse calculo assume que qualquer requisição cujo retorno seja diferente de 5xx é considerada uma requisição bem sucessida:

```sh
sum(rate(flask_http_request_total{job="app", status!~"5.."}[10m])) /  
sum(rate(flask_http_request_total{job="app"}[10m])) * 100
```

> Dentro dos últimos 10 minutos estamos analisando qual a taxa de eventos executados com sucesso (código de status diferente de 5xx), ou seja: Eventos válidos dívido pelo total de eventos ocorridos;

---

## Usando Historigrams

Na implementação do prometheus com timeseries temos alguns tipos interessantes de métricas, entre elas está o [historigram](https://prometheus.io/docs/practices/histograms/) que de forma simplificada permite determinar a proporção de eventos válidos com base em um threashould, para que isso ocorra esse formato basicamente organiza os pontos recebidos em timeseries em buckets,separando os pontos por intervalos, cada intervalo conta o número de solicitações que levaram um tempo menor ou igual (le) a um determinado valor, para este exemplo este valor será de 250 milisegundos:

Dessa forma para determinar quantas requisições foram atendidas em menos de 250 milisegundos poderiamos executar a seguinte consulta:

```sh
flask_http_request_duration_seconds_bucket{job="app", le="0.25"}
```

Esta métrica baseia-se no acúmulo de buckets, ou seja, contadores que acumulam os pontos recebidos com valor inferior a um determinado tempo, conforme o modelo ilustrado abaixo:

![alt tag](https://github.com/FiapDevOps/observability/raw/32b2b1479a75027dc738f6071411d967be7b6092/img-src/buckets.PNG)


Sendo assim cada bucket é sempre um bucket menor que "n" ms, o que significa que na imagem acima os buckets à direita contêm todos os buckets à esquerda.

Você decide quais tamanhos de buckets são significativos dependendo de seus indicadores e do valor que deseja usar como base de corte na sua consulta escolhendo intervalos que correspondam ao limite superior ao seu indicador, este é um exemplo da flexibilidade de sistemas baseados em timeseries 

Adicionando essa estratégia ao exemplo anterior:

```sh
sum(rate(flask_http_request_duration_seconds_bucket{job="app", le="0.25", status!="500"}[5m])) /
sum(rate(flask_http_request_duration_seconds_count{job="app",status!="500"}[5m])) * 100
```

ANeste calculo também usamos outra característica do prometheus a função [sum()](https://prometheus.io/docs/prometheus/latest/querying/operators/#aggregation-operators) que é um agregador;

---

# Criando uma regra de alerta

No prometheus a construção de alertas é baseado em consultas usando o PROMQL, para testarmos o conceito execute o seguinte processo:

3.1 A partir do ambiente local acesse remotamente a instancia onde a aplicação foi entregue;

3.2 Verifique que as regras de alerta ficam configuradas no arquivo rules.yml entregue no prometheus usando o docker-compose:

```sh
cd /home/ubuntu/automation/prometheus
cat rules.yml
```

3.3 Adicione uma nova regra de alerta neste arquivo:

```sh

cat <<EOF >> rules.yml

      - alert: NodeExporterDown
        expr: up{job="node"} != 1
        for: 5m
        labels:
          severity: high
        annotations:
          summary: The Node exporter metrics is down at $labels.instance
EOF
```

3.4 Como a alteração foi executada após o build utilize o docker-compose para reconfigurar a nossa stack:

```sh
docker-compose restart
```

3.5 Com este processo temos uma regra especifica para validar a disponibilidade do job "node"responsável pelo node-exporter, simule uma falha no componente e acompanha o alerta pela interface do prometheus:

```sh
docker kill prometheus_node-exporter_1
```

---

## Configurando um cenário com service discovery:

Dentro da arquitetura DevOps um conceito importante na monitoração de serviços é a agilidade, uma alternativa para conseguir esse objetivo é trabalhar com cenários de service discovery;

4.1 Em nosso lab iremos configurar um novo job usando as credenciais da AWS para identificar automaticamente novos resources ec2, para isso execute o seguinte processo:

```sh
cd /home/ubuntu/automation/prometheus
cat prometheus.yml
```

4.2 Ao final do arquivo adicione a configuração do novo job:

```sh
cat <<EOF >> prometheus.yml


```sh
  - job_name: 'node_ec2_job'
    ec2_sd_configs:
      - region: us-east-1
        access_key: ACCESS_KEY
        secret_key: SECRET_KEY
        port: 9100
    relabel_configs:
      - source_labels: [__meta_ec2_instance_id]
        target_label: ec2_instance_id
      - source_labels: [__meta_ec2_tag_environment]
        target_label: ec2_instance_env

EOF
```

4.3 Utilize o docker-compose para reconfigurar a nossa stack:

```sh
docker-compose restart
```

4.4 Acesse a interface web e verifique o novo job em ação no ip da instancia de prometheus acessando a URL /service-discovery

Uma documentação detalhada deste setup pode ser consultada neste link [Automatically monitoring EC2 Instances](https://www.robustperception.io/automatically-monitoring-ec2-instances);

---

##### Fiap - MBA DevOps Enginnering | SRE
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**
