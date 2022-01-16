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
require 'vr/vruby'
require 'vr/vrcontrol'
require 'vr/vrcomctl'
require 'vr/vrddrop.rb'
require 'vr/clipboard'
require '_frm_playlist_tool.rb'

SETTING_FILE  = EXE_DIR + 'setting.json'
SS_API        = 'https://scoresaber.com/api/player/'
CURL_TIMEOUT  = 20
SOFT_VER      = '20220116'

####文字コード変換処理####
#SJIS → UTF-8変換#
def utf8cv(str)
  if str.kind_of?(String)                       #引数に渡された内容が文字列の場合のみ変換処理をする
    return NKF.nkf('-w --ic=CP932 -m0 -x',str)  #NKFを使ってSJISをUTF-8に変換して返す
  else
    return str                                  #文字列以外の場合はそのまま返す
  end
end

#UTF-8 → SJIS変換#
def sjiscv(str)
  if str.kind_of?(String)                       #引数に渡された内容が文字列の場合のみ変換処理をする
    return NKF.nkf('-W --oc=CP932 -m0 -x',str)  #NKFを使ってUTF-8をSJISに変換して返す
  else
    return str                                  #文字列以外の場合はそのまま返す
  end
end

####メイン変換処理####
#ScoreSaber 取得処理
def user_score_get(userid,api_limit,limit = false,recent = false,prgrssbar = false,read_static = false)

  player_data = {}
  ss_data = []
  page = 1
  total = 0
  player = ''
  profilePicture = ''
  if recent
    sort = "recent"
  else
    sort = "top"
  end
  url = "#{SS_API}#{userid}/full"
  puts "#{userid}:UserDataGet"
  begin
    player_data = JSON.parse(`curl.exe --connect-timeout #{CURL_TIMEOUT} #{url}`)
    player = player_data['name']
    profile_picture = player_data['profilePicture']
    total = player_data['scoreStats']['totalPlayCount']
  rescue
    puts player_data
    return false
  end
  if limit
    limit = total if limit > total
    if api_limit >= limit
      maxpage = 1
      api_limit = limit
    else
      maxpage = limit / api_limit
      maxpage += 1 if (limit % api_limit) > 0
    end
  else
    maxpage = total / api_limit
    maxpage += 1 if (total % api_limit) > 0
  end
  while page <= maxpage do
    api_limit = limit % api_limit if limit && page == maxpage && (limit % api_limit) != 0
    puts "User:#{player} ScoreDataGet (#{page}/#{maxpage})"
    #ScoreSaberからユーザのスコアデータを取得
    url = "#{SS_API}#{userid}/scores?limit=#{api_limit}&sort=#{sort}&page=#{page}"
    begin
      scores_data = JSON.parse(`curl.exe --connect-timeout #{CURL_TIMEOUT} #{url}`)
      playerScores = scores_data['playerScores']
    rescue
      puts scores_data
      return false
    end
    unless playerScores
      puts scores_data
      return
    end
    #スコアテーブル
    playerScores.each do |score|
      if score['score']
        rank   = score['score']['rank']
        time   = score['score']['timeSet']
        time   = Time.parse(time).localtime.strftime("%Y/%m/%d %H:%M:%S")
        pp     = score['score']['pp']
        ppw    = pp * score['score']['weight']
        base_score    = score['score']['baseScore']
        modified_score = score['score']['modifiedScore']
      else
        next
      end
      if score['leaderboard']
        song   = score['leaderboard']['songName']
        song_sub = score['leaderboard']['songSubName']
        mapper = score['leaderboard']['levelAuthorName']
        id     = score['leaderboard']['songHash']
        uid    = score['leaderboard']['id']
        max_score     = score['leaderboard']['maxScore']
        if score['leaderboard']['difficulty']
          difficulty = score['leaderboard']['difficulty']['difficultyRaw']
        else
          difficulty = ""
        end
      else
        next
      end
      ss_data.push [uid,id,rank,time,pp,ppw,base_score,modified_score,max_score,mapper,song,song_sub,difficulty]
    end
    #画面更新
    if read_static
      SWin::Application.doevents
      read_static.caption = "#{page}/#{maxpage} page read"
    end
    prgrssbar.position = page * 100 / maxpage if prgrssbar
    page += 1
    return false if ss_data == []
  end
  return [player,profile_picture,ss_data]
end

#プレイリスト作成
def playlist_convert(cb_text,name_output,image_file,description,title,author,namecol,hashcol,sjis = true)
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
  bplist_data['playlistTitle'] = sjis ? utf8cv(title) : title
  bplist_data['playlistDescription'] = sjis ? utf8cv(description) : description
  bplist_data['playlistAuthor'] = sjis ? utf8cv(author) : author
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

