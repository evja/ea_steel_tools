module EA_Extensions623
  module EASteelTools
  require 'sketchup.rb'
    module ToolUpdater
      ### CONSTANTS ### ------------------------------------------------------------
      PLATFORM_IS_OSX     = (Object::RUBY_PLATFORM =~ /darwin/i) ? true : false
      PLATFORM_IS_WINDOWS = !PLATFORM_IS_OSX
      def self.update_tool( rbz = true )
        extension = ( rbz ) ? '*.rbz' : '*.zip'
        file = UI.openpanel( "Look for version greater than #{VERSION_NUM}", nil, extension )
        UI.messagebox(file)
        return if file.nil?
        begin
          Sketchup.install_from_archive( file )
        rescue Interrupt => error
          #UI.messagebox "User said 'no': #{error}"
          puts "User said 'no': #{error}"
        rescue Exception => error
          UI.messagebox "Error during installation: #{error}"
        end
      end
      file_loaded( __FILE__ )

    end
  end
end
