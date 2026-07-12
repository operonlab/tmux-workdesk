# tmux-ide（繁體中文說明）

一個按鍵，把當前專案變成 **IDE 式的 tmux 視窗**——左邊檔案樹、中間主工作區、
中下 git 面板、右邊 AI 助手。每一格的程式與尺寸都可以替換，任何一格也都能關掉。

## 這是什麼？

寫專案時，你通常想同時看到同一組東西：一個瀏覽檔案的地方、一個打字的地方、
一個看 git 的地方，還有（近來）一個 AI 助手。每次手動擺出來——切、切、切、
這格跑這個、那格跑那個——很煩。

**tmux-ide** 一個鍵搞定。在任何專案目錄裡按 `prefix + i`，它就建出一個像 IDE 的
專屬視窗：

```
+----------+-----------------------------+------------+
|          |                             |            |
|          |       主工作區               |            |
|          |     （shell / 編輯器）        |            |
|   yazi   |         高 70%              |   agent    |
|  (檔案)   +-----------------------------+  (claude)  |
| 寬 20%   |                             |  寬 30%    |
| 全高     |     lazygit （git）          |  全高      |
|          |         高 30%              |            |
|          |       中央直欄               |            |
+----------+-----------------------------+------------+
    20%                ~50%                    30%
```

