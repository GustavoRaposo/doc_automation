# GitFlow - Gerenciador de Hooks

## Sobre o Projeto

O GitFlow é um gerenciador e instalador de hooks (também chamados de plugins), projetado para automatizar tarefas relacionadas a versionamento, documentação, CI/CD (Integração Contínua e Entrega Contínua) e outras atividades do fluxo de trabalho de desenvolvimento. O projeto utiliza uma abordagem modular, permitindo a criação e integração de hooks personalizados para atender às necessidades específicas de cada equipe ou projeto.

Além disso, o GitFlow oferece um ambiente de desenvolvimento robusto e isolado, construído com o Vagrant, que garante consistência e compatibilidade entre diferentes sistemas operacionais. Isso facilita o desenvolvimento e teste de hooks sem interferir no ambiente local do desenvolvedor.

## Propósito

O objetivo principal do GitFlow é:

1. Fornecer um Gerenciador de Hooks:

    - Facilitar a instalação, remoção, ativação e desativação de hooks.

    - Permitir a criação e uso de hooks personalizados.

2. Ser um Repositório de Hooks:

    - Oferecer um catálogo de hooks prontos para uso.

    - Promover a extensibilidade do sistema com novos hooks.

3. Garantir Consistência no Ambiente de Desenvolvimento:

    - Utilizar o Vagrant para criar uma máquina virtual (VM) com todas as dependências necessárias.

    - Isolar o ambiente de desenvolvimento, evitando conflitos e problemas de compatibilidade.

4. Facilitar o Desenvolvimento Colaborativo:

    - Prover um ambiente padronizado para todos os colaboradores.

    - Simplificar o processo de teste e depuração de hooks.

## Funcionalidades Principais

### Core do GitFlow

- Gerenciador de Hooks:

    - Instalação e remoção de hooks.

    Ativação e desativação de hooks.

- Repositório de Hooks:

    - Catálogo de hooks disponíveis para download e uso.

    - Suporte para hooks personalizados.

- Ambiente de Desenvolvimento Isolado:

    - Configuração simplificada com Vagrant.

    - Compatibilidade multiplataforma (Windows, macOS, Linux).

## Instruções de Uso do GitFlow Hook Manager

O **GitFlow Hook Manager** é uma ferramenta para gerenciar hooks (ganchos) Git de forma modular. Ele permite instalar, desinstalar, reinstalar e configurar hooks personalizados para automatizar tarefas no fluxo de trabalho de desenvolvimento.

### Como Usar

#### Comandos Disponíveis

O GitFlow Hook Manager suporta os seguintes comandos:

1. **Instalar um Hook**:
   ```bash
   gitflow install <nome-do-hook>
   ```
   Exemplo:
   ```bash
   gitflow install doc-update-hook
   ```

2. **Desinstalar um Hook**:
   ```bash
   gitflow uninstall <nome-do-hook>
   ```
   Exemplo:
   ```bash
   gitflow uninstall pre-commit
   ```

3. **Reinstalar um Hook**:
   ```bash
   gitflow reinstall <nome-do-hook>
   ```
   Exemplo:
   ```bash
   gitflow reinstall doc-update-hook
   ```

4. **Listar Hooks Disponíveis**:
   ```bash
   gitflow list
   ```

5. **Configurar um Hook**:
   ```bash
   gitflow config <nome-do-hook>
   ```
   Exemplo:
   ```bash
   gitflow config doc-update-hook
   ```

6. **Exibir Ajuda**:
   ```bash
   gitflow --help
   ```

7. **Exibir Versão**:
   ```bash
   gitflow --version
   ```

---

#### Opções Adicionais

- **`--force`**:
  Força a instalação ou desinstalação de um hook, mesmo que já esteja instalado ou não exista.
  Exemplo:
  ```bash
  gitflow install doc-update-hook --force
  ```

- **`--help`**:
  Exibe a mensagem de ajuda com todos os comandos e opções disponíveis.

- **`--version`**:
  Exibe a versão atual do GitFlow Hook Manager.

---

#### Requisitos

- **Git**:
  O GitFlow Hook Manager deve ser executado em um repositório Git válido. Certifique-se de que o diretório atual seja um repositório Git.

- **Permissões**:
  Alguns comandos podem exigir permissões de administrador (sudo) para instalar ou desinstalar hooks.

---

## Instalação do gerenciador via .deb

[Download GitFlow Debian Package](https://github.com/GustavoRaposo/doc_automation/blob/feature/dev_env_impl/gitflow/build/gitflow_0.1.0_all.deb)

```
sudo apt-get update
sudo dpkg -i gitflow_*_all.deb
sudo apt-get install -f
```

## Como utilizar



## Contribuindo

### Ambiente de Desenvolvimento

O ambiente de desenvolvimento pode ser configurado de duas maneiras:

#### 1. Root System

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

#### 2. Vagrant (Recomendado)

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
  
#### Recursos de Isolamento

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

#### Tarefas Comuns

##### Recriando o Ambiente
```bash
vagrant destroy -f
vagrant up
```

##### Atualizando Dependências
```bash
vagrant ssh
sudo apt-get update
sudo apt-get upgrade
```

##### Gerenciando a VM
- Iniciar VM: `vagrant up`
- Parar VM: `vagrant halt`
- Excluir VM: `vagrant destroy`
- Recarregar VM: `vagrant reload`

#### Solução de Problemas

##### Problemas de Permissão
Se encontrar problemas de permissão:
```bash
# Dentro da VM
chmod +x scripts/*.sh
sudo chown -R vagrant:vagrant ~/gitflow
```

#### Notas de Segurança

- O ambiente de desenvolvimento está isolado do seu sistema host
- Todo desenvolvimento deve ser feito dentro da VM
- Não desabilite recursos de segurança no Vagrantfile
- Mantenha VirtualBox e Vagrant atualizados

#### Dependências

As dependências do projeto variam dependendo do método de desenvolvimento escolhido. Consulte a documentação específica para cada método para obter a lista completa de dependências.

### Fluxo de Desenvolvimento

#### Compilando o Projeto
```bash
cd ~/gitflow
./scripts/build.sh
```

#### Executando Testes
```bash
cd ~/gitflow
./scripts/test.sh
```

#### Criando Novos Plugins
1. Crie o diretório do plugin:
```bash
mkdir -p plugins/community/nome-do-seu-plugin
```

2. Copie os arquivos de template:
```bash
cp -r plugins/templates/basic/* plugins/community/nome-do-seu-plugin/
```

3. Implemente a lógica do seu plugin no diretório events.

### Troubleshooting

#### Falhas no Build
1. Verifique as permissões dos scripts
2. Confirme se todas as dependências estão instaladas
3. Garanta a estrutura correta de diretórios

#### Problemas de Conexão com VS Code
1. Verifique a configuração SSH
2. Verifique o redirecionamento de porta
3. Regenere as chaves SSH se necessário

## Licença
🚧🚧🚧
