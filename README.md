# スラックフロントエンド 
  スラックフロントエンドとIOS

# 環境設定
###1- コンテナー起動
> flutter pub upgrade<br>
> external device(android and ios )と接続したいとき<br>
> 接続したいデバイスを選んでください。そしてflutter run をしてください<br>
> もしウェブサイトと接続したいときに lib/main.dartに以下のcodeをコメントしてください。<br>
  await UniServices.init(); このcodeはウェブサイトには必要ではない。。。<br>
> ウェブサイトと接続したいときに　flutter run --web-port=3000 (自分が好みのブラウザ) chrome/edge
