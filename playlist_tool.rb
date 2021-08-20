#! ruby -Ks
# -*- mode:ruby; coding:Windows-31J -*-
$KCODE = "SJIS"

#======================================================================
#Project Name    : BeatSaber PlayList TOOL
#File Name       : playlist_tool.rb  _frm_playlist_tool.rb
#Creation Date   : 2019/11/16
# 
#Copyright       : 2019 Rynan. (Twitter @rynan4818)
#License         : Ruby License
#Tool            : ActiveScriptRuby(1.8.7-p330)  https://www.artonx.org/data/asr/
#                  FormDesigner for VisualuRuby Ver 040323  https://ja.osdn.net/projects/fdvr/
#RubyGems Package: rubygems-update (1.8.21)      https://rubygems.org/
#                  nokogiri (1.5.10 x86-mswin32-60)
#                  json (1.4.6 x86-mswin32)
#======================================================================

#直接実行時にEXE_DIRを設定する(末尾は\)
EXE_DIR = (File.dirname(File.expand_path($0)).sub(/\/$/,'') + '/').gsub(/\//,'\\') unless defined?(EXE_DIR)

require 'rubygems'
require 'jcode'
require 'nkf'
require 'win32ole'
require 'csv'
require 'json'
require 'time'
require 'base64'
require 'net/http'
require 'nokogiri'
require 'vr/vruby'
require 'vr/vrcontrol'
require 'vr/vrcomctl'
require 'vr/vrddrop.rb'
require 'vr/clipboard'
require '_frm_playlist_tool.rb'

SETTING_FILE = EXE_DIR + 'setting.json'
SS_SERVER = 'scoresaber.com'
SS_PATH   = '/u/'
SOFT_VER  = '20191118'


####文字コード変換処理####
#SJIS → UTF-8変換
def utf8cv(str)
  if str.kind_of?(String)
    return NKF.nkf('-w --ic=CP932 -m0 -x',str)
  else
    return str
  end
end

####メイン変換処理####
#ScoreSaber 取得処理
def user_score_get(userid,limit_page = false,prgrssbar = false,read_static = false)
  proxy_class = Net::HTTP
  #proxy_class = Net::HTTP::Proxy('proxy_server.com', 8080)  #Proxyサーバを使う時

  ss_data = []
  page = 1
  maxpage = 1
  player = ''
  rankchart = ''
  while page <= maxpage do
    #ScoreSaberからユーザのスコアリストのHTMLソースを取得
    res = proxy_class.start(SS_SERVER) {|h|
      h.get("#{SS_PATH}#{userid}&page=#{page}&sort=2")
    }
    #NokogiriでHTMLをパースし情報取得
    doc = Nokogiri::HTML(res.body,nil,'utf-8')
    #プレイヤー名
    player = doc.search('h5[@class="title is-5"]').text.strip
    #ランクのチャートデータ
    rankchart = '0'
    doc.search('script').text.each_line do |line|
      if line.strip =~ /^data: \[[\d,]+\],$/
        rankchart = line.strip.sub(/data: \[/,'').sub(/\],/,'')
      end
    end
    #スコアテーブル
    doc.search('table[@class="ranking songs"]').each do |table|
      tr = table.search("tr")
      tr.each do |a|
        #ランク
        rank = a.search('th[@class="rank"]').text.strip.sub(/#/,'').gsub(/,/,'')
        next if rank == '' || rank == 'Rank'
        #曲名
        song_nodeset = a.search('th[@class="song"]')
        song = song_nodeset.search('span[@class="songTop pp"]').text.strip
        #マッパー
        mapper = song_nodeset.search('span[@class="songTop mapper"]').text.strip
        #曲ID
        id   = song_nodeset.at("img")["src"].sub(/^.+\/(\w+)\.png$/,'\1').strip
        #譜面ID
        uid  = song_nodeset.at("a")["href"].sub(/\/leaderboard\//,'').strip
        #記録日時
        time = song_nodeset.at('span[@class="songBottom time"]')["title"].strip
        time = Time.parse(time).localtime.strftime("%Y/%m/%d %H:%M:%S")
        #何日前
        songBottom_time = song_nodeset.search('span[@class="songBottom time"]').text.strip
        #曲pp
        score_nodeset = a.search('th[@class="score"]')
        pp   = score_nodeset.search('span[@class="scoreTop ppValue"]').text.strip
        #取得pp
        ppw  = score_nodeset.search('span[@class="scoreTop ppWeightedValue"]').text.strip.gsub(/\(/,'').gsub(/pp\)/,'')
        #スコア
        score= score_nodeset.search('span[@class="scoreBottom"]').text.strip.gsub(/,/,'')
        ss_data.push [uid,id,rank,time,songBottom_time,pp,ppw,score,mapper,song]
      end
    end
    #最大ページ情報の取得
    doc.search('ul[@class="pagination-list"]').each do |ul|
      li = ul.search("li")
      li.each do |a|
        maxpage = a.text.strip.gsub(/,/,'').to_i
      end
    end
    #画面更新
    if read_static
      SWin::Application.doevents
      if limit_page
        endpage = limit_page
      else
        endpage = maxpage
      end
      read_static.caption = "#{page}/#{endpage} page read"
    end
    page += 1
    return false if ss_data == []
    #取得ページ制限
    if limit_page
      prgrssbar.position = page * 100 / limit_page if prgrssbar
      break if page > limit_page
    else
      prgrssbar.position = page * 100 / maxpage if prgrssbar
    end
  end
  return [player,rankchart,ss_data]
end

#プレイリスト作成
def playlist_convert(cb_text,name_output,image_file,description,title,author,namecol,hashcol)
  cb_array = []
  cb_text.each_line do |line|
    cb_array.push line.split("\t")
  end
  nameidx = false
  hashidx = false
  cb_array[0].each_with_index do |column,idx|
    nameidx = idx if column.strip == namecol
    hashidx = idx if column.strip == hashcol
  end
  cb_array.shift
  bplist_data = {}
  songs_array = []
  cb_array.each do |songs|
    song_data = {}
    song_data['songName'] = songs[nameidx].strip if name_output
    id_data = songs[hashidx].strip
    if id_data =~ /^\w+$/
      song_data['hash'] = id_data
      songs_array.push song_data
    end
  end
  bplist_data['songs'] = songs_array
  bplist_data['playlistTitle'] = utf8cv(title)
  bplist_data['playlistDescription'] = utf8cv(description)
  bplist_data['playlistAuthor'] = utf8cv(author)
  if File.exist?(image_file)
    image_data = File.open(image_file, "rb") {|f| f.read }
    image_base64 = Base64.encode64(image_data).split().join()
    if File.extname(image_file) =~ /\.png$/i
      type = 'png'
    else
      type = 'undefined'
    end
    bplist_data['image'] = "data:image/#{type};base64,#{image_base64}"
  else
    bplist_data['image'] = '1'
  end
  return bplist_data
end

#GUIフォームイベント処理
module Frm_main_form
  include VRDropFileTarget
  
  #フォーム起動時処理
  def self_created
    if File.exist?(SETTING_FILE)
      setting = JSON.parse(File.read(SETTING_FILE))
      @userid_edit.caption = setting['UserID']          if setting['UserID']
      @limit_checkBox.check true                        if setting['LimitPage']
      @limit_edit.caption = setting['LimitPage']        if setting['LimitPage']
      @tab_checkBox.check true                          if setting['TSV']
      @author_edit.caption = setting['Author']          if setting['Author']
      @namecol_edit.caption = setting['SongnameColumn'] if setting['SongnameColumn']
      @hashcol_edit.caption = setting['SongIDcolumn']   if setting['SongIDcolumn']
      @nameoutput_checkBox.check true                   if setting['SongnameOutput']
      self.x = setting['form_x']                        if setting['form_x']
      self.y = setting['form_y']                        if setting['form_y']
    else
      self.x = 330
      self.y = 70
      @tab_checkBox.check true
      @nameoutput_checkBox.check true
    end
    self.caption += "  Ver #{SOFT_VER}"
    @prgrssBar1.setRange(0,100)
    @tz_static.caption = Time.now.zone
  end
  
  #ScoreSaber Userデータ取得ボタン
  def get_button_clicked
    #ボタンをDisableにする
    @get_button.style     = 1476395008
    @imgopen_button.style = 1476395008
    @create_button.style  = 1476395008
    @playlist_tsv_button.style = 1476395008
    @prgrssBar1.position = 0
    refresh
    userid = @userid_edit.text.strip
    limit_page = @limit_edit.text.strip.to_i
    limit_page = false unless @limit_checkBox.checked? && limit_page > 0
    player,rankchart,ss_data = user_score_get(userid,limit_page,@prgrssBar1,@read_static)
    if @tab_checkBox.checked?
      separator = "\t"
      select_ext = '*.tsv'
      file_type = ["TSV File(*.tsv)","*.tsv"]
    else
      separator = ","
      select_ext = '*.csv'
      file_type = ["CSV File(*.csv)","*.csv"]
    end
    if ss_data
      @prgrssBar1.position = 100
      fn = SWin::CommonDialog::saveFilename(self,[file_type,["all file (*.*)","*.*"]],0x1004,'USER SCORE LIST SAVE FILE',select_ext,0,"#{player}_scorelist")
    else
      #取得データが異常時は警告表示
      messageBox("ScoreSaber READ ERROR","ERROR",0)
      @prgrssBar1.position = 0
      fn = false
    end
    #CSV保存処理
    if fn
      save_ok = true
      if File.exist?(fn)
        save_ok = false unless messageBox("Do you want to overwrite?","Overwrite confirmation",0x0004) == 6
      end
      if save_ok
        CSV.open(fn,'w',separator) do |record|
          record << ['uid','id','rank','time','songBottom_time','pp','ppw','score','mapper','song_name']
          ss_data.each do |row|
            record << row
          end
        end
      end
    end
    #ボタンをEnableにする
    @prgrssBar1.position = 0
    @get_button.style     = 1342177280
    @imgopen_button.style = 1342177280
    @create_button.style  = 1342177280
    @playlist_tsv_button.style = 1342177280
    @read_static.caption  = ""
    refresh
  end
  
  #プレイリストをTSV変換
  def playlist_tsv_button_clicked
    ext_list = [["BeatSaber PlayList(*.bplist)","*.bplist"],["JSON filet(*.json)","*.json"],["all file (*.*)","*.*"]]
    playlist_file = SWin::CommonDialog::openFilename(self,ext_list,0x1004,'PlayList file select','*.bplist')
    return unless playlist_file
    return unless File.exist?(playlist_file)
    playlist_file_name = File.basename(playlist_file,'.*')
    playlist = JSON.parse(File.read(playlist_file))
    if @tab_checkBox.checked?
      separator = "\t"
      select_ext = '*.tsv'
      file_type = ["TSV File(*.tsv)","*.tsv"]
    else
      separator = ","
      select_ext = '*.csv'
      file_type = ["CSV File(*.csv)","*.csv"]
    end
    songs = playlist['songs']
    if songs.kind_of?(Array)
      fn = SWin::CommonDialog::saveFilename(self,[file_type,["all file (*.*)","*.*"]],0x1004,'PlayList convert TSV(CSV) SAVE FILE',select_ext,0,playlist_file_name)
      return unless fn
    else
      #取得データが異常時は警告表示
      messageBox("PlayList READ ERROR","ERROR",0)
      return
    end
    #曲リストのカラム名取り出し
    column_list = {}
    songs.each do |a|
      a.keys.each do |b|
        column_list[b] = true
      end
    end
    column_list = column_list.keys
    #カラムのhashを先頭に、songNameをその次にする
    ['songName','hash'].each do |a|
      if column_list.index(a)
        column_list.delete(a)
        column_list.unshift(a)
      end
    end
    #CSV保存処理
    save_ok = true
    if File.exist?(fn)
      save_ok = false unless messageBox("Do you want to overwrite?","Overwrite confirmation",0x0004) == 6
    end
    if save_ok
      CSV.open(fn,'w',separator) do |record|
        record << column_list
        songs.each do |row|
          rows = []
          column_list.each do |a|
            if a == 'hash'
              d = row[a].upcase
            else
              d = row[a]
            end
            rows.push d
          end
          record << rows
        end
      end
    end
    #画像復元処理
    image = playlist['image']
    if image =~ /^data:image\/(\w+);base64,(.+)$/i
      image_type = $1
      base64_data = $2
      select_ext = "*.#{image_type}"
      file_type = ["#{image_type.upcase} File(*.#{image_type})","*.#{image_type}"]
      fn = SWin::CommonDialog::saveFilename(self,[file_type,["all file (*.*)","*.*"]],0x1004,'PlayList convert image SAVE FILE',select_ext,0,playlist_file_name)
      if fn
        save_ok = true
        if File.exist?(fn)
          save_ok = false unless messageBox("Do you want to overwrite?","Overwrite confirmation",0x0004) == 6
        end
      else
        save_ok = false
      end
      if save_ok
        File.open(fn, 'wb') do |file|
          file.write(Base64.decode64(base64_data))
        end
      end
    end
    #その他項目
    playlist.delete('songs')
    playlist.delete('image')
    unless playlist == {}
      fn = SWin::CommonDialog::saveFilename(self,[["TEXT File(*.txt)","*.txt"],["all file (*.*)","*.*"]],0x1004,'PlayList convert text SAVE FILE','*.txt',0,playlist_file_name)
      if fn
        save_ok = true
        if File.exist?(fn)
          save_ok = false unless messageBox("Do you want to overwrite?","Overwrite confirmation",0x0004) == 6
        end
      else
        save_ok = false
      end
      if save_ok
        File.open(fn, 'w') do |file|
          playlist.each do |key,val|
            file.puts "[#{key}]"
            file.puts val
            file.puts
          end
        end
      end
    end
  end
  
  #画像ファイル開くボタン
  def imgopen_button_clicked
    ext_list = [["Image File (*.png;*.jpg;*.jpeg;*.gif)","*.png;*.jpg;*.jpeg;*.gif"],["all file (*.*)","*.*"]]
    fn = SWin::CommonDialog::openFilename(self,ext_list,0x1004,'Image file select','*.png')
    return unless fn
    @image_edit.text = fn
  end
  
  #ドラッグ＆ドロップ貼り付け
  def self_dropfiles(files)
    @image_edit.text = files[0]
  end
  
  #プレイリスト作成ボタン
  def create_button_clicked
    name_output = @nameoutput_checkBox.checked?
    image_file  = @image_edit.text.strip
    description = @description_edit.text.strip
    title       = @title_edit.text.strip
    author      = @author_edit.text.strip
    namecol     = @namecol_edit.text.strip
    hashcol     = @hashcol_edit.text.strip
    cb_text = false
    Clipboard.open(self.hWnd) do |cb|
      begin
        cb_text = cb.getText
      rescue RuntimeError  #クリップボードがテキスト以外の時
        messageBox("Copy text to clipboard" ,"ERROR",0)
      end
    end
    playlist_data = playlist_convert(cb_text,name_output,image_file,description,title,author,namecol,hashcol) if cb_text
    if playlist_data
      fn = SWin::CommonDialog::saveFilename(self,[["BeatSaber PlayList(*.bplist)","*.bplist"],["all file (*.*)","*.*"]],0x1004,'PLAYLIST SAVE FILE','*.bplist',0,title.gsub(/[\\\/:\*\?\"<>|]/,'_'))
      return unless fn
      if File.exist?(fn)
        return unless messageBox("Do you want to overwrite?","Overwrite confirmation",0x0004) == 6
      end
      File.open(fn,'w') do |file|
        JSON.pretty_generate(playlist_data).each do |line|
          file.puts line
        end
      end
    end
  end
  
  def exit_menu_clicked
    close
  end

  def save_menu_clicked
    setting = {}
    setting['UserID']         = @userid_edit.text.strip
    if @limit_checkBox.checked?
      setting['LimitPage']      = @limit_edit.text.strip
    else
      setting['LimitPage']      = false
    end
    setting['TSV']            = @tab_checkBox.checked?
    setting['Author']         = @author_edit.text.strip
    setting['SongnameColumn'] = @namecol_edit.text.strip
    setting['SongIDcolumn']   = @hashcol_edit.text.strip
    setting['SongnameOutput'] = @nameoutput_checkBox.checked?
    setting['form_x']         = self.x
    setting['form_y']         = self.y
    File.open(SETTING_FILE,'w') do |file|
      JSON.pretty_generate(setting).each do |line|
        file.puts line
      end
    end
  end
  
  def default_menu_clicked
    @tab_checkBox.check true
    @nameoutput_checkBox.check true
    @limit_checkBox.check false
    @userid_edit.caption = ''
    @author_edit.caption = ''
    @namecol_edit.caption = 'name'
    @hashcol_edit.caption = 'id'
  end

  def version_menu_clicked
    messageBox("BeatSaber PlayList TOOL Ver#{SOFT_VER} for ActiveScriptRuby(1.8.7-p330)\r\nCopyright 2019 Rynan.  (Twitter @rynan4818)" ,"Version",0)
  end

end

#GUIメッセージループ
VRLocalScreen.start Frm_main_form