def playlist_convert2(title,profile_picture,ss_data)
  bplist_data = {}
  songs_array = []
  ss_data.each do |songs|
    song_data = {}
    song_data['songName'] = songs[10]
    song_data['levelAuthorName'] = songs[9]
    song_data['hash'] = songs[1]
    characteristic = songs[12].split('_')[2].sub(/(Solo|Party|Multiplayer)/,'')
    diff_name      = songs[12].split('_')[1]
    song_data['difficulties'] = [{'characteristic' => characteristic,'name' => diff_name}]
    songs_array.push song_data
  end
  bplist_data['songs'] = songs_array
  bplist_data['playlistTitle'] = title
  ext = "jpg"
  ext = $1 if profile_picture =~ /\.(\w+)$/
  image_file = "#{EXE_DIR}temp.#{ext}"
  puts "user:#{title} Profile Picture Get"
  begin
    `curl.exe --connect-timeout #{CURL_TIMEOUT} --output "#{image_file}" #{profile_picture}`
  rescue
    image_file = false
  end
  if image_file && File.exist?(image_file)
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
    if $Exerb
      #アイコンの設定
      extractIconA = Win32API.new('shell32','ExtractIconA','LPI','L')
      myIconData = extractIconA.Call(0, "#{EXE_DIR}#{File.basename(MAIN_RB, '.*')}.exe", 0)
      sendMessage(128, 0, myIconData)
    end
    self.x = 330
    self.y = 70
    @limit_checkBox.check true
    @tab_checkBox.check true
    @radio_top.check true
    @nameoutput_checkBox.check true
    if File.exist?(SETTING_FILE)
      setting = JSON.parse(File.read(SETTING_FILE))
      @userid_edit.caption = setting['UserID']          if setting['UserID']
      @limit_checkBox.check false                       if setting['Limit'] == false
      @limit_edit.caption = setting['Limit']            if setting['Limit']
      @edit_api_limit.caption = setting['APILimit']     if setting['APILimit']
      @tab_checkBox.check false                         if setting['TSV'] == false
      @author_edit.caption = setting['Author']          if setting['Author']
      @namecol_edit.caption = setting['SongnameColumn'] if setting['SongnameColumn']
      @hashcol_edit.caption = setting['SongIDcolumn']   if setting['SongIDcolumn']
      @nameoutput_checkBox.check false                  if setting['SongnameOutput'] == false
      self.x = setting['form_x']                        if setting['form_x']
      self.y = setting['form_y']                        if setting['form_y']
      if setting['sort_recent']
        @radio_recent.check true
        @radio_top.check false
      end
    end
    self.caption += "  Ver #{SOFT_VER}"
    @prgrssBar1.setRange(0,100)
    @tz_static.caption = Time.now.zone
  end
  
  #ScoreSaber Userデータ プレイリスト変換ボタン
  def get_button2_clicked
    #ボタンをDisableにする
    @get_button.style     = 1476395008
    @get_button2.style    = 1476395008
    @imgopen_button.style = 1476395008
    @create_button.style  = 1476395008
    @playlist_tsv_button.style = 1476395008
    @prgrssBar1.position = 0
    refresh
    userid = @userid_edit.text.strip
    limit = @limit_edit.text.strip.to_i
    limit = false unless @limit_checkBox.checked? && limit > 0
    api_limit = @edit_api_limit.text.to_i
    api_limit = 100 if api_limit <= 0
    player,profile_picture,ss_data = user_score_get(userid,api_limit,limit,@radio_recent.checked?,@prgrssBar1,@read_static)
    if ss_data
      @prgrssBar1.position = 100
      select_ext = '*.bplist'
      file_type = ["BeatSaber PlayList(*.bplist)","*.bplist"]
      if @radio_recent.checked?
        sort = 'recent'
      else
        sort = 'top'
      end
      title = "#{player} #{sort} #{ss_data.size}"
      playlist_data = playlist_convert2(title,profile_picture,ss_data)
      if playlist_data
        fn = SWin::CommonDialog::saveFilename(self,[file_type,["all file (*.*)","*.*"]],0x1004,'PLAYLIST SAVE FILE',select_ext,0,sjiscv(player + "_#{sort}").gsub(/[\\\/:\*\?\"<>|]/,'_'))
        return unless fn
        if File.exist?(fn)
          return unless messageBox("Do you want to overwrite?","Overwrite confirmation",0x0004) == 6
        end
        File.open(fn,'w') do |file|
          JSON.pretty_generate(playlist_data).each do |line|
            file.puts line
          end
          puts "#{fn}:PlayList SaveOK!"
        end
      end
    else
      #取得データが異常時は警告表示
      messageBox("ScoreSaber READ ERROR","ERROR",0)
      @prgrssBar1.position = 0
    end
    #ボタンをEnableにする
    @prgrssBar1.position = 0
    @get_button.style     = 1342177280
    @get_button2.style    = 1342177280
    @imgopen_button.style = 1342177280
    @create_button.style  = 1342177280
    @playlist_tsv_button.style = 1342177280
    @read_static.caption  = ""
    refresh
  end
  
  #ScoreSaber Userデータ TSV変換
  def get_button_clicked
    #ボタンをDisableにする
    @get_button.style     = 1476395008
    @get_button2.style    = 1476395008
    @imgopen_button.style = 1476395008
    @create_button.style  = 1476395008
    @playlist_tsv_button.style = 1476395008
    @prgrssBar1.position = 0
    refresh
    userid = @userid_edit.text.strip
    limit = @limit_edit.text.strip.to_i
    limit = false unless @limit_checkBox.checked? && limit > 0
    api_limit = @edit_api_limit.text.to_i
    api_limit = 100 if api_limit <= 0
    player,profile_picture,ss_data = user_score_get(userid,api_limit,limit,@radio_recent.checked?,@prgrssBar1,@read_static)
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
      fn = SWin::CommonDialog::saveFilename(self,[file_type,["all file (*.*)","*.*"]],0x1004,'USER SCORE LIST SAVE FILE',select_ext,0,"#{sjiscv(player)}_scorelist")
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
          record << ['uid','id','rank','time','pp','ppw','base score','modified score','max score','mapper','name','song_sub','difficulty']
          ss_data.each do |row|
            record << row
          end
        end
      end
    end
    #ボタンをEnableにする
    @prgrssBar1.position = 0
    @get_button.style     = 1342177280
    @get_button2.style    = 1342177280
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
      setting['Limit']      = @limit_edit.text.strip
    else
      setting['Limit']      = false
    end
    setting['APILimit']       = @edit_api_limit.text.strip
    setting['TSV']            = @tab_checkBox.checked?
    setting['Author']         = @author_edit.text.strip
    setting['SongnameColumn'] = @namecol_edit.text.strip
    setting['SongIDcolumn']   = @hashcol_edit.text.strip
    setting['SongnameOutput'] = @nameoutput_checkBox.checked?
    setting['form_x']         = self.x
    setting['form_y']         = self.y
    setting['sort_recent']    = @radio_recent.checked?
    File.open(SETTING_FILE,'w') do |file|
      JSON.pretty_generate(setting).each do |line|
        file.puts line
      end
    end
  end
  
  def default_menu_clicked
    @tab_checkBox.check true
    @nameoutput_checkBox.check true
    @limit_checkBox.check true
    @limit_edit.caption = 100
    @userid_edit.caption = ''
    @author_edit.caption = ''
    @namecol_edit.caption = 'name'
    @hashcol_edit.caption = 'id'
  end

  def version_menu_clicked
    messageBox("BeatSaber PlayList TOOL Ver#{SOFT_VER} for ActiveScriptRuby(1.8.7-p330)\r\nCopyright 2019 Rynan.  (Twitter @rynan4818)" ,"Version",0)
  end

end

if ARGV == []
  #GUIメッセージループ
  VRLocalScreen.start Frm_main_form
else
  userid        = ARGV[0] #省略不可
  playlist_file = ARGV[1] #省略不可
  sort          = ARGV[2] #省略時 top
  limit         = ARGV[3] #省略時 100
  api_limit     = ARGV[4] #省略時 100
  title         = ARGV[5] #省略時 プレイヤー ソート 取得数
  if userid && playlist_file
    limit = 100 unless limit
    limit = limit.to_i
    api_limit = 100 unless api_limit
    api_limit = api_limit.to_i
    api_limit = 100 if api_limit <= 0
    sort_recent = false
    sort_recent = true if sort =~ /recent/
    if sort_recent
      sort = "recent"
    else
      sort = "top"
    end
    player,profile_picture,ss_data = user_score_get(userid,api_limit,limit,sort_recent)
    if ss_data
      title = "#{player} #{sort} #{ss_data.size}" unless title
      playlist_data = playlist_convert2(title,profile_picture,ss_data)
      if playlist_data
        File.open(playlist_file,'w') do |file|
          JSON.pretty_generate(playlist_data).each do |line|
            file.puts line
          end
          puts "#{playlist_file}:PlayList SaveOK!"
        end
      end
    else
      puts "User score data get error."
    end
  else
    puts "userid and playlist file name are missing."
  end
end
