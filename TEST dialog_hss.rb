module EA_Extensions623
  module EASteelTools
    class Hss_Html_Dialog

      def initialize
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
          :style => UI::HtmlDialog::STYLE_DIALOG
        })
        p 'test to get to setting file'
        fpath = Sketchup.find_support_file("HTML/steel_hss_dialog.html", "Plugins/ea_steel_tools")
        # fpath = Sketchup.find_support_file("icons/wfs_icon_rolled_select.png", "Plugins/ea_steel_tools")
        p fpath
        if fpath
          dialog.set_file(fpath)
        else
          dialog.set_html('<b>Hello world!</b>')
        end

        dialog.show
      end


    end
  end
end
