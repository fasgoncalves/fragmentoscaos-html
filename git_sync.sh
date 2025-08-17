#!/bin/bash

# Caminho do repositório
REPO_DIR="/home/teu_utilizador/meu_repositorio"

# Carregar token do ficheiro .env
source /home/teu_utilizador/.env

# URL segura com token
REPO_URL="https://${GIT_TOKEN}@github.com/teu_utilizador/repositorio.git"

# Caminho do log
LOG_FILE="/home/teu_utilizador/git_sync.log"

echo "=== [$(date)] Início do sync ===" >> $LOG_FILE

if [ ! -d "$REPO_DIR" ]; then
    git clone "$REPO_URL" "$REPO_DIR" >> $LOG_FILE 2>&1
else
    cd "$REPO_DIR" || exit 1
    git pull origin main >> $LOG_FILE 2>&1
fi

echo "=== [$(date)] Fim do sync ===" >> $LOG_FILE
