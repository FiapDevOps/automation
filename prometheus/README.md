# Prometheus e Timeseries

Deploy a python app usando prometheus como ferramenta de monitoração

![alt tag](https://raw.githubusercontent.com/FiapDevOps/observability/f8ccc0419face4b2b99aea68536d21551c699bc7/img-src/prometheus_logo.png)


## Setup do Prometheus

Neste laboratório a [infraestrutura de rede utilizada para entrega de uma aplicação via terraform](https://github.com/fiapdevops/automation/terraform) do exemplo deste repositório será reutilizada;

O prometheus é uma plataforma de monitoração modular baseada em uma linguagem de consulta chamada [PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics/), em nosso cenário entregaremos uma instancia do prometheus em docker como microserviço para monitorar uma aplicação simples;

1.1. Acesse o diretório infra dentro dessa pasta e inicie o terraform:

```sh
cd $HOME/environment/automation/prometheus/infra
terraform init
```

1.2. Verifique a partir do plan que o modelo fara a entrega de uma instancia ubuntu com base no template alocado no diretório "infra/cloud-init" bem como as regras de liberação dos grupos de segurança para comunicacão entre o prometheus e as aplicações

```sh
cd $HOME/environment/automation/prometheus/infra
terraform apply
```

---

## Configurando um exporter dentro da aplicação

Para testar a aplicação verifique o conteúdo do diretório build em relação aos seguintes pontos:

1.1 A versão original da aplicação é um projeto python usando flask preparado para construção em container, um modelo de construção similar pode ser obtido para estudo no portal Real Python: [https://realpython.com/flask-by-example-part-1-project-setup/](https://realpython.com/flask-by-example-part-1-project-setup/);


1.2. Nesta versão da aplicação foi adicionada uma biblioteca para construção das métricas no prometheus, o [prometheus-flask-exporter](https://pypi.org/project/prometheus-flask-exporter/), acessível a partir do endpoit /metrics ele será um dos responsáveis por gerar pontos de timeseries;

1.3 Além disso também adicionamos um Dockerfile, pois o modelo descrito nesse exemplo utiliza DockerCompose para entregar todos os serviços necessários usando uma camada de abstração de rede e evitando conflitos de endereço IP:

```sh
FROM python:3.8-alpine

# Padronizacao do Workdir
WORKDIR /src

# Instalacao de Dep.
COPY requeriments.txt .
RUN pip install -r requeriments.txt
COPY src/ .

# Execução da app
CMD [ "python", "./app.py" ]
```

1.4 Para gerar o artefato que será utilizado no laboratório acesse o diretório do projeto e execute o build do container:

```sh
cd $HOME/environment/automation/prometheus/app/
docker build . -t app:0.1
docker run --rm --name app -d -e PORT=8080 -p 80:8080 app:0.1
```

1.3 Após o processo de build você verá um exemplo da aplicação rodando no endereço 127.0.0.1:8080:

| descrição                       | path                              |
|---------------------------------|-----------------------------------|
| Entrega da aplicação            | \<IP-APP>:80                     |
| Scrape de métricas              | \<IP-APP>:80/metrics             |

```sh
curl 127.0.0.1
curl 127.0.0.1/metrics
```

1.4 A aplicação anterior utilizada no teste será iniciada novamente na arquitetura de rede onde está configurado o prometheus e os outros componentes do laboratório, para isso para a aplicação anterior:

```sh
docker kill app
docker ps
```

1.5. Inicie o conjunto de containers que fazem a composição do laboratório com Docker compose:

```sh
cd $HOME/environment/automation/prometheus/
docker-compose up -d
```

Se o processo de build ocorrer conforme esperado e as imagens do prometheus e do segundo componente que trataremos no futuro forem baixadas teremos o seguinte cenário:

| descrição                            | path                              |
|--------------------------------------|-----------------------------------|
| Entrega da aplicação Python          | <IP-APP>:80                       |
| Entrega da monitoração time series   | <IP-APP>:9090                     |
| Entrega da monitoração da instância  | 127.0.0.1:9100                    |


Em nosso modelo temos 4 targets configurados para expor métricas via timeseries, cada um deles é identificado por um job e podem ser consultados na instância onde rodamos nosso stack na path ":9090/targets";

---

# Indicando as métricas para os SLIs:

No modelo entregue temos uma aplicação web, respondendo a requisições HTTP e exportando métricas, dados que serão usados para produzir alguns exemplos de SLI, acesse a URL da sua stack na porta 9090:

2.1 Considere uma métrica simples filtrando requisições http com base no status code:

```sh
flask_http_request_total{status=~"2.."}
```

> O componente prober é responsável por porduzir insumos parta a nossa analise exeuctando requisições http bem sucedidas a cada 1s.

2.2 Poderíamos  interpretar que requisições com status code diferente de 200 representam o indicador desejado (o que provavelmente é falso):

```sh
sum(rate(flask_http_request_total{status=!"2.."}[5m]))
```

Nesta métrica usamos a função [rate()](https://prometheus.io/docs/prometheus/latest/querying/functions/#rate) que considera um intervalo de tempo e um contador como parâmetros para calcular uma "taxa por segundo";

2.3 Melhorando a estratégia poderíamos filtrar apenas requisições com status code 500, o que provavelmente se aproximaria mais de um cenário onde a falha relativa ao serviço é vinculada a comportamento inesperado em um backend.

```sh
rate(flask_http_request_total{status=~"5.."}[5m])
```

> SLO são sempre baseados em um período de tempo, para o teste anterior a função rate foi utilizada para calcular a quantidade de requisições com retorno 5xx em um intervalo de 5 minutos.

## Prática: Disponibilidade e Latência

Para este cenário nossa implementação de SLI será baseada no sucesso da resposta status code HTTP. As respostas 5xx contaram no SLO, enquanto todas as outras solicitações são consideradas bem-sucedidas.

Neste contexto nosso SLI de disponibilidade seria a proporção de solicitações bem-sucedidas:

```sh
sum(rate(flask_http_request_total{job="app", status!~"5.."}[10m])) /  
sum(rate(flask_http_request_total{job="app"}[10m])) * 100
```

> Dentro dos últimos 10 minutos estamos analisando qual a taxa de eventos executados com sucesso (códig ode status diferente de 5xx), ou seja: Eventos válidos dívido pelo total de eventos ocorridos;


Já o nosso SLI de latência seria a proporção de solicitações mais rápidas do que os limites definidos (threashould), para obter este perfil de dados utilizaremos uma métrica do tipo [historigram](https://prometheus.io/docs/practices/histograms/) acumulado em buckets, este tipo de métrica separa os pontos enviados por intervalos, cada intervalo conta o número de solicitações que levaram um tempo menor ou igual (le) a um determinado valor, neste caso 250 milisegundos:

```sh
flask_http_request_duration_seconds_bucket{job="app", le="0.25"}
```

Esta métrica baseia-se no acúmulo de buckets, ou seja, contadores que acumulam os pontos recebidos com valor inferior a um determinado tempo, conforme o modelo ilustrado abaixo:

![alt tag](https://github.com/FiapDevOps/observability/raw/32b2b1479a75027dc738f6071411d967be7b6092/img-src/buckets.PNG)


Sendo assim cada bucket é sempre um bucket menor que "n" ms, o que significa que na imagem acima os buckets à direita contêm todos os buckets à esquerda.

Você decide quais tamanhos de buckets são significativos dependendo de seus SLIs e escolhendo intervalos que correspondam ao limite superior ao seu indicador, como a métrica baseada em historigram é nativa na maioria das bibliotecas fica mais simples determinar os indicadores nesta abordagem:

```sh
sum(rate(flask_http_request_duration_seconds_bucket{job="app", le="0.25", status!="500"}[5m])) /
sum(rate(flask_http_request_duration_seconds_count{job="app",status!="500"}[5m])) * 100
```

Ao sumarizar as métricas para construir SLIs é normal adicionar um agregador [sum()](https://prometheus.io/docs/prometheus/latest/querying/operators/#aggregation-operators) para executar a soma dos resultados obtidos com diferentes labels;


---
##### Fiap - MBA DevOps Enginnering | SRE
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**
