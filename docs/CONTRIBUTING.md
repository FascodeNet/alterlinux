# 貢献する方法 -日本語-

## コーディング規約

### 全体

- なるべく`bash`のビルドインコマンドを使用する
- 外部コマンドを使用する場合は依存パッケージを追加する（極力使用しないでください）

### 出力

- エラーメッセージは全て`STDERR`に出力する
- メッセージ用の関数がある場合はその関数を使用する
- 最小限の出力とし、冗長な出力は引数で有効化された場合のみに許可する

### 見た目

- インデントはスペース4つとする
- 引数の多いコマンド（`xorriso`など）やパイプを多用する場合は`\`で改行する
- コードにTodoを書く場合は日付とユーザー名を書く

### 変数や関数

- 全ての関数に概要や使い方にコメントを書く
- 関数の定義は`function`を付けず、`my_func () {}`を使用する
- 全ての変数は`${hoge}`のように括弧を使用する
- 関数内でしか使用しない変数は必ず`local`で宣言する
- コマンド置き換えは`` `echo hoge` ``ではなく`$(echo hoge)`を使用する
- 算術式展開は`$(( m + n ))`を使用する
- ローカル変数、関数は名前を`_`から始める

### if、for、test、case、while

- `test`コマンドは必ず`[[`を使用する
- `do`や`then`などは`while`、`for`、`if`と同じ行に書く
- `case`の際はなるべくインデントを揃える

### 例

```bash
# Usage: test_hoge <str>
test_hoge () {
    local _var="${1}"
    if [[ "${var}" = "hoge" ]]; then
        echo "${var} is hoge"
        return 0
    else
        echo "${var} is not hoge"
        return 1
    fi
}
```

### その他

- 極力相対パスを使用しない
- ファイルパスは必ず`""`で囲む

## Issues

Issueを送る際は以下の情報を記述して下さい。

- インストールに使用したイメージファイルへのURL
- 問題が発生した環境
- どのようなことを行ったか
- スクリーンショットやログ等
- ビルドに問題が発生した際は作業ディレクトリにある`build_options`

## プルリクエスト

日本語もしくは英語で内容を書いて下さい。内容とは具体的に以下のものを指します。

- どのような機能を追加するか（問題を修正するのか）
- 現在確認されている問題（その対処方法も書ければ）
- 参考にした文献について
- 動作を確認した環境や開発環境

---

# How to Contribute - English-

## Coding Conventions

### General

- Use the `bash` build-in command if possible
- Add a dependency package if you use an external command (please try not to use it as much as possible)

### Output

- Output all error messages to `STDERR`
- If you have a function for messages, use that function
- Minimize output and redundant output only allow when enabled by the argument

### Looks

- Indent should be four spaces
- The line break with `\` when using a lot of commands with many arguments (`xorriso`, etc.) or a lot of pipes
- If you write a Todo in your code, write the date and user name

### Variables and functions

- Write comments on all functions in summary and usage
- The function definition does not use a `function` but uses `my_func () {}`
- All variables use brackets like `${hoge}`
- Declare variables that are used only in the function by `local`
- Command substitution does not use a `` `echo hoge` `` but uses `$(echo hoge)`
- Arithmetic expansion uses `$(( m + n ))`
- Local variables, functions start their names with `_`

### if, for, test, case, while

- The `test` command must use `[[`
- `do`, `then`, etc. write on the same line as `while`, `for` and `if`
- Align indents on `cases` as much as possible

### Example

```bash
# Usage: test_hoge <str>
test_hoge () {
    local _var="${1}"
    if [[ "${var}" = "hoge" ]]; then
        echo "${var} is hoge"
        return 0
    else
        echo "${var} is not hoge"
        return 1
    fi
}
```

### Other

- Use as few relative paths as possible.
- Make sure to enclose the file path in `""`.

## Issues

When you send the issue, please include the following information.

- The URL to the image file used for the installation
- The environment in which the problem occurred
- What did we do
- Screenshots, logs, etc.
- If a problem happens when you're building, Please attach the file `build_options` in the working directory

## Pull Request

Please write content in either Japanese or English. Specifically, the content refers to the following

- What features you are going to add (or fix the problem)
- Known issues (and how to deal with them if you can write about them)
- About the references
- Tested environment and development environment
