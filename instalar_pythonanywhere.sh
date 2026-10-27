#!/bin/bash
# Instala (ou atualiza) o Sistema Morro da Cruz no PythonAnywhere — a conta gratuita serve. No console Bash de lá, cole:
#
#   [ -d ~/morrodacruz_webapp ] || git clone --depth 1 https://github.com/gabrielghorta/MorrodaCruz_WebApp.git ~/morrodacruz_webapp; bash ~/morrodacruz_webapp/instalar_pythonanywhere.sh
#
# Repositório privado: o git pede usuário e senha; a senha é um token do GitHub (Settings > Developer settings >
# Fine-grained tokens, só leitura do conteúdo deste repositório). Passo a passo em docs/NUVEM.md.
#
# O que ele faz: baixa a versão mais nova do código; instala o openpyxl e o pypdf (leitura da nota de serviço); monta a obra das planilhas do repositório
# (banco de demonstração, perfil TESTE) e pede o seu administrador; liga o site em https://<seu usuário>.pythonanywhere.com
# Pode rodar de novo quantas vezes quiser: não apaga nada (os dados ficam em dados_demo/ e dados/, fora do Git).
# Quem vinha da instalação antiga (~/Projeto-Pessoal/morro-da-cruz): os dados de lá são copiados para cá na primeira vez,
# e a pasta antiga fica intacta.
set -u
PASTA="$HOME/morrodacruz_webapp"
ANTIGA="$HOME/Projeto-Pessoal/morro-da-cruz"
cd "$PASTA" || { echo "Pasta $PASTA não encontrada: cole o comando completo (com o git clone)."; exit 1; }

echo "== 1/4 Código: buscando a versão mais nova"
git -C "$PASTA" pull --ff-only || echo "   (não consegui atualizar; sigo com a versão que já está aqui)"

PY=""
for v in 3.13 3.12 3.11; do command -v "python$v" >/dev/null && { PY="python$v"; break; }; done
[ -n "$PY" ] || { echo "Preciso do Python 3.11 ou mais novo, e não achei neste console."; exit 1; }
echo "== 2/4 Bibliotecas ($PY e as outras versões do console)"
for v in 3.13 3.12 3.11; do
  command -v "python$v" >/dev/null || continue
  "python$v" -c "import openpyxl" 2>/dev/null || "python$v" -m pip install --user --quiet "openpyxl>=3.1,<4"
  "python$v" -c "import PIL" 2>/dev/null || "python$v" -m pip install --user --quiet "pillow>=10" 2>/dev/null || true
  "python$v" -c "import pypdf" 2>/dev/null || "python$v" -m pip install --user --quiet "pypdf>=6,<7"
done

echo "== 3/4 Banco da obra e administrador"
for d in dados_demo dados; do                          # instalação antiga: copia os dados uma vez, sem mexer na origem
  [ -d "$ANTIGA/$d" ] && [ ! -e "$PASTA/$d" ] || continue
  echo "   Copiando $ANTIGA/$d para $PASTA/$d (a pasta antiga fica como está)"
  cp -a "$ANTIGA/$d" "$PASTA/$d" || { echo "Não consegui copiar $ANTIGA/$d: nada foi alterado na instalação antiga."; exit 1; }
  for db in "$ANTIGA/$d"/*.db; do                      # o banco vai pela cópia do próprio SQLite (consistente com o site no ar)
    [ -f "$db" ] || continue
    rm -f "$PASTA/$d/$(basename "$db")"-journal "$PASTA/$d/$(basename "$db")"-wal "$PASTA/$d/$(basename "$db")"-shm
    "$PY" -c "import sqlite3, sys; d = sqlite3.connect(sys.argv[2]); sqlite3.connect(sys.argv[1]).backup(d); d.close()" \
      "$db" "$PASTA/$d/$(basename "$db")" || { echo "Não consegui copiar o banco $db."; exit 1; }
  done
done
"$PY" nuvem.py preparar || exit 1

echo "== 4/4 Site"
SITE="${PYTHONANYWHERE_SITE:-www.${PYTHONANYWHERE_DOMAIN:-pythonanywhere.com}}"
DOMINIO=$(echo "$USER.${PYTHONANYWHERE_DOMAIN:-pythonanywhere.com}" | tr '[:upper:]' '[:lower:]')   # o endereço é sempre minúsculo
WSGI="/var/www/$(echo "$DOMINIO" | tr '.' '_')_wsgi.py"
for f in /var/www/*_wsgi.py; do                       # usa o arquivo que o PythonAnywhere criou, qualquer que seja a caixa
  [ -f "$f" ] && [ "$(echo "$f" | tr '[:upper:]' '[:lower:]')" = "$WSGI" ] && WSGI="$f"
done
API="https://$SITE/api/v0/user/$USER/webapps"
VERSAO="python$(echo "${PY#python}" | tr -d '.')"
api() { [ -n "${API_TOKEN:-}" ] && curl -fsS -o /dev/null -H "Authorization: Token $API_TOKEN" "$@"; }

if [ ! -f "$WSGI" ] && api -X POST -d "domain_name=$DOMINIO" -d "python_version=$VERSAO" "$API/"; then
  echo "   Site criado: $DOMINIO"
fi
if [ ! -f "$WSGI" ]; then
  cat <<FIM

   Falta criar o site (uma vez só, leva 1 minuto):
     1. No menu do PythonAnywhere, abra "Web" e clique em "Add a new web app".
     2. Clique em "Next", escolha "Manual configuration" e depois "Python ${PY#python}". Clique em "Next".
     3. Volte a este console e cole de novo o mesmo comando.
FIM
  exit 0
fi

cat > "$WSGI" <<FIM
# Sistema Morro da Cruz — gerado por instalar_pythonanywhere.sh (rodar de novo regrava este arquivo)
import sys
sys.path.insert(0, "$PASTA")
from nuvem import application  # noqa: E402,F401
FIM
echo "   Arquivo do site gravado: $WSGI"

if api -X PATCH -d "force_https=true" "$API/$DOMINIO/" && api -X POST "$API/$DOMINIO/reload/"; then
  echo "   Site recarregado, só com https."
else
  cat <<FIM

   Último passo (no navegador): abra "Web", ligue "Force HTTPS" e clique no botão verde "Reload $DOMINIO".
FIM
fi
cat <<FIM

=======================================================================
 LINK DA EQUIPE (fixo):  https://$DOMINIO
 Entre com o administrador que você criou e cadastre a equipe em Administrativo > Usuários e histórico.
 Conta gratuita: uma vez por mês, abra "Web" e clique em "Run until 1 month from today"
 (o PythonAnywhere avisa por e-mail antes de desligar).
 Para atualizar o sistema depois: cole de novo o mesmo comando.
=======================================================================
FIM