- **左側、全高（20%）**——[yazi](https://github.com/sxyazi/yazi)，快速的終端檔案管理器。
- **中央上方（中欄的 70%）**——主工作區：預設是純 shell，也可以設成編輯器。
- **中央下方（中欄的 30%）**——[lazygit](https://github.com/jesseduffield/lazygit)，git TUI。
- **右側、全高（30%）**——AI 助手 CLI（預設 `claude`，任何指令都行）。

再按一次同一個鍵，它只會**切回**那個視窗——絕不會再建第二個。

> ⚠️ **這些格子會執行指令。** `@ide-left-cmd`、`@ide-right-cmd`、
> `@ide-bottom-cmd`、`@ide-main-cmd` 會在建視窗時被執行。它們來自你自己的
> `~/.tmux.conf`，但請比照你放進設定檔的任何指令一樣謹慎看待。若某個程式沒安裝，
> 該格會安靜地改開一個 shell（並提示你）。

## 快速上手

還不熟 tmux 的 `prefix` 鍵？預設 prefix 是 `Ctrl-b`——先按 `Ctrl-b` 放開，
再按下一個鍵。

需要 **tmux 2.4 以上**。二選一。

### 方式 A — 用 TPM（tmux 外掛管理器）

沒裝過 TPM 的話，先跑這三行（直接複製貼上）：

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
printf '\n%s\n' "run '~/.tmux/plugins/tpm/tpm'" >> ~/.tmux.conf
tmux source ~/.tmux.conf
```

（如果 tmux 還沒開，`tmux source` 可能會印出「no server running」——沒關係，
設定會在你下次開 tmux 時生效。）

接著在 `~/.tmux.conf` 裡、`run '~/.tmux/plugins/tpm/tpm'` 那行的**上面**，加：

```tmux
set -g @plugin 'joneshong-skills/tmux-ide'
```

重新載入並安裝：

```sh
tmux source ~/.tmux.conf   # 1. 重新載入設定
# 2. 按下：prefix + I（大寫 i）下載外掛
```

### 方式 B — 不用 TPM（一行搞定）

隨便找個地方 clone，然後往 `~/.tmux.conf` 加一行：

```sh
git clone https://github.com/joneshong-skills/tmux-ide ~/.tmux/plugins/tmux-ide
printf '%s\n' "run-shell '~/.tmux/plugins/tmux-ide/ide.tmux'" >> ~/.tmux.conf
tmux source ~/.tmux.conf
```

（如果 tmux 還沒開，`tmux source` 可能會印出「no server running」——沒關係，
設定會在你下次開 tmux 時生效。）

### 試玩

1. `cd` 進一個專案，開啟（或 attach）tmux。
2. 按 **`prefix + i`**（小寫 i）→ 一個新的 `ide` 視窗會擺出四格佈局，
   以那個專案目錄為根。
3. 從任何地方再按 **`prefix + i`** → 直接跳回 `ide` 視窗（不會重建）。

> **注意：** 預設 `prefix + i` 會**覆蓋 tmux 內建的按鍵**——內建的是顯示一小段
> 視窗資訊的訊息（`display-message`）。如果你需要那個功能，用下面的 `@ide-bind`
> 把 tmux-ide 改綁到別的鍵。

## 選項

以下都可省略，要設就設在 `~/.tmux.conf` 裡、外掛那行的**上面**。

| 選項 | 預設 | 白話說明 |
|---|---|---|
| `@ide-bind` | `i` | 切換 IDE 視窗的按鍵（接在 prefix 之後）。設成 `none` 可停用。**會覆蓋內建的 `prefix + i`。** |
| `@ide-window-name` | `ide` | IDE 視窗的名字。toggle 靠這個名字找它。 |
| `@ide-cwd` | *(觸發 pane 的路徑)* | 佈局以哪個目錄為根。預設是你按鍵時所在的位置。 |
| `@ide-left-cmd` | `yazi` | 左側（檔案樹）格的指令。空字串 = 跳過這格。 |
| `@ide-right-cmd` | `claude` | 右側（AI 助手）格的指令。空字串 = 跳過。 |
| `@ide-bottom-cmd` | `lazygit` | 中央下方（git）格的指令。空字串 = 跳過。 |
| `@ide-main-cmd` | *(空 → shell)* | 主工作區的指令。留空就是純 shell。 |
| `@ide-left-width` | `20` | 左格寬度，佔**整個視窗**的百分比。 |
| `@ide-right-width` | `30` | 右格寬度，佔**整個視窗**的百分比。 |
| `@ide-bottom-height` | `30` | git 面板高度，佔**整個視窗**的百分比（即中欄高度，中欄本身是視窗全高）。 |
| `@ide-right-bottom-cmd` | *(空)* | 右欄的第二個指令，疊在右格**下方**（例如上面檔案樹、下面 agent）。留空＝右欄維持一格。 |
| `@ide-right-bottom-height` | `50` | 右欄第二格的高度，佔**整個視窗**的百分比。 |

本外掛建立的視窗都帶著 window option `@ide-window 1`。如果你有自己的
自動排版／rebalance hook，請檢查這個標記並跳過這些視窗——它們的
pane 比例是刻意排的。

範例——左邊整條 git 面板、右邊上檔案樹下 agent（三格；*main* 槽就是右上那格）：

```tmux
set -g @ide-left-cmd 'lazygit'
set -g @ide-left-width '33'
set -g @ide-main-cmd 'yazi'
set -g @ide-bottom-cmd 'claude'
set -g @ide-bottom-height '40'
set -g @ide-right-cmd ''
```

範例——主 pane 放 nvim、換另一個 agent、加寬側欄、把鍵改到 `g`：

```tmux
set -g @ide-bind 'g'
set -g @ide-main-cmd 'nvim'
set -g @ide-right-cmd 'codex'
set -g @ide-left-width '25'
set -g @plugin 'joneshong-skills/tmux-ide'
```

範例——不要 AI 格，只要 檔案 + 編輯器 + git：

```tmux
set -g @ide-right-cmd ''
set -g @ide-main-cmd 'nvim'
set -g @plugin 'joneshong-skills/tmux-ide'
```

## 解除安裝

跑內建的 teardown 腳本，解除按鍵綁定並關掉 IDE 視窗，然後刪掉資料夾：

```sh
~/.tmux/plugins/tmux-ide/scripts/teardown.sh
rm -rf ~/.tmux/plugins/tmux-ide
```

> ⚠️ teardown 會**殺掉 `ide` 視窗**，連帶關閉裡面所有在跑的東西（yazi、你的
> agent、lazygit、主 pane）。請先存好你的工作。

（如果你用 TPM 安裝，也把 `~/.tmux.conf` 裡的 `set -g @plugin '.../tmux-ide'`
那行移除。）

## 常見問題

**我按了 `prefix + i`，結果只跳出一段視窗資訊訊息。**
那是 tmux 內建的 `prefix + i`——外掛的綁定還沒載入。重新載入設定
（`tmux source ~/.tmux.conf`），若用 TPM 就按 `prefix + I`（大寫 i）安裝。
tmux-ide 載入後，`prefix + i` 就會改成建佈局。

**某一格開成了純 shell，而不是我預期的程式。**
那格的指令不在 tmux 啟動時環境的 `PATH` 上。tmux-ide 會檢查每個 `*-cmd` 的
第一個字，找不到就在那格開 shell，並印出 `ide: <cmd> not found, slot left as shell`。
把工具裝好（yazi / lazygit / 你的 agent CLI），或把選項指到正確的執行檔。

**某格什麼都沒有／我想要少一點 pane。**
把那格的指令設成空字串（例如 `set -g @ide-right-cmd ''`）。該次 split 會被跳過，
空間讓給鄰格。

**再按一次鍵又開了一個 IDE 視窗——或者沒反應。**
它不該建第二個：toggle 會找名為 `@ide-window-name`（預設 `ide`）的視窗，有就切
過去。如果你手動改了 IDE 視窗的名字，tmux-ide 就找不到它、會重建一個新的——把
`@ide-window-name` 改成一致，或別去改名。

**比例看起來差了一兩格。**
tmux 每條 pane 邊界會吃掉一格，所以 200 欄視窗的 20% / ~50% / 30% 會落在
40 / 98 / 60 欄（少掉的兩欄就是邊界）。這是正常的。

**佈局能撐過 tmux server 重啟嗎？**
這個視窗和它的 pane 就像其他視窗一樣活在跑著的 server 裡，所以
[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) 之類的設定可以
把它們救回來——但 tmux-ide 本身不在硬碟上留任何狀態。單純重啟後，再按一次
`prefix + i` 重建即可。

## 藍圖（Roadmap）

- **yazi → 主 pane**：把 yazi 選中的檔案直接開進主工作區。做法（yazi opener 設定
  ＋ 一段 `tmux send-keys` 橋接）寫在
  [docs/yazi-integration.md](yazi-integration.md)；**v0.1 不內建**。

## 與其他 `tmux-ide` 外掛的關係

`tmux-ide` 這個名字有好幾個彼此無關的專案各自取用——其中最接近的是
[guysoft/tmux-ide](https://github.com/guysoft/tmux-ide)（`nvim + opencode` 的
三格佈局，並把 nvim 的 RPC socket 暴露出來給 agent 做除錯），另外還有
[wavyrai/tmux-ide](https://github.com/wavyrai/tmux-ide) 與
[sandeeprenjith/TMUX-IDE](https://github.com/sandeeprenjith/TMUX-IDE)。

**本 repo 與上述任何一個都沒有關聯。** 之所以沿用這個名字是刻意的：它直白地說明了
外掛在做什麼；而且安裝走命名空間（`set -g @plugin 'joneshong-skills/tmux-ide'`），
所以你抓到的永遠是**這一個**，不會抓成別人的。

與最接近的 guysoft/tmux-ide 的差異：

- **四格，而非三格**——左側多一個全高的檔案管理器（yazi），主 pane 下方多一個
  獨立的 git 面板（lazygit），對比 guysoft 的 editor + agent + terminal。
- **不綁編輯器**——主 pane 預設純 shell（要用編輯器就把 `@ide-main-cmd` 指過去）；
  沒有 nvim 耦合，也沒有 RPC socket。
- **預設不同**——這裡是 yazi / claude / lazygit，那邊是 nvim / opencode。
- **tmux 2.4 起跳**——尺寸換算成絕對格數，佈局不受 split 順序影響，也不需要新版
  的百分比語法。

提醒：兩個外掛都讀 `@ide-*` 選項前綴，所以別同時啟用——擇一即可。

## 致謝 / 授權

一組單一用途 tmux 小外掛家族的一員。以 [MIT License](../LICENSE) 釋出。
