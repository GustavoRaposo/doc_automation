# Documentação do Projeto GitFlow

## Sobre o Projeto

Este projeto visa fornecer um ambiente de desenvolvimento robusto e isolado para o framework de hooks GitFlow. Ele utiliza o Vagrant para criar uma máquina virtual (VM) com todas as dependências necessárias, garantindo um ambiente de desenvolvimento consistente para todos os colaboradores, independentemente de seus sistemas operacionais.

## Propósito

O principal objetivo deste projeto é facilitar o desenvolvimento e teste de hooks GitFlow, permitindo que os desenvolvedores criem e modifiquem hooks sem afetar seus ambientes locais. O ambiente isolado também garante que todos os colaboradores trabalhem com a mesma configuração, evitando problemas de compatibilidade e garantindo a consistência dos testes.

## Ambiente de Desenvolvimento

O ambiente de desenvolvimento pode ser configurado de três maneiras:

### 1. Máquina Raiz

*   **Prós**:*
    * Sem necessidade de software adicional (Vagrant, VirtualBox).
    * Acesso direto aos arquivos do projeto.
*   **Contras**:*
    * Requer configuração manual do ambiente.
    * Risco de conflitos com outras ferramentas.
    * Dificuldade em reproduzir o ambiente em outras máquinas.
*   **Instruções**:*
    1. Clone o repositório para um diretório de sua escolha.
    2. Instale as dependências necessárias (listadas na seção "Dependências").
    3. Configure o GitFlow conforme as instruções do projeto.

### 2. Vagrant

*   **Prós**:*
    * Ambiente isolado e consistente.
    * Fácil configuração e reprodução.
    * Segurança contra danos ao sistema hospedeiro.
*   **Contras**:*
    * Requer instalação do Vagrant e VirtualBox.
    * Pode ser mais lento que o desenvolvimento na máquina raiz.
*   **Instruções**:*
    1. Instale o Vagrant e o VirtualBox.
    2. Clone o repositório.
    3. Execute `vagrant up` para iniciar a máquina virtual.
    4. Acesse a máquina virtual via SSH com `vagrant ssh`.
    5. O diretório do projeto estará disponível em `/home/vagrant/gitflow`.

### 3. Instalação via .deb

*   **Prós**:*
    * Fácil instalação e remoção.
    * Integração com o sistema operacional.
*   **Contras**:*
    * Requer a construção do pacote .deb.
    * Menos flexível para desenvolvimento.
*   **Instruções**:*
    1. Construa o pacote .deb (consulte a seção "Construindo o Projeto").
    2. Instale o pacote .deb com `sudo dpkg -i gitflow.deb`.

## Dependências

As dependências do projeto variam dependendo do método de desenvolvimento escolhido. Consulte a documentação específica para cada método para obter a lista completa de dependências.

## Construindo o Projeto

Para construir o projeto e gerar o pacote .deb, siga as instruções abaixo (dentro da VM Vagrant ou em um ambiente com as dependências instaladas):

```bash
cd ~/gitflow
./scripts/build.sh
```


2.0 Flash Experimental. Pode não funcionar conforme o esperado.
Markdown

# Documentação do Projeto GitFlow

## Sobre o Projeto

Este projeto visa fornecer um ambiente de desenvolvimento robusto e isolado para o framework de hooks GitFlow. Ele utiliza o Vagrant para criar uma máquina virtual (VM) com todas as dependências necessárias, garantindo um ambiente de desenvolvimento consistente para todos os colaboradores, independentemente de seus sistemas operacionais.

## Propósito

O principal objetivo deste projeto é facilitar o desenvolvimento e teste de hooks GitFlow, permitindo que os desenvolvedores criem e modifiquem hooks sem afetar seus ambientes locais. O ambiente isolado também garante que todos os colaboradores trabalhem com a mesma configuração, evitando problemas de compatibilidade e garantindo a consistência dos testes.

## Ambiente de Desenvolvimento

O ambiente de desenvolvimento pode ser configurado de duas maneiras:

### 1. Root System

*   **Prós**:*
    * Sem necessidade de software adicional (Vagrant, VirtualBox).
    * Acesso direto aos arquivos do projeto.
*   **Contras**:*
    * Requer configuração manual do ambiente.
    * Risco CRÍTICO de conflitos com outras ferramentas e dependências.
    * Dificuldade em reproduzir o ambiente em outras máquinas.
*   **Instruções**:*

```
    git clone git@github.com:GustavoRaposo/doc_automation.git
    cd gitflow
    sudo apt-get install -y build-essential devscripts debhelper
    ./scripts/build.sh
```

