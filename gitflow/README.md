# GitFlow - Framework de Plugins para Hooks Git

Um framework flexível para criar, gerenciar e usar plugins de hooks Git com foco em controle de versão e automação de documentação.

## Visão Geral

GitFlow fornece:
- Sistema robusto de controle de versão semântica
- Automação de documentação API via Postman
- Arquitetura baseada em plugins para hooks
- Gerenciamento de configuração flexível
- Ferramentas de desenvolvimento integradas

## Requisitos

- Ubuntu 22.04 LTS (Jammy)
- Git >= 2.34.1 
- Python >= 3.8.0
- jq
- curl

## Instalação

```bash
# Via pacote .deb
sudo apt-get update
sudo apt-get install -y git curl python3 jq

# Instalar GitFlow
cd build/
sudo dpkg -i gitflow_*_all.deb
sudo apt-get install -f
cd ..

# Via código fonte
sudo apt-get install -y build-essential devscripts debhelper
./scripts/build.sh
```

### Basic Usage

#### Controle de Versão

```bash
# Inicializar versão
gitflow --init-fork

# Incrementar versão major
gitflow --increment-major

# Consultar versão atual
gitflow --get-version

# Definir versão manualmente
gitflow --set-version v1.2.3.4
```

#### Plugins
```bash
# Listar plugins disponíveis
gitflow --list-hooks

# Instalar plugin
gitflow --install-hook doc-update-hook

# Configurar plugin
gitflow --config
```

...existing code...

### Plugins Oficiais

#### version-update-hook
- Controle de versão semântica automatizado
- Incremento baseado em branches
- Suporte a tags de release
- Resolução de conflitos de merge

### Plugins da Comunidade

#### doc-update-hook
- Atualização automática de documentação API
- Integração com Postman Collections
- Normalização de URLs
- Versionamento de endpoints

## Arquitetura

```
/usr/share/gitflow/
├── lib/                    # Bibliotecas core
│   ├── utils.sh           # Utilitários compartilhados  
│   ├── git.sh             # Operações Git
│   └── version-control.sh # Controle de versão
├── plugins/
│   ├── official/          # Plugins oficiais
│   ├── community/         # Plugins da comunidade
│   └── templates/         # Templates de plugins
└── config/                # Configuração global
```

## Desenvolvimento de Plugins

```
plugin-name/
├── events/              
│   ├── pre-commit/     # Handler pre-commit
│   └── post-commit/    # Handler post-commit
├── lib/                # Funções compartilhadas
├── config/             # Configuração do plugin
└── metadata.json       # Metadados do plugin
```

### Exemplo de `metadata.json`

```json
{
    "name": "my-plugin",
    "version": "1.0.0",
    "description": "Plugin description", 
    "author": "Your Name",
    "events": ["pre-commit", "post-commit"],
    "dependencies": {
        "git": ">=2.34.1"
    }
}
```

## Contribuindo

- Fork o repositório
- Crie sua branch de feature
- Escreva testes
- Envie um pull request

## Licença

MIT License