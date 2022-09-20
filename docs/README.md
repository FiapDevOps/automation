# Canary

Modelos para deploy usando Kubernetes + Istio como parte de uma estratégia de canary deployment

## Preparação

Para execução deste roteiro será necessário um ambiente kubernetes, que será configurado utilizando o [EKS](https://aws.amazon.com/eks/) gerenciado da AWS, o setup a seguir utiliza parte da documentação fornecida workshop [Amazon EKS Workshop](https://www.eksworkshop.com/);

1.1. Inicie a configuração atualizando as dependências da IDE Cloud9:

```sh
cd ~/environment/scripts
git pull
./config.sh
```

1.2. Configure uma variavel para facilitar a identificação do cluster:

```sh
echo "export EKS_CLUSTER=eks-$(echo $C9_PROJECT | sed -e 's/\$//'  | awk -F '\\-Cloud' '{print $1}')" | tee -a ~/.bash_profile
source ~/.bash_profile
```

1.3. Crie o arquivo declarativo com a estrutura de entrega do Cluster

```sh
cat << EOF > eks-eksctl.yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${EKS_CLUSTER}
  region: ${AWS_REGION}
  version: "1.21"

availabilityZones: ["${AZS[0]}", "${AZS[1]}", "${AZS[2]}"]

managedNodeGroups:
- name: nodegroup-${C9_PID}
  desiredCapacity: 3
  instanceType: t3.small
  ssh:
    enableSsm: true

# To enable all of the control plane logs, uncomment below:
# cloudWatch:
#  clusterLogging:
#    enableTypes: ["*"]

secretsEncryption:
  keyARN: ${MASTER_ARN}
EOF

```

1.4. Utilize o eksctl para criar o cluster de eks:

```sh
eksctl create cluster -f eks-eksctl.yaml 
```

> Aguarde até que o cluster seja criado, o processo deverá demorar cerca de 15 minutos para ser finalizado;

1.5. Atualize o arquivo kubeconfig para interagir com seu cluster:

```sh
aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${AWS_REGION}
```

1.6. Fechando o processo de criação valide o acesso ao cluster via kubectl:

```sh
kubectl get nodes
```

---

## Configurando o Istio para Service Mesh

2. Existem várias ferramentas que podem ser exploradas em processos de deployment e na evolução de estratégias de entrega, em especial para o modelo Canary e estratégias similares, uma arquitetura baseada em Service Mesh ou [API Gateways](https://www.getambassador.io/docs/edge-stack/latest/topics/using/canary/) fornecerá um mecanismo seguro para o chaveamento de versões e entregas controladas com base em características como HEADERS de requisição, alteração de versão e similares.

Em nosso modelo exploraremos o Istio Service Mesh configurado sobre um [Ambiente EKS na AWS](https://www.eksworkshop.com/advanced/310_servicemesh_with_istio/);

Antes de começarmos a configurar o Istio, vale entender a layout do ambiente que será usado como base para o roteiro, o Istio oferece uma camada de [Service Mesh](https://istio.io/latest/about/service-mesh/) para orquestrar o tráfego entre micro serviços distribuídos a partir de uma camada de infraestrutura;

Mais detalhes sobre a arquitetura do Istio podem ser consultados na documentação do projeto disponível em [https://istio.io/latest/docs/](https://istio.io/latest/docs/);

Para execução dos testes será feito a entrega da App Bookinfo no namespace de mesmo nome, essa aplicação possui o layout descrito no desenho de arquitetura abaixo:

![alt tag](https://github.com/FiapDevOps/automation/blob/dcc279337cce26af494f562c9c1fbeef04de413c/eks-canary/images/istio_bookinfo_architecture.png)

A app Bookinfo é dividida em quatro microsserviços separados:

- **productpage:** Microsserviço productpage chama os microsserviços de detalhes e revisões para preencher a página.
- **details:** Microsserviço de detalhes contém informações do livro.
- **reviews:** Microsserviço de resenhas contém resenhas de livros. Ele também chama o microsserviço de classificações.
- **ratings:** Microsserviço de classificações contém informações de classificação de livros que acompanham uma resenha de livro.

Existem 3 versões do microsserviço de avaliações:

- **Versão v1:** Não faz a chamada para o serviço ratings.
- **Versão v2:** Faz a chamada para o serviço ratings e exibe cada classificação como 1 a 5 estrelas pretas.
- **Versão v3:** Faz a chamada para o serviço ratings e exibe cada classificação como 1 a 5 estrelas vermelhas.

Todo o acesso será feito utilizando um Gateway de frontend responsável por receber o tráfego e rotear para a versão desejada da aplicação conforme as regras a serem entregues em nosso cluster como recursos de Virtual Gateway dentro do Istio.

Etapas de construção:

| Roteiro       | Descrição |
|-------------------|-----------|
| [Introdução](https://www.eksworkshop.com/advanced/310_servicemesh_with_istio/introduction/) | Documentação base sobre o uso do Istio para Service Mesh | 
| [Download do CLI](https://www.eksworkshop.com/advanced/310_servicemesh_with_istio/download/) | Instalação do cliente de linha de comando | 
| [Instalação do Istio](https://www.eksworkshop.com/advanced/310_servicemesh_with_istio/install/) | Instalação do Istio no cluster eks | 
| [Deploy](https://www.eksworkshop.com/advanced/310_servicemesh_with_istio/deploy/) | Entrega da aplicação de testes Bookinfo |
| [Roteamento de Tráfego](https://www.eksworkshop.com/advanced/310_servicemesh_with_istio/routing/) | Validar estratégias de roteamento usando Canary |

---

##### Fiap - MBA
profhelder.pereira@fiap.com.br

**Free Software, Hell Yeah!**
