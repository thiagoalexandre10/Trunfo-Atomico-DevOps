# Trunfo Atômico — DevOps

**Challenge FIAP 2026 — Sprint 1**  
**Parceiro:** AMAZUL / CTMSP  
**Disciplina:** DevOps Tools & Cloud Computing  
**Turma:** 2TDSPR

## Integrantes

| Integrante | RM |
|---|---|
| Diego Paulino | 566841 |
| Guilherme Dabul | 559901 |
| Renan Lima | 568321 |
| Ryan Mazali | 567168 |
| Thiago Alexandre | 567486 |

## Sobre o projeto

O **Trunfo Atômico** é um jogo educativo de cartas sobre isótopos e aplicações da tecnologia nuclear. Nesta Sprint, a equipe desenvolveu componentes da solução e demonstrou a infraestrutura necessária para hospedar a API do catálogo.

A entrega de DevOps demonstra o **provisionamento de uma máquina virtual Linux no Microsoft Azure por Azure CLI**, a **containerização da API Java com Docker**, a disponibilização de endpoints REST por IP público e a **exclusão dos recursos** ao final dos testes.

## Arquitetura da solução

![Arquitetura da solução Trunfo Atômico](arquitetura.png)

- **Aplicativo Flutter:** interface do jogo. Nesta Sprint, utiliza **dados simulados**; a integração REST com a API é uma evolução prevista, não uma integração já concluída.
- **Microsoft Azure:** VM `vm-trunfo-atomico`, Ubuntu Server 22.04 LTS, na região **Spain Central (`spaincentral`)**.
- **Tamanho da VM:** `Standard_B2ls_v2` (2 vCPUs e 4 GiB de memória RAM).
- **Docker:** executa a imagem `trunfo-atomico-api:1.0`, construída com Java 25.
- **API:** Java 25 e Spring Boot, com endpoints `/areas` e `/isotopos`.
- **Persistência:** banco de dados H2 em volume Docker `trunfo-h2`, montado em `/app/data`.
- **Rede:** porta TCP `8080`, liberada temporariamente para o IP de origem autorizado durante a demonstração.

## Tecnologias

Java 25 · Spring Boot · Maven · Docker Engine · Azure CLI · Azure Virtual Machines · Ubuntu Linux · H2 · GitHub

## Repositórios

- **DevOps:** https://github.com/thiagoalexandre10/Trunfo-Atomico-DevOps
- **API Java:** https://github.com/DiegoCPaulino/API-Trunfo-Atomico

## Arquivos da entrega DevOps

| Arquivo | Finalidade |
|---|---|
| `provisionar.sh` | Automatiza a criação do grupo de recursos e da VM Azure e consulta o IP público. |
| `Dockerfile` | Build multi-stage com Java 25: compila a API usando Maven e gera a imagem de execução. |
| `.dockerignore` | Exclui arquivos desnecessários do contexto de build. |
| `arquitetura.png` | Diagrama da arquitetura do projeto. |
| `README.md` | Documenta a implantação, os testes e o encerramento dos recursos. |

## 1. Pré-requisitos

- Uma assinatura Azure com permissão e cota disponíveis para criar uma VM na região selecionada.
- Azure CLI instalado e autenticado (`az login`).
- Bash disponível para executar o script `.sh` (por exemplo, Git Bash no Windows).
- Git e acesso aos dois repositórios públicos.

> **Atenção:** criar recursos Azure pode gerar custos. Os comandos devem ser executados apenas em uma assinatura autorizada. A disponibilidade do tamanho escolhido depende da assinatura, da região e da capacidade do Azure.

## 2. Provisionar a VM pelo Azure CLI

No terminal **Git Bash** do Windows, a partir da pasta deste repositório:

```bash
az account show --output table
bash provisionar.sh
```

O script utiliza as configurações:

```bash
RG="rg-trunfo-atomico"
VM="vm-trunfo-atomico"
LOCATION="spaincentral"
SIZE="Standard_B2ls_v2"
USER_NAME="azureuser"
```

Verifique o resultado da criação e obtenha o IP público:

```bash
az vm list --resource-group rg-trunfo-atomico --show-details --output table
az vm show -d --resource-group rg-trunfo-atomico --name vm-trunfo-atomico --query publicIps --output tsv
```

O script cria a VM com imagem Ubuntu 22.04 e gera chaves SSH caso necessário.

## 3. Conectar à VM e instalar o Docker

Substitua `IP_PUBLICO_DA_VM` pelo endereço retornado pelo comando anterior:

```bash
ssh azureuser@IP_PUBLICO_DA_VM
```

**Os comandos abaixo são executados dentro do Ubuntu, via SSH:**

