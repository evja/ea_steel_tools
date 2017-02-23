module EA_Extensions623
  module EASteelTools
    PATH_TO_UPDATED_TOOL = "//DELL/Data"


    class ToolUpdater

      def initialize
        @tool_folder = __FILE__
        @plugin_tool = Sketchup.find_support_file FNAME, 'Plugins'
        p @tool_folder
        p @plugin_tool
        p 'Hey'
        p 'Boo'
        activate
      end

      def activate
        p 'does this activate??'
      end

      def find_files

      end
    end

  end
end