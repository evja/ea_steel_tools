module EA_Extensions623
  module EASteelTools
    require 'sketchup'

    require FNAME+'/'+'control.rb'
    require FNAME+'/'+'beam_library.rb'
    require FNAME+'/'+'hss_library.rb'
    require FNAME+'/'+'dialog.rb'
    require FNAME+'/'+'tube_steel_data.rb'
    require FNAME+'/'+'dialog_rolled.rb'
    require FNAME+'/'+'dialog_tube_steel.rb'
    require FNAME+'/'+'wide_flange_data.rb'
    require FNAME+'/'+'wide_flange_rolled_data.rb'
    require FNAME+'/'+'tube_steel_data.rb'
    require FNAME+'/'+'breakout_setup.rb'
    require FNAME+'/'+'breakout.rb'
    require FNAME+'/'+'breakout_send.rb'
    require FNAME+'/'+'load_schemas.rb'
    require FNAME+'/'+'magic_numbers.rb'
    require FNAME+'/'+'update.rb'
    require FNAME+'/'+'layer_helper.rb'
    require FNAME+'/'+'plate_observer.rb'
    require FNAME+'/'+'export_plates.rb'
    # require FNAME+'/'+'test.rb'

  if !file_loaded?('ea_steel_tools_menu_loader')
    @@EA_tools_menu = UI.menu("Extensions").add_submenu("Steel Tools")
  end

  unless file_loaded? (__FILE__)
    toolbar = UI::Toolbar.new " EA Steel Tools"

    cmd = UI::Command.new("Wide Flange") {
      @@wide_flange_tool = Sketchup.active_model.select_tool EASteelTools::Window.new
    }
    @@EA_tools_menu.add_item cmd
    cmd.small_icon = "icons/wfs_icon1.png"
    cmd.large_icon = "icons/wfs_icon1.png"
    cmd.tooltip = "Draw Wide Flange Steel"
    cmd.status_bar_text = "Draw Steel Members"
    cmd.menu_text = "Wide Flange Steel"
    toolbar = toolbar.add_item cmd

    cmd1 = UI::Command.new("Rolled Wide Flange") {
     @@rolled_flange_tool = Sketchup.active_model.select_tool @two = EASteelTools::RolledDialog.new
    }
    @@EA_tools_menu.add_item cmd1
    cmd1.small_icon = "icons/wfs_icon_rolled_easy.png"
    cmd1.large_icon = "icons/wfs_icon_rolled_easy.png"
    cmd1.tooltip = "Draw Rolled Wide Flange Steel"
    cmd1.status_bar_text = "Draw Rolled Steel Members"
    cmd1.menu_text = "Wide Rolled Flange Steel"
    toolbar = toolbar.add_item cmd1


    cmd3 = UI::Command.new("HSS Steel") {
     Sketchup.active_model.abort_operation
     @@hss_tool = Sketchup.active_model.select_tool(EASteelTools::HssDialog.new)
    }
    @@EA_tools_menu.add_item cmd3
    cmd3.small_icon = "icons/ts_icon1.png"
    cmd3.large_icon = "icons/ts_icon1.png"
    cmd3.tooltip = "Draw Tube Steel"
    cmd3.status_bar_text = "Draw Tube Steel Members"
    cmd3.menu_text = "Tube Steel"
    toolbar = toolbar.add_item cmd3

    @@EA_tools_menu.add_separator

    cmd2 = UI::Command.new("Steel Tool Settings") {
      Sketchup.active_model.select_tool EASteelTools::BreakoutSettings.open
    }
    @@EA_tools_menu.add_item cmd2

    # @@EA_tools_menu.add_item( 'Check for updates' ) { EASteelTools::ToolUpdater.update_tool }

    toolbar.show


    UI.add_context_menu_handler do |menu|
      menu.add_separator
      menu.add_item("--Send to Breakout") { EASteelTools::SendToBreakout.new }
    end

    UI.add_context_menu_handler do |menu|
      menu.add_item("--Breakout") {Sketchup.active_model.select_tool EASteelTools::Breakout.new }
    end

    UI.add_context_menu_handler do |menu|
      if EASteelTools::ExportPlates.qualify_for_dxf
        menu.add_item("--Prepare DXF") {EASteelTools::ExportPlates.new}
      end
    end

    cmd4 = UI::Command.new("DirtyLayerCleanup") {
      Sketchup.active_model.select_tool EASteelTools::LayerHelper.new
    }
    @@EA_tools_menu.add_item cmd4

    # UI.add_context_menu_handler do |menu|
    #   menu.add_item("Send to Layout") { EASteelTools::SendToLayout.new(Sketchup.active_model.selection[0], Sketchup.active_model.path) }
    #   menu.add_separator
    # end

    # UI.add_context_menu_handler do |menu|
    #   menu.add_item("addObserverToPlate") { Sketchup.active_model.selection[0].add_observer(MyPlateObserver.new(Sketchup.active_model.selection[0]))}
    #   # menu.add_separator
    # end

  end

  file_loaded('ea_steel_tools_menu_loader')
  file_loaded(__FILE__)

  end
end