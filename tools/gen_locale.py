# Erzeugt locale/<sprache>/touchdeck-bridge.cfg für touchdeck-bridge aus einer Tabelle.
import os, sys
L = ["en", "de", "fr", "es-ES", "pl", "pt-BR", "ru", "zh-CN"]
T = {}  # (abschnitt, schlüssel) -> [Texte in Reihenfolge L]
def add(sec, key, *texts):
    assert len(texts) == len(L), (sec, key, len(texts))
    T[(sec, key)] = texts

add("mod-name","touchdeck-bridge","TouchDeck Bridge","TouchDeck Bridge","TouchDeck Bridge","TouchDeck Bridge","TouchDeck Bridge","TouchDeck Bridge","TouchDeck Bridge","TouchDeck Bridge")
add("mod-description","touchdeck-bridge",
 "Connects Factorio to TouchDeck (phone or tablet as a remote control): writes the game state as a JSON file to script-output and takes commands through its own key bindings. No launch options, no network.",
 "Verbindet Factorio mit TouchDeck (Handy oder Tablet als Fernbedienung): schreibt den Spielzustand als JSON-Datei nach script-output und nimmt Befehle über eigene Tastenkürzel an. Keine Startoptionen, kein Netzwerk.",
 "Relie Factorio à TouchDeck (téléphone ou tablette comme télécommande) : écrit l'état du jeu dans un fichier JSON dans script-output et reçoit des commandes par ses propres raccourcis clavier. Sans option de lancement, sans réseau.",
 "Conecta Factorio con TouchDeck (móvil o tableta como mando a distancia): escribe el estado del juego en un archivo JSON en script-output y recibe órdenes mediante sus propios atajos de teclado. Sin opciones de inicio, sin red.",
 "Łączy Factorio z TouchDeck (telefon lub tablet jako pilot): zapisuje stan gry do pliku JSON w script-output i przyjmuje polecenia przez własne skróty klawiszowe. Bez opcji uruchamiania, bez sieci.",
 "Conecta o Factorio ao TouchDeck (celular ou tablet como controle remoto): grava o estado do jogo em um arquivo JSON em script-output e recebe comandos pelos próprios atalhos de teclado. Sem opções de inicialização, sem rede.",
 "Связывает Factorio с TouchDeck (телефон или планшет как пульт): записывает состояние игры в JSON-файл в script-output и принимает команды через собственные сочетания клавиш. Без параметров запуска, без сети.",
 "将 Factorio 连接到 TouchDeck（手机或平板电脑作为遥控器）：把游戏状态写入 script-output 中的 JSON 文件，并通过自身的快捷键接收命令。无需启动参数，无需网络。")

add("mod-setting-name","touchdeck-bridge-interval","Write state every … ticks","Zustand schreiben alle … Ticks","Écrire l'état tous les … ticks","Escribir el estado cada … ticks","Zapisuj stan co … ticków","Gravar o estado a cada … ticks","Записывать состояние каждые … тиков","每隔 … 刻写入状态")
add("mod-setting-name","touchdeck-bridge-enabled","Write files for TouchDeck","Für TouchDeck schreiben","Écrire les fichiers pour TouchDeck","Escribir archivos para TouchDeck","Zapisuj pliki dla TouchDeck","Gravar arquivos para o TouchDeck","Записывать файлы для TouchDeck","为 TouchDeck 写入文件")
add("mod-setting-description","touchdeck-bridge-interval",
 "How often state.json is updated (60 ticks = 1 second). Events and commands are written at once.",
 "Wie oft state.json aktualisiert wird (60 Ticks = 1 Sekunde). Ereignisse und Befehle werden sofort geschrieben.",
 "Fréquence de mise à jour de state.json (60 ticks = 1 seconde). Les événements et commandes sont écrits immédiatement.",
 "Con qué frecuencia se actualiza state.json (60 ticks = 1 segundo). Los eventos y órdenes se escriben al instante.",
 "Jak często aktualizowany jest state.json (60 ticków = 1 sekunda). Zdarzenia i polecenia są zapisywane od razu.",
 "Com que frequência o state.json é atualizado (60 ticks = 1 segundo). Eventos e comandos são gravados na hora.",
 "Как часто обновляется state.json (60 тиков = 1 секунда). События и команды записываются сразу.",
 "state.json 的更新频率（60 刻 = 1 秒）。事件和命令会立即写入。")
