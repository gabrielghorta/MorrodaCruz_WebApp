"""Sistema de gestão da obra Morro da Cruz (Ankara × Caesb, CT 10.239/2026).

O código fica neste pacote, por área:

* nucleo/ — O núcleo: caminhos, relógio, regras de negócio puras, casos de uso sobre o banco, acesso, imagens e backup.
* carga/ — A carga das planilhas oficiais (06.1, 06.2, BM, reajuste, evidências): simulação, aplicação e leitura do .xls.
* execucao/ — Execução de campo: a nota de serviço (leitura e registro), o diário, as terceirizadas e o trecho físico.
* obra/ — A obra no mapa e nas planilhas: planejamento das equipes, Dados da obra, cronograma, LEV, mapa geral e relatórios.
* almoxarifado/ — Compras, recebimento, almoxarifado e a leitura da NF-e.
* faturamento/ — Medição e faturamento: gavetas e regras, apropriação direta, pacote no modelo oficial do BM e exportação.
* integracoes/ — Ligações com fora: Google Drive, catálogo de documentos e o link https para a equipe.
* servidor/ — O servidor web e as entradas: servidor HTTP, nuvem (WSGI), programa do Windows, usuários, demonstração e pacote.

As entradas (python server.py, nuvem.py, importar.py…) ficam na raiz do projeto.
"""
