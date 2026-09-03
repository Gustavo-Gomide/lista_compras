#!/bin/bash
# Baixa o Flutter (versão stable)
git clone https://github.com/flutter/flutter.git -b stable
# Adiciona o Flutter ao PATH temporário do Vercel
export PATH="$PATH:`pwd`/flutter/bin"
# Desabilita telemetria no CI
flutter config --no-analytics
# Baixa as dependências do projeto
flutter pub get
# Compila a versão Web
flutter build web --release
