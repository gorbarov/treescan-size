<p align="center">
  <img src="docs/screenshots/icon.png" width="128" alt="TreeScan Size icon">
</p>

<h1 align="center">TreeScan Size</h1>

<p align="center">
  <b>Veja o que ocupa espaço no seu Mac — como uma árvore de pastas com barras de tamanho.</b><br>
  Gratuito e de código aberto. Sem rede, sem rastreamento. Compatível com Dropbox, iCloud e OneDrive.
</p>

<p align="center">
  <a href="https://github.com/gorbarov/treescan-size/releases/latest"><img src="https://img.shields.io/github/v/release/gorbarov/treescan-size?label=download&color=2a78d6" alt="Download"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-lightgrey" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Apple%20Silicon-native-lightgrey" alt="Apple Silicon">
  <img src="https://img.shields.io/badge/SwiftUI-100%25-orange" alt="SwiftUI">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT"></a>
  <img src="https://img.shields.io/badge/languages-9-blueviolet" alt="9 languages">
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.ru.md">Русский</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <b>Português</b> · <a href="README.ko.md">한국어</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a>
</p>

<p align="center">
  <img src="docs/screenshots/pie-en.png" width="900" alt="TreeScan Size: folder tree with size bars and a chart">
</p>

---

## Por quê

O Finder não consegue dizer quais pastas consumiram o seu disco. A maioria dos analisadores de disco para Mac desenha anéis ou treemaps. **O TreeScan Size mostra a visualização que os usuários de Windows conhecem do TreeSize:** uma árvore de pastas simples em que cada linha tem uma barra de tamanho e sua participação em relação à pasta pai. Role para baixo — e você saberá o que limpar.

## Destaques

|  |  |
|---|---|
| 🌳 **Árvore com barras de tamanho** | Cada pasta mostra seu tamanho e a % em relação à pasta pai, ordenada da maior para a menor. Teclas de seta, clique em qualquer lugar de uma linha. |
| ⚡ **Varredura ao vivo** | A árvore é preenchida enquanto a varredura acontece, com uma barra de progresso real (porcentagem do espaço usado no disco). Sem esperar atrás de um indicador de carregamento. |
| ☁️ **Compatível com a nuvem** | Arquivos "somente online" do Dropbox, iCloud e OneDrive são marcados: eles contam para o seu plano de nuvem, mas não ocupam espaço no Mac. Marque uma pasta do Dropbox como **Não sincronizar** diretamente pelo menu. |
| ⚖️ **Tamanho vs No disco** | *Tamanho* é o que os arquivos pesam e o que as cotas de nuvem contam. *No disco* é o que eles realmente ocupam neste Mac. Um disco de Docker ou VM pode "pesar" 460 GB e usar 39 GB — você vê os dois. |
| 🔍 **Seis visualizações** | Gráfico, Detalhes, Extensões, Idade dos arquivos, Maiores arquivos, Candidatos a duplicata (encontrados sem baixar arquivos da nuvem). |
| 🛡️ **Seguro e privado** | Somente Lixeira, com confirmação; pastas do sistema são protegidas. Sem acesso à rede, sem análises, sem contas. Veja [PRIVACY.md](PRIVACY.md). |
| 🌍 **9 idiomas** | English, 简体中文, 日本語, 한국어, Deutsch, Español, Français, Português, Русский. Tema claro e escuro. |

## Capturas de tela

| Varredura ao vivo | Maiores arquivos | Candidatos a duplicata |
|---|---|---|
| <img src="docs/screenshots/live-en.png" alt="Live scan with progress"> | <img src="docs/screenshots/top-en.png" alt="Top files in a folder"> | <img src="docs/screenshots/duplicates-en.png" alt="Duplicate candidates"> |

| O que escanear? | Tema escuro | Tamanho vs No disco, explicado |
|---|---|---|
| <img src="docs/screenshots/welcome-en.png" alt="Start screen"> | <img src="docs/screenshots/details-dark-en.png" alt="Details, dark theme"> | <img src="docs/screenshots/mode-help-en.png" alt="Size vs On disk help"> |

