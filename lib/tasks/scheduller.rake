desc "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
  require 'line/bot' #gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  # 使用したxmlデータ（毎朝6時更新）:以下をURLを入力すれば見ることができる
  url = "https://www.drk7.jp/weather/xml/10.xml"
  # xmlデータをパース(利用しやすいように整形)
  xml = open( url ).read.touth8
  doc = REXML::Document.new(xml)
  #パスの共通部分を変数化(area[2]は『南部』を指定している)
  xpath = 'weatherforecast/pref/area[2]/info/rainfallchance/'
  # 6時〜12時降水確率(以下同様)
  per06to12 = doc.elements[xpath + 'period[2]'].text
  per12to18 = doc.elements[xpath + 'period[3]'].text
  per18to24 = doc.elements[xpath + 'period[4]'].text
  # メッセージを発信する降水確率の下限値の設定
  min_per = 20
  if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
    word1 =
      ["今日は雨が降らなそうだよ！",
       "いい１日を過ごそう！",
       "今日のTo Doは確認したかな？",
       "有意義な１日を過ごせるように頑張ろう！！！",
       "目覚めはいいかな！？"].sample
    word2 =
      ["気をつけて行ってきてね(^^)",
       "いい１日を過ごそう(^^)",
       "雨にも負けずに今日も頑張ってね(^^)",
       "今日も一日楽しんでいこーー",
       "いいことがありますように(^^)"].sample
       # 降水確率に寄ってメッセージを変更する閾値の設定
       mid_per = 50
       if per06to12.to_i >= mid_per || per12to18.to_i >= mide_per || per18to24.to_i >= mid_per
         word3 = "今日が雨が降るかも！折りたたみ傘を忘れずに！"
       else
         word3 = "今日は雨が降るかもしれないから折りたたみ傘が有ると安心！"
       end
       #　発信するメッセージの設定
       push =
        "#{word1}\n#{word3}\n降水確率はこんな感じだよ。\n  6~12時　#{per06to12}%\n 12~18時  #{per12to18}%\n 18時~24時 #{per18to24}%\n#{word2}"
      # メッセージの発信先idを配列で渡す必要があるため,plunk関数を使って配列をidで取得
      user_ids =User.all.plunk(:line_id)
      message = {
        type: 'text',
        test: push
      }
      responce = client.multicasts(user_ids, message)
  end
  "OK"
end
