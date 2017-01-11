module EA_Extensions623
  module EASteelTools
    require 'sketchup'
    require FNAME+'/'+'control.rb'
    require FNAME+'/'+'beam_library.rb'
    require FNAME+'/'+'dialog.rb'
    require FNAME+'/'+'wide_flange_data.rb'
    require FNAME+'/'+'dialog_rolled.rb'
    require FNAME+'/'+'wide_flange_rolled_data.rb'
    require FNAME+'/'+'breakout.rb'
    require FNAME+'/'+'breakout_send.rb'
    require FNAME+'/'+'test.rb'

    # require 'hss_column_data.rb'         # Coming Soon

  if !file_loaded?('ea_steel_tools_menu_loader')
    @@EA_tools_menu = UI.menu("Extensions").add_submenu("Steel Tools")
  end

  unless file_loaded? (__FILE__)
    toolbar = UI::Toolbar.new " EA Steel Tools"

    cmd = UI::Command.new("Wide Flange") {
      Sketchup.active_model.select_tool EASteelTools::Window.new
    }
    @@EA_tools_menu.add_item cmd
    cmd.small_icon = "icons/wfs_icon1.png"
    cmd.large_icon = "icons/wfs_icon1.png"
    cmd.tooltip = "Draw Wide Flange Steel"
    cmd.status_bar_text = "Draw Flange"
    cmd.menu_text = "Wide Flange Steel"
    toolbar = toolbar.add_item cmd
    toolbar.show

    cmd1 = UI::Command.new("Rolled") {
     Sketchup.active_model.select_tool @two = EASteelTools::RolledDialog.new
    }
    @@EA_tools_menu.add_item cmd1
    cmd1.small_icon = "icons/wfs_icon_rolled.png"
    cmd1.large_icon = "icons/wfs_icon_rolled.png"
    cmd1.tooltip = "Draw Rolled Wide Flange Steel"
    cmd1.status_bar_text = "Draw Rolled Steel"
    cmd1.menu_text = "Wide Rolled Flange Steel"
    toolbar = toolbar.add_item cmd1
    toolbar.show

    # cmd = UI::Command.new("HSS") {
    #  Sketchup.active_model.select_tool EASteelTools::HssColumn.new
    # }
    # @@EA_tools_menu.add_item cmd
    # cmd.small_icon = "icons/wfs_icon_column.png"
    # cmd.large_icon = "icons/wfs_icon_column.png"
    # cmd.tooltip = "Draw Hollow Structural Sections"
    # cmd.status_bar_text = "Draw Column"
    # cmd.menu_text = "Wide HSS Columns"
    # toolbar = toolbar.add_item cmd
    # toolbar.show

    UI.add_context_menu_handler do |menu|
      if not( EASteelTools::BreakoutMod.qualify_model(Sketchup.active_model) )
        if( EASteelTools::BreakoutSendMod.qualify_selection(Sketchup.active_model.selection) )
          menu.add_separator
          menu.add_item("Send to Breakout") { EASteelTools::SendToBreakout.new }
          menu.add_separator
        end
      end
    end

    UI.add_context_menu_handler do |menu|
      if( EASteelTools::BreakoutMod.qualify_model(Sketchup.active_model) )
        menu.add_separator
        menu.add_item("Breakout") { EASteelTools::Breakout.new }
        menu.add_separator
      end
    end

  end

  file_loaded('ea_steel_tools_menu_loader')
  file_loaded(__FILE__)

  end
end