## Instalação

Requer **macOS 14 Sonoma ou posterior** em **Apple Silicon**.

1. Baixe **TreeScan-Size.zip** em [Releases](https://github.com/gorbarov/treescan-size/releases/latest), descompacte e mova o app para Aplicativos.
2. A build **ainda não é notarizada**, então o macOS bloqueia a primeira inicialização:
   - **macOS 15 e posteriores:** abra o app uma vez, clique em *Concluído* e depois em **Ajustes do Sistema → Privacidade e Segurança → Abrir Mesmo Assim**.
   - **macOS 14:** clique com o botão direito no app → **Abrir** → **Abrir**.
   - Ou no Terminal: `xattr -dr com.apple.quarantine "/Applications/TreeScan Size.app"`
3. Na primeira inicialização, o app solicita **Acesso Total ao Disco** — um único interruptor nos Ajustes do Sistema em vez de uma dúzia de solicitações do macOS para Área de Trabalho, Documentos, iCloud e dados de outros apps. Você pode pular esta etapa: as pastas protegidas serão simplesmente marcadas com 🔒 e não lidas.

### Compilar a partir do código-fonte

```bash
git clone https://github.com/gorbarov/treescan-size && cd treescan-size
scripts/make_app.sh          # Command Line Tools are enough (Swift 5.9+), no Xcode needed
open "build/TreeScan Size.app"
```

## Comparado a outras ferramentas

| | TreeScan Size | DaisyDisk | GrandPerspective | OmniDiskSweeper | Disk Inventory X |
|---|---|---|---|---|---|
| Visualização principal | árvore com barras de tamanho + gráfico | anéis sunburst | treemap | lista em colunas | treemap + lista |
| Preço | gratuito | pago | gratuito (pago na App Store) | gratuito | gratuito |
| Código-fonte | aberto, MIT | fechado | aberto, GPL | fechado | aberto, GPL |

Além disso: arquivos de nuvem somente online marcados, "Não sincronizar" do Dropbox pelo menu, alternância Tamanho / No disco, árvore ao vivo durante a varredura, candidatos a duplicata sem baixar arquivos da nuvem.

*Baseado em descrições públicas de setembro de 2026 — correções são bem-vindas.*

## Como foi construído

O TreeScan Size também é um experimento. **O código foi escrito por um modelo de programação barato** (DeepSeek V4 Flash), enquanto o Claude Opus atuou como líder técnico: escreveu a especificação, dividiu o trabalho em ~25 pequenas tarefas com respostas precomputadas, revisou cada linha arriscada. Um script Python e um relatório HTML ([reference/](reference/)) serviram como implementação de referência.

O que aprendemos, em resumo:
- Um modelo barato é ótimo em um caminho bem traçado: portar lógica de uma referência, construir a interface a partir de um esqueleto de código.
- Testes verdes não bastam: certa vez, ele desativou a proteção de pastas do sistema no menu da Lixeira enquanto todos os testes passavam — só a revisão de código detectou isso.
- Uma pasta de teste com 500 arquivos esconde o que 2,9 milhões de arquivos revelam: uma aba levou 9 minutos para ser desenhada em um disco real. Verificações em tamanho real encontraram isso, um humano encontrou o resto.

A história completa — tarefas, verificações, lições, registros de execução — está em [docs/FINDINGS.md](docs/FINDINGS.md) e [docs/RESEARCH.md](docs/RESEARCH.md) (em russo); os registros de execução estão anexados à [release](https://github.com/gorbarov/treescan-size/releases/latest).

## Contribuindo

Relatos de bugs, traduções e revisões por falantes nativos são muito bem-vindos — veja [CONTRIBUTING.md](CONTRIBUTING.md).

## Licença e marcas registradas

[MIT](LICENSE). O TreeScan Size é inspirado no TreeSize para Windows, mas **não é afiliado nem endossado pela JAM Software**. TreeSize é uma marca registrada de Joachim Marder e.K. (JAM Software). Dropbox, iCloud, OneDrive e macOS são marcas registradas de seus respectivos proprietários.