add("mod-setting-description","touchdeck-bridge-enabled",
 "When off, the mod writes no files for you (for example in multiplayer if you do not use TouchDeck).",
 "Wenn aus, schreibt der Mod für dich keine Dateien (z. B. im Mehrspieler, wenn du TouchDeck nicht nutzt).",
 "Désactivé, le mod n'écrit aucun fichier pour vous (par exemple en multijoueur si vous n'utilisez pas TouchDeck).",
 "Si está desactivado, el mod no escribe archivos para ti (por ejemplo en multijugador si no usas TouchDeck).",
 "Gdy wyłączone, mod nie zapisuje dla ciebie plików (np. w trybie wieloosobowym, jeśli nie używasz TouchDeck).",
 "Desligado, o mod não grava arquivos para você (por exemplo no multijogador, se você não usa o TouchDeck).",
 "Если выключено, мод не записывает для вас файлы (например, в мультиплеере, если вы не используете TouchDeck).",
 "关闭后，模组不会为你写入文件（例如在多人游戏中你不使用 TouchDeck 时）。")

C = "controls"
add(C,"touchdeck-bridge-command","TouchDeck: open command field","TouchDeck: Befehlsfeld öffnen","TouchDeck : ouvrir le champ de commande","TouchDeck: abrir campo de órdenes","TouchDeck: otwórz pole poleceń","TouchDeck: abrir campo de comando","TouchDeck: открыть поле команд","TouchDeck：打开命令栏")
add(C,"touchdeck-bridge-pause","TouchDeck: toggle pause","TouchDeck: Pause umschalten","TouchDeck : pause/reprise","TouchDeck: pausar/reanudar","TouchDeck: przełącz pauzę","TouchDeck: pausar/retomar","TouchDeck: пауза вкл./выкл.","TouchDeck：切换暂停")
for i, v in enumerate(["0.5", "1", "2", "4"], start=1):
    de = v.replace(".", ",")
    add(C, f"touchdeck-bridge-speed-{i}", f"TouchDeck: speed {v}×", f"TouchDeck: Geschwindigkeit {de}×", f"TouchDeck : vitesse {de}×", f"TouchDeck: velocidad {de}×", f"TouchDeck: prędkość {de}×", f"TouchDeck: velocidade {de}×", f"TouchDeck: скорость {de}×", f"TouchDeck：速度 {v}×")
add(C,"touchdeck-bridge-slower","TouchDeck: slower (half speed)","TouchDeck: langsamer (halbe Geschwindigkeit)","TouchDeck : plus lent (moitié)","TouchDeck: más lento (mitad)","TouchDeck: wolniej (połowa)","TouchDeck: mais devagar (metade)","TouchDeck: медленнее (вдвое)","TouchDeck：减速（一半）")
add(C,"touchdeck-bridge-faster","TouchDeck: faster (double speed)","TouchDeck: schneller (doppelte Geschwindigkeit)","TouchDeck : plus vite (double)","TouchDeck: más rápido (doble)","TouchDeck: szybciej (podwójnie)","TouchDeck: mais rápido (dobro)","TouchDeck: быстрее (вдвое)","TouchDeck：加速（两倍）")
add(C,"touchdeck-bridge-save","TouchDeck: save game","TouchDeck: Spiel speichern","TouchDeck : sauvegarder","TouchDeck: guardar partida","TouchDeck: zapisz grę","TouchDeck: salvar jogo","TouchDeck: сохранить игру","TouchDeck：保存游戏")
add(C,"touchdeck-bridge-screenshot","TouchDeck: screenshot","TouchDeck: Screenshot","TouchDeck : capture d'écran","TouchDeck: captura de pantalla","TouchDeck: zrzut ekranu","TouchDeck: captura de tela","TouchDeck: снимок экрана","TouchDeck：截图")
add(C,"touchdeck-bridge-cancel-research","TouchDeck: cancel research","TouchDeck: Forschung abbrechen","TouchDeck : annuler la recherche","TouchDeck: cancelar investigación","TouchDeck: anuluj badanie","TouchDeck: cancelar pesquisa","TouchDeck: отменить исследование","TouchDeck：取消研究")
for i in (1, 2, 3):
    add(C, f"touchdeck-bridge-research-{i}", f"TouchDeck: queue research suggestion {i}", f"TouchDeck: Forschungsvorschlag {i} einreihen", f"TouchDeck : ajouter la suggestion de recherche {i}", f"TouchDeck: poner en cola la sugerencia de investigación {i}", f"TouchDeck: dodaj propozycję badania {i} do kolejki", f"TouchDeck: enfileirar sugestão de pesquisa {i}", f"TouchDeck: в очередь предложение исследования {i}", f"TouchDeck：将研究建议 {i} 加入队列")