```bash
sudo apt update
sudo apt install -y ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Configure o repositório oficial do Docker:

```bash
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF2
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF2

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
sudo docker --version
sudo docker run --rm hello-world
```

A saída `Hello from Docker!` confirma a instalação funcional do Docker Engine.

## 4. Construir a imagem e executar o container

Ainda dentro da VM, obtenha a API e os arquivos de containerização:

```bash
git clone https://github.com/DiegoCPaulino/API-Trunfo-Atomico.git
cd API-Trunfo-Atomico
curl -fL https://raw.githubusercontent.com/thiagoalexandre10/Trunfo-Atomico-DevOps/main/Dockerfile -o Dockerfile
curl -fL https://raw.githubusercontent.com/thiagoalexandre10/Trunfo-Atomico-DevOps/main/.dockerignore -o .dockerignore
```

Construa a imagem Docker:

```bash
sudo docker build -t trunfo-atomico-api:1.0 .
sudo docker images
```

Crie o volume persistente e inicie a API:

```bash
sudo docker volume create trunfo-h2
sudo docker run -d --name trunfo-api -p 8080:8080 -v trunfo-h2:/app/data trunfo-atomico-api:1.0
sudo docker ps
sudo docker logs --tail 30 trunfo-api
```

Teste localmente **dentro da VM**:

```bash
curl -f http://localhost:8080/areas
curl -f 'http://localhost:8080/isotopos?size=20'
```

O volume `trunfo-h2` armazena os dados persistentes do H2 separadamente do ciclo de vida do container.

## 5. Liberar temporariamente a porta 8080

Saia da sessão SSH (`exit`) para retornar ao terminal local com o Azure CLI.

Identifique o grupo de segurança de rede (NSG) da VM:

```bash
az network nsg list --resource-group rg-trunfo-atomico --output table
```

No provisionamento demonstrado, o NSG recebeu o nome `vm-trunfo-atomicoNSG`.

Crie uma regra para permitir **somente o IPv4 público atual do computador que realizará o teste**:

```bash
az network nsg rule create --resource-group rg-trunfo-atomico --nsg-name vm-trunfo-atomicoNSG --name PermitirTrunfoDemo --priority 1010 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "$(curl -4 -s https://api.ipify.org)/32" --destination-port-ranges 8080
```

Confira a regra:

```bash
az network nsg rule list --resource-group rg-trunfo-atomico --nsg-name vm-trunfo-atomicoNSG --output table
```

> A API é apresentada por HTTP para fins de demonstração. Este acesso não constitui uma configuração de produção; não exponha interfaces administrativas ou o console do banco de dados.

## 6. Testar os endpoints pelo IP público

Abra no navegador, substituindo `IP_PUBLICO_DA_VM` pelo IP da VM:

| Recurso | Endereço |
|---|---|
| Áreas | `http://IP_PUBLICO_DA_VM:8080/areas` |
| Isótopos | `http://IP_PUBLICO_DA_VM:8080/isotopos?size=20` |
| Swagger UI, quando habilitado | `http://IP_PUBLICO_DA_VM:8080/swagger-ui/index.html` |

A resposta é retornada em **JSON**, conforme o funcionamento de uma API REST. A documentação Swagger, quando disponível, permite consultar os endpoints de maneira interativa.

## 7. Excluir os recursos ao final da demonstração

Após registrar as evidências e confirmar que o grupo contém **apenas os recursos desta atividade**, execute no terminal local:

```bash
az resource list --resource-group rg-trunfo-atomico --output table
az group delete --name rg-trunfo-atomico --yes
az group exists --name rg-trunfo-atomico
```

O resultado esperado da última consulta é `false`, comprovando a exclusão do grupo.

## Como o Docker e a computação em nuvem ajudam o projeto?

O **Docker** reúne a API Java e suas dependências em uma imagem, reduzindo diferenças entre os ambientes de desenvolvimento e de execução. A mesma imagem pode ser testada localmente e implantada em uma VM Linux, enquanto o volume do H2 permite preservar os dados independentemente do container.

A **computação em nuvem** oferece uma infraestrutura remota para disponibilizar a API, realizar testes de conectividade e ampliar a arquitetura nas próximas Sprints. Quando a integração REST for implementada, o aplicativo Flutter poderá consumir os mesmos endpoints do catálogo, em vez dos dados simulados utilizados nesta etapa.

O uso de scripts Azure CLI também facilita a reprodução da infraestrutura e a exclusão controlada dos recursos ao fim de uma demonstração.

## Vídeo da demonstração

**YouTube — vídeo da entrega DevOps:** https://youtu.be/BNrjYQzG4n0

**Visibilidade requerida:** Não listado.

---

**Challenge FIAP 2026 — Trunfo Atômico · DevOps · Sprint 1**
