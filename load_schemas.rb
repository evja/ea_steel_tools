module EA_Extensions623
  module EASteelTools
    module SchemaLoader
      require 'sketchup'
      require FNAME+'/'+'control.rb'

      unless file_loaded?(__FILE__)
        steel_schema = Sketchup.find_support_file('steel.skc', "Plugins/#{FNAME}/Schemas/")
        # steel_schema = Sketchup.find_support_file('steel.skc', "Classifications")
        c = Sketchup.active_model.classifications
        begin
          status = c.load_schema(steel_schema)

        rescue => exception
          p 'There was a problem loading the Schema Classification'
        end
      end

    end
  end
end