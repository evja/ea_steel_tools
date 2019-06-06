#Initialize the console with some of these options to get working

#As of 3/15/2017 this tool has over 7400 lines of code

model = Sketchup.active_model
ents = model.entities
sel = model.selection
scenes = model.pages
#CONSTANT LIBRARY
load 'ea_steel_tools/magic_numbers.rb'

#LayerHelper
load 'ea_steel_tools/layer_helper.rb'

#HSS Files
load 'ea_steel_tools/tube_steel_data.rb'
load 'ea_steel_tools/dialog_tube_steel.rb'
load 'ea_steel_tools/hss_library.rb'

#Rolled Flange Tool Files
load 'ea_steel_tools/wide_flange_rolled_data.rb'
load 'ea_steel_tools/dialog_rolled.rb'

#Main Files
load 'ea_steel_tools/steel_tools_menus.rb'
load 'ea_steel_tools/control.rb'

#Flange Tool Files
load 'ea_steel_tools/wide_flange_data.rb'
load 'ea_steel_tools/dialog.rb'

#Layout Files (Under Construction)
# load 'ea_steel_tools/layout_send.rb'

#Breakout Files
# load 'ea_steel_tools/breakout_setup.rb'
# load 'ea_steel_tools/breakout.rb'
# load 'ea_steel_tools/breakout_send.rb'


#Guide Tools Files (Depricated)
# load 'ea_guide_tools/ea_guide_tools.rb'
# load 'ea_steel_tools_loader.rb'
# load 'ea_steel_tools/Updater/updater.rb'


load 'ea_steel_tools/plate_observer.rb'



#Test Crap, not sure why i have these here,
dialog = UI::HtmlDialog.new(
{
  :dialog_title => "Dialog Example",
  :preferences_key => "com.sample.plugin",
  :scrollable => true,
  :resizable => true,
  :width => 600,
  :height => 400,
  :left => 100,
  :top => 100,
  :min_width => 50,
  :min_height => 50,
  :max_width =>1000,
  :max_height => 1000,
  :style => UI::HtmlDialog::STYLE_UTILITY
})
dialog.set_url("http://www.sketchup.com")
dialog.show

@params = []

def get_params(plate)
  a = []
  a.push plate.bounds.width.to_f
  a.push plate.bounds.depth.to_f
  a.push plate.bounds.height.to_f
  a.sort!
  a.push plate.volume.to_f
  a.push plate.definition.name
  @params.push a
end
sel.each{|p| get_params(p)}

CSV.open("plate_data.csv","w") do |csv|
  csv << ["Value1", "Value2", "Value3", "Volume", "Name"]
  @params.each {|pm| csv << pm}
end


def print_w_h_d(ent)
  p "Width is #{ent.bounds.width.to_f}"
  p "Depth is #{ent.bounds.depth.to_f}"
  p "Height is #{ent.bounds.height.to_f}"
  p "Volume is #{ent.volume}"
end