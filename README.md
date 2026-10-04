# Clipo

Histórico de copiar e colar para macOS, que vive na barra de menu.

O Clipo guarda os últimos textos que você copiou e deixa copiar qualquer um de volta com um clique. É um projeto pessoal, feito para uso próprio, sem loja e sem conta de desenvolvedor.

## Funcionalidades

- Fica na **barra de menu** (sem ícone no Dock).
- Registra automaticamente cada **texto copiado** em qualquer app.
- Guarda os **20 itens mais recentes**; o mais antigo é descartado ao passar do limite.
- Um texto repetido **sobe para o topo** em vez de duplicar.
- **Busca** no histórico.
- **Copiar de volta** clicando na linha ou no ícone de copiar (aparece um ✓ de confirmação).
- Apagar um item (ícone de lixeira ao passar o mouse) ou **limpar tudo** (pede confirmação).
- **Janela redimensionável** pelas bordas direita, inferior e pelo canto; o tamanho fica salvo.
- Tempo relativo em cada item ("há 2 minutos").

## Como funciona

Um timer consulta o `changeCount` do `NSPasteboard` a cada 0,5 s. Só quando o número muda o texto é lido e gravado. O histórico é persistido com **SwiftData**, localmente.

```
Clipo/
  ClipoApp.swift          # MenuBarExtra + inicialização do monitor
  ClipboardMonitor.swift  # observa o clipboard e grava no SwiftData
  ClipItem.swift          # modelo (@Model): texto + data
  ContentView.swift       # popover: busca, lista, rodapé, redimensionamento
```

## Stack

- Swift / SwiftUI
- SwiftData
- `MenuBarExtra` (estilo janela)
- macOS 26.5 (deployment target atual)

## Rodando

1. Abra `Clipo.xcodeproj` no Xcode.
2. Aperte **⌘R**. O ícone de prancheta aparece na barra de menu.

Como o app não tem Dock, o ⌘Q não funciona: use o botão **Sair** do popover ou o ■ Stop do Xcode.

## Instalando para uso diário

Sem conta paga da Apple, o Xcode assina o app localmente (Team = None), o que basta para rodar no próprio Mac.

```bash
pkill -x Clipo
xcodebuild -project Clipo.xcodeproj -scheme Clipo -configuration Release -destination 'platform=macOS' build
cp -R ~/Library/Developer/Xcode/DerivedData/Clipo-*/Build/Products/Release/Clipo.app /Applications/
open /Applications/Clipo.app
```

Na primeira abertura, se o macOS reclamar de "desenvolvedor não identificado", clique com o botão direito no app → **Abrir**.

Para abrir junto com o sistema: **Ajustes do Sistema → Geral → Itens de Início**.

## Ideias futuras

- Atalho global para abrir o histórico.
- Colar direto no app ativo (exige permissão de Acessibilidade).
- Suporte a imagens e itens fixados.
- Ignorar apps sensíveis (gerenciadores de senha).
