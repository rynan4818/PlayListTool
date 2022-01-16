## CAUTION!! ## This code was automagically ;-) created by FormDesigner.
# NEVER modify manualy -- otherwise, you'll have a terrible experience.

require 'vr/vruby'
require 'vr/vrcontrol'
require 'vr/vrcomctl'

module Frm_main_form
  include VRMenuUseable if defined? VRMenuUseable

  def _main_form_init
    self.caption = 'BeatSaber PlayList TOOL'
    self.move(330,70,498,761)
    @mainmenu = newMenu.set(
      [
        ["&File",[
          ["E&xit", "exit_menu"]]
        ],
        ["&Setting",[
          ["&Save", "save_menu"],
          ["&Default", "default_menu"]]
        ],
        ["&Help",[
          ["Versio&n", "version_menu"]]
        ]
      ]
    )
    setMenu(@mainmenu,true)
    #$_ctn_mainmenu=[419,8]
    addControl(VRStatic,'static13',"API Limit",40,304,64,24,1342177280)
    addControl(VRStatic,'tz_static',"",112,40,344,24,1342177280)
    addControl(VREdit,'namecol_edit',"name",216,592,128,24,1342177408)
    addControl(VREdit,'author_edit',"",24,592,176,24,1342177408)
    addControl(VREdit,'limit_edit',"100",168,136,48,24,1342177408)
    addControl(VRStatic,'static2',"ScoreSaber UserID",24,72,408,24,1342177280)
    addControl(VRButton,'playlist_tsv_button',"PlayList to TSV(CSV)",248,296,200,32,1342177280)
    addControl(VRButton,'imgopen_button',"Open",376,424,88,24,1342177280)
    addControl(VREdit,'description_edit',"",24,536,440,24,1342177408)
    addControl(VRStatic,'static11',"SongID column",216,624,128,24,1342177280)
    addControl(VREdit,'userid_edit',"",24,96,424,24,1342177408)
    addControl(VRButton,'get_button',"ScoreList to TSV(CSV)",248,256,200,32,1342177280)
    addControl(VRStatic,'static7',"Description",24,512,224,24,1342177280)
    addControl(VRButton,'get_button2',"ScoreList to PlayList",32,256,176,32,1342177280)
    addControl(VRStatic,'static10',"Songname column",216,568,136,24,1342177280)
    addControl(VRButton,'create_button',"PlayList SAVE",32,632,128,40,1342177280)
    addControl(VRStatic,'static6',"Cover Image  (drag and drop OK)",24,400,304,24,1342177280)
    addControl(VRStatic,'static12',"Time zone :",24,40,88,24,1342177280)
    addControl(VRCheckbox,'tab_checkBox',"TSV(TAB Separator)",272,224,168,24,1342177283)
    addControl(VRStatic,'read_static',"",32,224,192,24,1342177280)
    addControl(VRRadiobutton,'radio_top',"top",312,136,48,24,1342177289)
    addControl(VRProgressbar,'prgrssBar1',"prgrssBar1",32,184,416,24,1342177280)
    addControl(VRStatic,'static8',"Title",24,456,288,24,1342177280)
    addControl(VRRadiobutton,'radio_recent',"recent",368,136,72,24,1342177289)
    addControl(VRStatic,'static5',"Clipboard to PlayList",24,360,440,24,1342177280)
    addControl(VRStatic,'static3',"sort:",264,136,40,32,1342177280)
    addControl(VREdit,'image_edit',"",24,424,344,24,1342177408)
    addControl(VREdit,'title_edit',"",24,480,440,24,1342177408)
    addControl(VREdit,'edit_api_limit',"100",104,304,48,24,1342177408)
    addControl(VRCheckbox,'nameoutput_checkBox',"output",352,584,72,32,1342177283)
    addControl(VRStatic,'static1',"ScoreList or PlayList to TSV(CSV)",24,8,360,24,1342177280)
    addControl(VRStatic,'static9',"Author",24,568,176,24,1342177280)
    addControl(VRStatic,'static4',"------------------------------------------",16,336,456,16,1342177280)
    addControl(VREdit,'hashcol_edit',"id",216,648,128,24,1342177408)
    addControl(VRCheckbox,'limit_checkBox',"Limit read scores",24,136,144,24,1342177283)
  end 

  def construct
    _main_form_init
  end 

end 

#VRLocalScreen.start Frm_main_form
