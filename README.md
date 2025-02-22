# [SYSTEM CORE] Portainer + Traefik Deployer

Bem-vindo ao **Portainer + Traefik Deployer**, uma ferramenta de automação para implantar o **Portainer** (gerenciamento de containers Docker) e o **Traefik** (proxy reverso) com SSL integrado via Let’s Encrypt. Desenvolvido por **Maicon Bartoski**, este script oferece uma solução eficiente e segura para orquestração de containers.

---

## [FEATURES ONLINE]

- **[Portainer CE]**: Interface gráfica para gerenciamento de Docker.
- **[Traefik Proxy]**: Proxy reverso com SSL automático.
- **[SSL Automation]**: Certificados Let’s Encrypt configurados em tempo real.
- **[Secure Config]**: Credenciais criptográficas e setup otimizado.

---

## [SYSTEM REQUIREMENTS]

Antes de iniciar, verifique os requisitos mínimos do sistema:

- **[OS]**: Ubuntu 20.04 LTS ou superior (recomendado).
- **[Disk Space]**: ≥ 10 GB livres.
- **[RAM]**: ≥ 2 GB disponíveis.
- **[Network]**: Conexão ativa com a internet para downloads e SSL.
- **[Privileges]**: Execução como root ou via `sudo`.

---

## [DEPLOYMENT PROTOCOL]

Siga os passos abaixo para ativar o sistema em seu servidor:

### 1. [DOWNLOAD MODULE]
Obtenha o script diretamente do repositório:

```bash
wget <URL_DO_SCRIPT> -O install_portainer.sh
```

**Nota**: Substitua `<URL_DO_SCRIPT>` pelo link oficial do arquivo.

### 2. [EXECUTE CORE]
Inicie o script com os parâmetros necessários:

```bash
sudo ./install_portainer.sh <traefik_domain> <portainer_domain> <email>
```

- `<traefik_domain>`: Endereço do dashboard Traefik (ex.: `traefik.meudominio.com`).
- `<portainer_domain>`: Endereço do Portainer (ex.: `portainer.meudominio.com`).
- `<email>`: E-mail para registro SSL.

**Exemplo:**
```bash
sudo ./install_portainer.sh traefik.meudominio.com portainer.meudominio.com meuemail@exemplo.com
```

### 3. [SELECT OPERATION]
O sistema exibirá uma interface interativa:

- **[1] Deploy Portainer**: Inicia a configuração completa.
- **[2] Reset System**: Remove instalações anteriores (containers, volumes, etc.).
- **[3] Shutdown**: Encerra o processo.

Digite o número correspondente `[1-3]` para prosseguir.

### 4. [AWAIT DEPLOYMENT]
O script instalará dependências, configurará o ambiente e exibirá um progresso dinâmico. Após a conclusão, as credenciais de acesso serão geradas.

---

## [ACCESS CREDENTIALS]

Ao finalizar, o sistema fornecerá:

- **[Portainer URL]**: `https://<portainer_domain>`
- **[Portainer User]**: Seu e-mail informado.
- **[Portainer Key]**: Chave gerada (16 bytes hexadecimais).
- **[Traefik URL]**: `https://<traefik_domain>`
- **[Traefik User]**: `admin`
- **[Traefik Key]**: `admin`

**ALERT**: Armazene essas credenciais em um local seguro!

---

## [PROJECT STRUCTURE]

- **`install_portainer.sh`**: Módulo principal de execução.
- **`docker-compose.yml`**: Arquivo gerado em `~/Portainer` com a configuração dos serviços.

---

## [SYSTEM NOTES]

- **[Backup]**: Instalações anteriores em `~/Portainer` serão salvas automaticamente antes da nova implantação.
- **[Reset]**: A opção `[2]` elimina todos os containers, volumes, redes e imagens Docker. Use com cuidado.
- **[Logs]**: O Traefik opera com logs no nível `ERROR`. Ajuste no `docker-compose.yml` se necessário.

---

## [TROUBLESHOOTING]

- **[Disk/RAM Error]**: Verifique os requisitos e libere recursos.
- **[Network Failure]**: Confirme a conectividade com a internet.
- **[Portainer Offline]**: Inspecione os logs via `docker logs portainer`.

---

## [CONTRIBUTION MODULE]

Desenvolvido por **Maicon Bartoski**. Para feedback ou melhorias:

- **Contact**: contato@maiconbartoski.com
- **Issues**: Abra uma solicitação no repositório.

---

## [LICENSE PROTOCOL]

Distribuído sob a **Licença MIT**. Consulte o arquivo `LICENSE` para detalhes (se aplicável).