add(C,"touchdeck-bridge-center","TouchDeck: back to the player","TouchDeck: Zurück zum Spieler","TouchDeck : retour au joueur","TouchDeck: volver al jugador","TouchDeck: wróć do gracza","TouchDeck: voltar ao jogador","TouchDeck: вернуться к игроку","TouchDeck：回到玩家")
add(C,"touchdeck-bridge-refresh","TouchDeck: write data again","TouchDeck: Daten neu schreiben","TouchDeck : réécrire les données","TouchDeck: volver a escribir datos","TouchDeck: zapisz dane ponownie","TouchDeck: gravar dados novamente","TouchDeck: записать данные заново","TouchDeck：重新写入数据")
add(C,"touchdeck-bridge-utl-manager","TouchDeck: open UTL manager (UTLogistics only)","TouchDeck: UTL-Manager öffnen (nur mit UTLogistics)","TouchDeck : ouvrir le gestionnaire UTL (UTLogistics uniquement)","TouchDeck: abrir gestor de UTL (solo con UTLogistics)","TouchDeck: otwórz menedżera UTL (tylko z UTLogistics)","TouchDeck: abrir gerenciador UTL (só com UTLogistics)","TouchDeck: открыть менеджер UTL (только с UTLogistics)","TouchDeck：打开 UTL 管理器（仅限 UTLogistics）")
add(C,"touchdeck-bridge-utl-alerts","TouchDeck: UTL manager, alerts (UTLogistics only)","TouchDeck: UTL-Manager, Warnungen (nur mit UTLogistics)","TouchDeck : gestionnaire UTL, alertes (UTLogistics uniquement)","TouchDeck: gestor de UTL, avisos (solo con UTLogistics)","TouchDeck: menedżer UTL, ostrzeżenia (tylko z UTLogistics)","TouchDeck: gerenciador UTL, alertas (só com UTLogistics)","TouchDeck: менеджер UTL, предупреждения (только с UTLogistics)","TouchDeck：UTL 管理器，警报（仅限 UTLogistics）")

