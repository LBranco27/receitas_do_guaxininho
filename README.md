# 📱 App de Receitas Flutter

Um aplicativo mobile de receitas desenvolvido com Flutter, inspirado nos apps **TudoGostoso** e **Tasty**, com foco em simplicidade, praticidade e organização na cozinha.

![Flutter](https://img.shields.io/badge/Flutter-v3.x-blue?logo=flutter)
![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)
![License](https://img.shields.io/badge/license-MIT-green)

Projeto desenvolvido por Pedro Caetano, Lucas Branco e João Guilherme Benjamin, como parte da disciplina de Desenvolvimento Mobile com Flutter 🚀

---

## Installation

1. Create a .env file on repository's root directory.
2. Add SUPABASE_KEY environment variable.
3. Run `flutter pub get` to install dependencies.
4. Run `flutter run` to start the app.

---

## 🧠 Motivação

A motivação para desenvolver este app de receitas é oferecer uma solução simples, acessível e organizada para quem busca cozinhar em casa, com foco em uma experiência intuitiva e leve. Seu diferencial está na interface minimalista e funcional, que permite encontrar, salvar e gerenciar receitas favoritas de forma rápida, sem distrações ou excesso de informações.

---

## 📌 Protótipo no Figma

📎 Link para o protótipo: **https://www.figma.com/design/0kwdes2OWzNKVgDSONZWZP/Projeto-Mobile-Receitas?node-id=0-1&t=7C6aAE6yAeSZLQHz-1**

---

## 🎬 Apresentação

📎 Link para a apresentação: **https://youtu.be/HK26VZ7ps2Y**

---

## 📄 Descrição do Aplicativo

O aplicativo tem como objetivo oferecer aos usuários uma maneira prática e organizada de encontrar receitas culinárias para o dia a dia. Com uma interface intuitiva e visualmente atrativa, permite:

- Navegar por uma variedade de receitas categorizadas (massas, sobremesas, saladas etc.)
- Visualizar ingredientes e modo de preparo
- Salvar receitas favoritas
- (Opcional) Adicionar suas próprias receitas

---

## 👥 Público-alvo

Pessoas interessadas em cozinhar em casa, desde iniciantes até usuários mais experientes que buscam inspiração e praticidade na cozinha.

---

## 🧩 Funcionalidades

### ✅ Funcionalidades Essenciais (MVP)

#### 📚 Receitas
- [ ] Listar todas as receitas disponíveis
- [ ] Visualizar detalhes da receita (nome, descrição, ingredientes, preparo, imagem)
- [ ] Filtrar receitas por categoria (massas, sopas, etc.)
- [ ] Buscar receitas pelo nome
- [ ] Marcar/desmarcar receitas como favoritas
- [ ] Visualizar lista de receitas favoritas

#### 🧭 Interface e Navegação
- [ ] Tela inicial com destaques
- [ ] Tela de listagem geral
- [ ] Tela de detalhes
- [ ] Tela de favoritos
- [ ] Navegação entre telas (bottom navigation ou drawer)

---

### 🔄 Funcionalidades Intermediárias (Versão 2)

#### 📝 Gerenciamento de Receitas (CRUD)
- [ ] Criar nova receita com nome, descrição, ingredientes, preparo e imagem
- [ ] Editar receitas existentes
- [ ] Excluir receitas
- [ ] Validações de formulário

#### 🗂️ Categorias Dinâmicas
- [ ] Selecionar categoria ao criar/editar
- [ ] Visualizar receitas por abas ou scroll horizontal por categoria

#### 🎨 Melhoria de UI/UX
- [ ] Tela de splash ou loading
- [ ] Snackbars ou dialogs de feedback
- [ ] Skeleton ou shimmer no carregamento de conteúdo

---

## 📌 Histórias de Usuário

### MVP
- Como usuário, quero ver uma lista de todas as receitas disponíveis.
- Como usuário, quero visualizar os detalhes de uma receita.
- Como usuário, quero filtrar receitas por categoria.
- Como usuário, quero buscar receitas pelo nome.
- Como usuário, quero marcar e desmarcar receitas como favoritas.
- Como usuário, quero acessar apenas minhas receitas favoritas.
- Como usuário, quero navegar facilmente entre as telas do app.

### Versão 2
- Como usuário, quero criar minhas próprias receitas.
- Como usuário, quero editar ou excluir receitas que criei.
- Como usuário, quero selecionar categorias ao cadastrar receitas.
- Como usuário, quero mensagens claras ao realizar ações (salvar, excluir, etc.)
- Como usuário, quero uma boa experiência visual enquanto os dados carregam.

---

## 🚀 Tecnologias Utilizadas

- Flutter 3.x
- Dart
- SQLite (armazenamento local)
  
---
## 📄 Licença
Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais informações.
