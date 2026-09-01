# Relatório de Desenvolvimento — Protótipo de Plataforma 2D

---

## 1. As Duas Fases

### Fase 1 — Grassland (`scenes/game.tscn`)
* **Tema:** Planície verdejante ensolarada com relevo ondulado de colinas, vegetação rasteira e céu aberto com nuvens em movimento.
* **Ações do Jogador:** Caminha e salta entre diferentes níveis de terreno e elevações de terra, superando pequenas fendas até alcançar a casa no topo direito onde está o portal de transição.
* **Decisão de Desenho e Motivo:** Construção de um relevo com múltiplos caminhos verticais e uma cavidade oculta sob a colina com `TileMapLayer_fakeTerrain`, incentivando a exploração e quebrando a sensação de progressão puramente horizontal e linear.

### Fase 2 — Autumn Forest (`scenes/forest.tscn`)
* **Tema:** Floresta de outono densa com copas de árvores em tons alaranjados, troncos caídos, pilhas de folhas secas e ambientação fechada.
* **Ações do Jogador:** Percorre um trajeto horizontal muito mais longo (mais de 1600px de extensão), escalando plataformas suspensas e saltando sobre grandes abismos mortais até o portal final.
* **Decisão de Desenho e Motivo:** Foco no espaçamento de plataformas sobre fossos profundos atrelados ao limite de queda (`QUEDA_LIMITE`), elevando a curva de dificuldade e exigindo maior domínio do tempo e precisão dos saltos em relação à primeira fase.

---

## 2. O Parallax

### Valores de `motion_scale` / `scroll_scale` Utilizados:

* **Fase 1 (Nós `Parallax2D`):**
  * `Parallax2D_Ceu`: `Vector2(0.0, 0.0)` — céu estático posicionado no infinito.
  * `Parallax2D_NuvensLonge`: `Vector2(0.1, 0.05)` — nuvens de fundo com deslocamento suave.
  * `Parallax2D_NuvensPerto`: `Vector2(0.2, 0.1)` com `autoscroll = Vector2(-8, 0)` — nuvens intermediárias com velocidade própria constante simulando vento.
  * `Parallax2D_Montanhas`: `Vector2(0.4, 0.2)` — colinas médias de fundo.
  * `Parallax2D_CenarioFundo`: `Vector2(0.7, 0.35)` — vegetação próxima ao plano de jogo.

* **Fase 2 (Nós `ParallaxLayer`):**
  * Camada 6 (`Distant_trees`): `motion_scale = Vector2(0.1, 0.1)`
  * Camada 5 (`Tree_row_BG_2`): `motion_scale = Vector2(0.2, 0.2)`
  * Camada 4 (`Tree_row_BG_1`): `motion_scale = Vector2(0.3, 0.3)`
  * Camada 3 (`Bottom_leaf_piles`): `motion_scale = Vector2(0.4, 0.4)`
  * Camada 2 (`Trees`): `motion_scale = Vector2(0.5, 0.5)`
  * Camada 1 (`Leaf_top`): `motion_scale = Vector2(1.0, 1.0)` (folhas superiores).

### Como chegamos neles e o que mudou:
* **Construção dos Valores:** Foi aplicada uma progressão linear baseada na distância perceptual: quanto mais longe um plano está da lente da câmera, menor a velocidade com que ele aparenta se deslocar. No eixo Y da Fase 1, o valor foi configurado na metade da velocidade do eixo X para que os pulos verticais do personagem não fizessem o cenário de fundo se mover bruscamente nem revelassem vazios fora da tela.
* **Evolução da 1ª Tentativa para a Final:** Na primeira versão, os deslocamentos eram uniformes ou com saltos de escala excessivos, gerando um efeito visual estranho e deixando cortes/fendas pretas nas bordas da viewport ao pular. Na versão final, calibrou-se o `repeat_size` para coincidir com as dimensões da textura (288x208) junto ao `repeat_times` / `motion_mirroring` com repetição de textura ligada (`texture_repeat`), além da inclusão do `autoscroll` nas nuvens para criar dinamismo mesmo quando o jogador permanece parado.

---

## 3. A Área Secreta