B = "touchdeck-bridge"
add(B,"command-title","TouchDeck command","TouchDeck-Befehl","Commande TouchDeck","Orden de TouchDeck","Polecenie TouchDeck","Comando do TouchDeck","Команда TouchDeck","TouchDeck 命令")
add(B,"command-help","Command for TouchDeck Bridge, e.g. /touchdeck speed 2, /touchdeck research #1, /touchdeck pause","Befehl für TouchDeck Bridge, z. B. /touchdeck speed 2, /touchdeck research #1, /touchdeck pause","Commande pour TouchDeck Bridge, p. ex. /touchdeck speed 2, /touchdeck research #1, /touchdeck pause","Orden para TouchDeck Bridge, p. ej. /touchdeck speed 2, /touchdeck research #1, /touchdeck pause","Polecenie dla TouchDeck Bridge, np. /touchdeck speed 2, /touchdeck research #1, /touchdeck pause","Comando do TouchDeck Bridge, ex.: /touchdeck speed 2, /touchdeck research #1, /touchdeck pause","Команда для TouchDeck Bridge, напр. /touchdeck speed 2, /touchdeck research #1, /touchdeck pause","TouchDeck Bridge 命令，例如 /touchdeck speed 2、/touchdeck research #1、/touchdeck pause")
add(B,"utl-tab","TouchDeck","TouchDeck","TouchDeck","TouchDeck","TouchDeck","TouchDeck","TouchDeck","TouchDeck")
add(B,"utl-section","TouchDeck","TouchDeck","TouchDeck","TouchDeck","TouchDeck","TouchDeck","TouchDeck","TouchDeck")
add(B,"utl-pin","Show on the TouchDeck","Auf dem TouchDeck zeigen","Afficher sur le TouchDeck","Mostrar en el TouchDeck","Pokaż na TouchDeck","Mostrar no TouchDeck","Показывать на TouchDeck","在 TouchDeck 上显示")
add(B,"utl-pin-tooltip",
 "Shows this station on the TouchDeck page “UTLogistics › Stations” (trains here and on the way, supply, demand). Travels with blueprints and when copying settings.",
 "Zeigt diese Station auf der TouchDeck-Seite „UTLogistics › Stationen“ (Züge da und unterwegs, Angebot, Bedarf). Reist mit Blaupausen und beim Kopieren mit.",
 "Affiche cette gare sur la page TouchDeck « UTLogistics › Gares » (trains présents et en route, offre, demande). Suit les plans et la copie des réglages.",
 "Muestra esta estación en la página de TouchDeck «UTLogistics › Estaciones» (trenes aquí y en camino, oferta, demanda). Viaja con los planos y al copiar ajustes.",
 "Pokazuje tę stację na stronie TouchDeck „UTLogistics › Stacje” (pociągi na miejscu i w drodze, podaż, popyt). Przenosi się w planach i przy kopiowaniu ustawień.",
 "Mostra esta estação na página do TouchDeck “UTLogistics › Estações” (trens aqui e a caminho, oferta, demanda). Vai junto em projetos e ao copiar configurações.",
 "Показывает эту станцию на странице TouchDeck «UTLogistics › Станции» (поезда на месте и в пути, предложение, спрос). Сохраняется в чертежах и при копировании настроек.",
 "在 TouchDeck 页面“UTLogistics › 车站”上显示此车站（在站和途中的列车、供应、需求）。随蓝图和复制设置一同保留。")
add(B,"utl-slot","Slot __1__","Platz __1__","Emplacement __1__","Posición __1__","Miejsce __1__","Posição __1__","Место __1__","位置 __1__")
add(B,"utl-tab-count","__1__ of __2__ slots used","__1__ von __2__ Plätzen belegt","__1__ emplacements sur __2__ utilisés","__1__ de __2__ posiciones ocupadas","Zajęte miejsca: __1__ z __2__","__1__ de __2__ posições ocupadas","Занято мест: __1__ из __2__","已用 __1__ / __2__ 个位置")
add(B,"utl-tab-hint","Pin a station: station window › TouchDeck › tick the box and pick a slot.","Station anheften: Stationsfenster › TouchDeck › Häkchen setzen und Platz wählen.","Épingler une gare : fenêtre de la gare › TouchDeck › cocher et choisir un emplacement.","Fijar una estación: ventana de estación › TouchDeck › marcar la casilla y elegir posición.","Przypnij stację: okno stacji › TouchDeck › zaznacz pole i wybierz miejsce.","Fixar uma estação: janela da estação › TouchDeck › marcar a caixa e escolher a posição.","Закрепить станцию: окно станции › TouchDeck › поставить галочку и выбрать место.","固定车站：车站窗口 › TouchDeck › 勾选并选择位置。")
add(B,"utl-tab-empty","No station pinned yet.","Noch keine Station angeheftet.","Aucune gare épinglée pour l'instant.","Aún no hay ninguna estación fijada.","Nie przypięto jeszcze żadnej stacji.","Nenhuma estação fixada ainda.","Ни одна станция ещё не закреплена.","尚未固定任何车站。")
for key, texts in {"slot": ("Slot","Platz","Empl.","Posición","Miejsce","Posição","Место","位置"),
                   "station": ("Station","Station","Gare","Estación","Stacja","Estação","Станция","车站"),
                   "surface": ("Planet","Planet","Planète","Planeta","Planeta","Planeta","Планета","星球"),
                   "network": ("Network","Netz","Réseau","Red","Sieć","Rede","Сеть","网络"),
                   "trains": ("Trains","Züge","Trains","Trenes","Pociągi","Trens","Поезда","列车"),
                   "action": ("","","","","","","","")}.items():
    add(B, "utl-col-" + key, *texts)
