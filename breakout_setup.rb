# page1 = {name: "Perspective", use_camera?: true, style: "Standard.style",  }

module EA_Extensions623
  module EASteelTools
    require 'sketchup'

    module BreakoutSetup

      def self.set_styles(model)
        style1_file = Sketchup.find_support_file('Standard.style', "Plugins/#{FNAME}/Models/Styles/")
        style2_file = Sketchup.find_support_file('X-ray.style', "Plugins/#{FNAME}/Models/Styles/")
        model.styles.add_style style1_file, true
        model.styles.add_style style2_file, false
        return model.styles
      end

      def self.set_scenes(model)
        scenes = ["Perspective", "Front", "Plates", "Non-X-Ray", "X-Ray"]
        pages = model.pages
        scenes.each {|scene| pages.add scene}
        view = model.active_view
        pages.selected_page = pages[0]
        pages[-1].use_style = model.styles['X-Ray']
        return pages
      end

      def self.set_cameras(model)

      end

      def self.set_materials(model)
        material_files = Sketchup.find_support_files('skm', 'Plugins/ea_steel_tools/Colors')
        material_files.each do |m_file|
          model.materials.load(m_file)
        end
      end

    end #BreakoutScenes

  end #EASteelTools
end #EA_Extensions623