### 2. Vagrant (Recomendado)

*   **Prós**:*
    * Ambiente isolado e consistente.
    * Fácil configuração e reprodução.
    * Segurança contra danos ao sistema hospedeiro.
*   **Contras**:*
    * Requer instalação do Vagrant e VirtualBox.
    * Pode ser mais lento que o desenvolvimento na máquina raiz.
*   **Instruções**:*


Antes de começar, certifique-se de ter instalado em sua máquina:

- [VirtualBox](https://www.virtualbox.org/) (versão mais recente)
- [Vagrant](https://www.vagrantup.com/) (versão mais recente)

Início Rápido

1. Clone o repositório:
```bash
git clone https://github.com/yourusername/gitflow-dev.git
cd gitflow-dev
```

2. Inicie o ambiente de desenvolvimento:
```bash
vagrant up
```

3. Conecte-se à máquina virtual:
```bash
vagrant ssh
```

Especificações da VM
- Ubuntu 22.04 LTS
- 2GB de RAM
- 2 núcleos de CPU
- Configuração de rede isolada
- Acesso restrito a dispositivos
- Ferramentas de desenvolvimento dedicadas

Configurando Integração com VS Code

1. Gere uma chave SSH na VM:
```bash
vagrant ssh
ssh-keygen -t rsa -b 4096
cat ~/.ssh/id_rsa.pub
```

2. Adicione a chave à configuração SSH do VS Code:
```bash
# Na sua máquina host, edite ~/.ssh/config
Host gitflow-dev
    HostName localhost
    User vagrant
    Port 2222
    IdentityFile ~/.ssh/gitflow_dev_key
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no
    PasswordAuthentication no
    IdentitiesOnly yes
    LogLevel FATAL
```

3. Conecte usando VS Code:
   - Instale a extensão "Remote - SSH"
   - Clique em Remote Explorer
   - Selecione "gitflow-dev" da lista de hosts
  
### Recursos de Isolamento

Este ambiente de desenvolvimento fornece:
- ✅ Gerenciamento isolado de pacotes
- ✅ Acesso restrito a dispositivos
- ✅ Acesso controlado à rede
- ✅ Espaço de desenvolvimento separado
- ✅ Ambiente de build limpo

Verifique o status do isolamento:
```bash
check-isolation
```

### Tarefas Comuns

#### Recriando o Ambiente
```bash
vagrant destroy -f
vagrant up
```

#### Atualizando Dependências
```bash
vagrant ssh
sudo apt-get update
sudo apt-get upgrade
```

#### Gerenciando a VM
- Iniciar VM: `vagrant up`
- Parar VM: `vagrant halt`
- Excluir VM: `vagrant destroy`
- Recarregar VM: `vagrant reload`

### Solução de Problemas

#### Problemas de Permissão
Se encontrar problemas de permissão:
```bash
# Dentro da VM
chmod +x scripts/*.sh
sudo chown -R vagrant:vagrant ~/gitflow
```

### Notas de Segurança

- O ambiente de desenvolvimento está isolado do seu sistema host
- Todo desenvolvimento deve ser feito dentro da VM
- Não desabilite recursos de segurança no Vagrantfile
- Mantenha VirtualBox e Vagrant atualizados

## Simples instalação do gerenciador via .deb

```
sudo apt-get update
cd build/
sudo dpkg -i gitflow_*_all.deb
sudo apt-get install -f
cd ..
```

## Dependências

As dependências do projeto variam dependendo do método de desenvolvimento escolhido. Consulte a documentação específica para cada método para obter a lista completa de dependências.

## Fluxo de Desenvolvimento

### Compilando o Projeto
```bash
cd ~/gitflow
./scripts/build.sh
```

### Executando Testes
```bash
cd ~/gitflow
./scripts/test.sh
```

### Criando Novos Plugins
1. Crie o diretório do plugin:
```bash
mkdir -p plugins/community/nome-do-seu-plugin
```

2. Copie os arquivos de template:
```bash
cp -r plugins/templates/basic/* plugins/community/nome-do-seu-plugin/
```

3. Implemente a lógica do seu plugin no diretório events.

## Troubleshooting

### Falhas no Build
1. Verifique as permissões dos scripts
2. Confirme se todas as dependências estão instaladas
3. Garanta a estrutura correta de diretórios

### Problemas de Conexão com VS Code
1. Verifique a configuração SSH
2. Verifique o redirecionamento de porta
3. Regenere as chaves SSH se necessário

## Contribuindo
🚧🚧🚧

## Licença
🚧🚧🚧