add(B,"utl-trains","__1__ here · __2__ coming","__1__ da · __2__ kommen","__1__ ici · __2__ en route","__1__ aquí · __2__ en camino","__1__ na miejscu · __2__ w drodze","__1__ aqui · __2__ a caminho","__1__ здесь · __2__ в пути","__1__ 在站 · __2__ 途中")
add(B,"utl-goto","Show the station on the map","Station auf der Karte zeigen","Afficher la gare sur la carte","Mostrar la estación en el mapa","Pokaż stację na mapie","Mostrar a estação no mapa","Показать станцию на карте","在地图上显示车站")
add(B,"utl-unpin","Unpin","Lösen","Détacher","Quitar","Odepnij","Desafixar","Открепить","取消固定")

S = "touchdeck-bridge-msg"
add(S,"paused","Game paused","Spiel angehalten","Jeu en pause","Juego en pausa","Gra wstrzymana","Jogo pausado","Игра на паузе","游戏已暂停")
add(S,"resumed","Game running again","Spiel läuft weiter","Le jeu reprend","El juego continúa","Gra wznowiona","Jogo retomado","Игра продолжается","游戏已继续")
add(S,"speed","Speed __1__×","Geschwindigkeit __1__×","Vitesse __1__×","Velocidad __1__×","Prędkość __1__×","Velocidade __1__×","Скорость __1__×","速度 __1__×")
add(S,"saved","Saved: __1__","Gespeichert: __1__","Sauvegardé : __1__","Guardado: __1__","Zapisano: __1__","Salvo: __1__","Сохранено: __1__","已保存：__1__")
add(S,"screenshot","Screenshot: __1__","Screenshot: __1__","Capture d'écran : __1__","Captura: __1__","Zrzut ekranu: __1__","Captura de tela: __1__","Снимок экрана: __1__","截图：__1__")
add(S,"research-queued","Queued: __1__","In Warteschlange: __1__","Ajouté à la file : __1__","En cola: __1__","Dodano do kolejki: __1__","Na fila: __1__","В очереди: __1__","已加入队列：__1__")
add(S,"research-cancelled","Research cancelled: __1__","Forschung abgebrochen: __1__","Recherche annulée : __1__","Investigación cancelada: __1__","Anulowano badanie: __1__","Pesquisa cancelada: __1__","Исследование отменено: __1__","已取消研究：__1__")
add(S,"centered","Back at the player","Zurück beim Spieler","De retour au joueur","De vuelta con el jugador","Z powrotem przy graczu","De volta ao jogador","Снова у игрока","已回到玩家")
add(S,"refreshed","Data written again","Daten neu geschrieben","Données réécrites","Datos escritos de nuevo","Dane zapisane ponownie","Dados gravados novamente","Данные записаны заново","已重新写入数据")
add(S,"bad-value","Invalid value: __1__","Ungültiger Wert: __1__","Valeur non valide : __1__","Valor no válido: __1__","Nieprawidłowa wartość: __1__","Valor inválido: __1__","Недопустимое значение: __1__","无效的值：__1__")
add(S,"bad-speed","Speed must be between 0.01 and 100: __1__","Geschwindigkeit muss zwischen 0,01 und 100 liegen: __1__","La vitesse doit être entre 0,01 et 100 : __1__","La velocidad debe estar entre 0,01 y 100: __1__","Prędkość musi wynosić od 0,01 do 100: __1__","A velocidade deve estar entre 0,01 e 100: __1__","Скорость должна быть от 0,01 до 100: __1__","速度必须在 0.01 到 100 之间：__1__")
add(S,"research-unknown","Research not found: __1__","Forschung nicht gefunden: __1__","Recherche introuvable : __1__","Investigación no encontrada: __1__","Nie znaleziono badania: __1__","Pesquisa não encontrada: __1__","Исследование не найдено: __1__","未找到研究：__1__")
add(S,"research-done","Already researched: __1__","Schon erforscht: __1__","Déjà recherché : __1__","Ya investigado: __1__","Już zbadane: __1__","Já pesquisado: __1__","Уже исследовано: __1__","已研究：__1__")
add(S,"research-failed","Cannot be queued: __1__","Kann nicht eingereiht werden: __1__","Impossible d'ajouter à la file : __1__","No se puede poner en cola: __1__","Nie można dodać do kolejki: __1__","Não pode ser enfileirado: __1__","Нельзя поставить в очередь: __1__","无法加入队列：__1__")
add(S,"no-suggestion","No research suggestion __1__ (nothing can be queued right now)","Keinen Forschungsvorschlag __1__ (gerade nichts einreihbar)","Pas de suggestion de recherche __1__ (rien à ajouter pour l'instant)","No hay sugerencia de investigación __1__ (ahora no se puede poner nada en cola)","Brak propozycji badania __1__ (teraz nic nie można dodać)","Sem sugestão de pesquisa __1__ (nada pode ser enfileirado agora)","Нет предложения исследования __1__ (сейчас ничего нельзя поставить в очередь)","没有研究建议 __1__（目前无可加入队列的研究）")
add(S,"no-research","No research is running","Gerade läuft keine Forschung","Aucune recherche en cours","No hay ninguna investigación en curso","Żadne badanie nie trwa","Nenhuma pesquisa em andamento","Исследование не ведётся","当前没有进行中的研究")
add(S,"no-player","Only works with a player","Geht nur mit einem Spieler","Ne fonctionne qu'avec un joueur","Solo funciona con un jugador","Działa tylko z graczem","Só funciona com um jogador","Работает только с игроком","仅在有玩家时可用")
add(S,"not-admin","Admins only (multiplayer)","Nur für Admins (Mehrspieler)","Réservé aux admins (multijoueur)","Solo administradores (multijugador)","Tylko dla adminów (gra wieloosobowa)","Somente administradores (multijogador)","Только для админов (мультиплеер)","仅限管理员（多人游戏）")
add(S,"unknown-command","Unknown command: __1__","Unbekannter Befehl: __1__","Commande inconnue : __1__","Orden desconocida: __1__","Nieznane polecenie: __1__","Comando desconhecido: __1__","Неизвестная команда: __1__","未知命令：__1__")
add(S,"utl-opened","UTL manager opened","UTL-Manager geöffnet","Gestionnaire UTL ouvert","Gestor de UTL abierto","Otwarto menedżera UTL","Gerenciador UTL aberto","Менеджер UTL открыт","已打开 UTL 管理器")
add(S,"utl-missing","UTLogistics is not active","UTLogistics ist nicht aktiv","UTLogistics n'est pas actif","UTLogistics no está activo","UTLogistics nie jest aktywny","UTLogistics não está ativo","UTLogistics не активен","UTLogistics 未启用")
add(S,"utl-failed","The UTL manager could not be opened","UTL-Manager ließ sich nicht öffnen","Impossible d'ouvrir le gestionnaire UTL","No se pudo abrir el gestor de UTL","Nie udało się otworzyć menedżera UTL","Não foi possível abrir o gerenciador UTL","Не удалось открыть менеджер UTL","无法打开 UTL 管理器")

root = sys.argv[1]
order = []
for sec, _ in T:
    if sec not in order: order.append(sec)
for i, lang in enumerate(L):
    out = []
    for sec in order:
        out.append(f"[{sec}]")
        for (s, k), texts in T.items():
            if s == sec: out.append(f"{k}={texts[i]}")
        out.append("")
    os.makedirs(f"{root}/locale/{lang}", exist_ok=True)
    open(f"{root}/locale/{lang}/touchdeck-bridge.cfg", "w", encoding="utf-8").write("\n".join(out))
print(len(T), "Schlüssel ×", len(L), "Sprachen")
