# zbelto

## 概要

zig製の簡単なHTTPサーバー

## 使い方

`src/main.zig`を参照

## 実行方法

ルートディレクトリにいることが前提

```sh
zig build
```

```sh
./zig-out/bin/zbelto
Server listening on port 8000...
If yout want stop, press CTRL + C
```

別ウィンドウを開いてcurlなどを利用してAPIを叩く

```sh
curl -H 'Content-Type: application/json' http://localhost:8000/
Hello, World!% 
```
