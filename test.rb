module EA_Extensions623
  module EASteelTools

    class NewStyleWindow
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
          :style => UI::HtmlDialog::STYLE_UTILITY
        })
        file = Sketchup.find_support_file("#{ROOT_FILE_PATH}/test.html.erb", "Plugins/")
        p file
        dialog.set_file(file)
        dialog.show

      end

    end
  end
end