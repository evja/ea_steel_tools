module EA_Extensions623
  module EASteelTools

    class MasterTest
      include Seed_Data


      def initialize
        # draw_various_hss_columns
      end

      def draw_various_hss_columns
        Sketchup.active_model.select_tool EASteelTools::TubeTool.new(hss_options(1))
      end


    end

  end
end