# Ambiente de Desenvolvimento GitFlow

Este repositório fornece um ambiente de desenvolvimento isolado para o framework de hooks GitFlow usando Vagrant. Esta configuração garante um desenvolvimento consistente em diferentes máquinas e evita qualquer interferência com seu sistema principal.

## Pré-requisitos

Antes de começar, certifique-se de ter instalado em sua máquina:

- [VirtualBox](https://www.virtualbox.org/) (versão mais recente)
- [Vagrant](https://www.vagrantup.com/) (versão mais recente)
- Git

## Início Rápido

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

4. O diretório do projeto está montado em `/home/vagrant/gitflow` na máquina virtual.

## Detalhes do Ambiente de Desenvolvimento

### Estrutura de Diretórios
```
gitflow-dev/
├── Vagrantfile           # Configuração da VM
├── gitflow/             # Diretório do projeto (sincronizado com a VM)
│   ├── lib/            # Arquivos de biblioteca
│   ├── plugins/        # Diretório de plugins
│   ├── scripts/        # Scripts de build
│   └── debian/         # Configuração do pacote Debian
└── README.md           # Este arquivo
```

### Especificações da VM
- Ubuntu 22.04 LTS
- 2GB de RAM
- 2 núcleos de CPU
- Configuração de rede isolada
- Acesso restrito a dispositivos
- Ferramentas de desenvolvimento dedicadas

## Configurando Integração com VS Code

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

## Recursos de Isolamento

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

## Tarefas Comuns

### Recriando o Ambiente
```bash
vagrant destroy -f
vagrant up
```

### Atualizando Dependências
```bash
vagrant ssh
sudo apt-get update
sudo apt-get upgrade
```

### Gerenciando a VM
- Iniciar VM: `vagrant up`
- Parar VM: `vagrant halt`
- Excluir VM: `vagrant destroy`
- Recarregar VM: `vagrant reload`

## Solução de Problemas

### Problemas de Permissão
Se encontrar problemas de permissão:
```bash
# Dentro da VM
chmod +x scripts/*.sh
sudo chown -R vagrant:vagrant ~/gitflow
```

### Falhas no Build
1. Verifique as permissões dos scripts
2. Confirme se todas as dependências estão instaladas
3. Garanta a estrutura correta de diretórios

### Problemas de Conexão com VS Code
1. Verifique a configuração SSH
2. Verifique o redirecionamento de porta
3. Regenere as chaves SSH se necessário

## Contribuindo

1. Faça um fork do repositório
2. Crie sua branch de feature
3. Faça commit das suas alterações
4. Faça push para a branch
5. Crie um Pull Request

## Notas de Segurança

- O ambiente de desenvolvimento está isolado do seu sistema host
- Todo desenvolvimento deve ser feito dentro da VM
- Não desabilite recursos de segurança no Vagrantfile
- Mantenha VirtualBox e Vagrant atualizados

## Suporte

Para problemas e dúvidas:
- Abra uma issue no repositório
- Verifique issues existentes para soluções
- Forneça detalhes do ambiente ao reportar problemas

## Licença

[Sua Licença] - veja o arquivo [LICENSE.md](LICENSE.md) para detalhes

---

## Dicas Adicionais

### Primeiro Acesso
Após iniciar a VM pela primeira vez, é recomendado:
1. Verificar o isolamento com `check-isolation`
2. Atualizar os pacotes do sistema
3. Configurar seu nome e email no git

### Melhores Práticas
- Sempre trabalhe dentro da VM
- Faça commits frequentes
- Mantenha os scripts com permissão de execução
- Teste suas alterações antes de fazer push

### Comandos Úteis
```bash
# Verificar status do ambiente
check-isolation

# Listar plugins instalados
ls plugins/community/

# Verificar logs de build
cat build.log
```

### Desenvolvimento de Plugins
1. Use o template básico como referência
2. Siga as convenções de nomenclatura
3. Documente seu código
4. Inclua testes unitários

### Problemas Conhecidos

1. **Erro de Permissão ao Executar Scripts**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **VM Não Inicia**
   - Verifique se VirtualBox está instalado
   - Confirme que virtualização está habilitada na BIOS

3. **Sincronização de Arquivos**
   - Verifique permissões do diretório
   - Reinicie a VM se necessário

4. **Problemas de Rede**
   - Confirme configurações do VirtualBox
   - Verifique firewall do host