* **Onde está a pista:** No topo e nos arredores da colina principal da Fase 1 (onde há uma cerca de madeira e um arranjo decorativo incomum que destoa do terreno plano ao redor, chamando a atenção visual do jogador).
* **Onde está a entrada:** Na base/lateral inferior da colina (coordenadas de tiles X: 33–34, Y: 8–9), oculta por blocos de `TileMapLayer_fakeTerrain` desenhados com `z_index = 2` e sem colisão física.
* **Por que foram separadas:** Para proporcionar uma experiência genuína de exploração e dedução (*environmental storytelling*). Se a entrada estivesse exatamente onde está a pista, não haveria investigação. Ao notar uma formação incomum no topo da colina, o jogador é incentivado a inspecionar a estrutura ao redor, testando as paredes da base até descobrir que aquela textura de terra é ilusória e pode ser atravessada.

---

## 4. A Câmera

* **Opção Escolhida:** **Câmera 2D Independente e Desacoplada** (cena dedicada `entities/camera_2d.tscn` com script `scripts/camera.gd`), inserida diretamente na árvore de cada fase e buscando dinamicamente o alvo através do grupo `"player"`.
* **O que perderíamos com a outra opção (Câmera filha do Player):**
  1. **Limites e enquadramento específicos por fase:** Cada mapa possui dimensões e limites distintos (`limit_left`, `limit_top`, `limit_right`, `limit_bottom`). Exemplo: a Fase 1 tem limite horizontal de -200 até 860, enquanto a Fase 2 vai de 0 até 1725. Se a câmera fosse filha do Player, teríamos que reprogramar os limites dentro do script do personagem a cada troca de fase ou criar código acoplado desnecessário.
  2. **Independência de transformações:** A câmera herdaria rotações, escalas (como inversões caso o personagem usasse `scale.x = -1`) e movimentos abruptos do nó pai.
  3. **Modularidade para efeitos e cutscenes:** Perderíamos a flexibilidade de mover a câmera para pontos de interesse (como mostrar uma porta abrindo ou focar em um chefe) sem arrastar o corpo físico do jogador junto.

---

## 5. A Transição de Fase

### Explicação:
Imagine que o motor de física do jogo é como uma engrenagem que gira a cada milissegundo calculando contatos, gravidade e colisões de todos os objetos ao mesmo tempo (*physics frame* / *flushing queries*).

Quando o jogador encosta no portal, a colisão é detectada bem no meio desse cálculo de física (`_on_body_entered`). Se chamarmos a troca de fase imediatamente (`change_scene_to_file`), estaríamos pedindo para o jogo apagar a fase inteira da memória e destruir os objetos no exato momento em que a física ainda está varrendo a lista deles para terminar suas contas. Isso causa conflitos graves na engine, disparando erros de *"can't change scene while flushing queries"* ou travamentos.

Por isso, utilizamos o `call_deferred("load_next_scene")`. Essa função avisa ao Godot: *"Espere a física terminar o trabalho do frame atual com segurança e, assim que o motor estiver ocioso no próximo instante, execute a troca de cena."*

---

## 6. O que Travou

* **O Momento em que Algo Não Funcionou:** Durante o processo de desacoplamento da câmera e na implementação da troca de fases, ao carregar uma nova cena, a câmera não seguia o jogador e o console disparava o erro `Camera2D: nenhum nó no grupo 'player'`.
* **O que parecia ser a causa:** Inicialmente a suspeita era de que o método `_ready()` da câmera estivesse executando antes do Player ser instanciado no ciclo de vida da cena nova gerada pelo `change_scene_to_file`, ou que houvesse um problema de atraso no carregamento da árvore de nós.
* **O que era de verdade:** Na transição e reorganização das cenas, a instância do nó `Player` na nova cena não havia sido adicionada formalmente ao grupo global `player` nas configurações do nó na interface do Godot, fazendo com que a chamada `get_tree().get_nodes_in_group("player")` retornasse uma lista vazia.
* **Como foi descoberto:** Inspecionando a árvore de nós em tempo de execução através da aba **Remote** do depurador do Godot e acompanhando as mensagens de erro no painel de **Output**. Ao verificar que o nó do jogador estava presente na cena mas a lista de grupos vinha vazia, adicionou-se a tag de grupo `groups=["player"]` diretamente no nó instanciado da cena, restaurando o rastreamento da câmera instantaneamente.
