
module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'
    require 'benchmark'

    module ExportPlates
      @model = Sketchup.active_model
      @ents = @model.entities
      @sel = @model.selection

      def self.qualify_plates
        @sel.each do |plate|
          p plate
          if plate.attribute_dictionaries[DICTIONARY_NAME]
            p 'found'
          else
            p'no attr. dictionaries'
          end
        end
      end

      def position_groups
      end

      def make_wireframe
      end

      def recursive_explosion(ent)
        plane = [Geom::Point3d.new(0, 0, 0), Geom::Vector3d.new(0, 0, 1)]
        ents = ent.explode
        ents.each do |en|
          if (en.is_a? Sketchup::Group) || (en.is_a? Sketchup::ComponentInstance)
            recursive_explosion(en)
          elsif (en.is_a? Sketchup::Face)
            en.erase!
          end
        end
        return ents
      end

      def prep_plates_for_export(group)
        plate_g_cpy = group.copy
        mv = Geom::Transformation.translation([0,-30,0])
        @entities.transform_entities mv, plate_g_cpy
        plates = plate_g_cpy.entities.to_a
        geom = plates.each{|p| recursive_explosion(p)}

        vec = Geom::Vector3d.new(0,0,1)
        vert_edges = (plate_g_cpy.entities.to_a).select{|e| (e.is_a? Sketchup::Edge) && (e.line[1].parallel? vec)}
        plate_g_cpy.entities.erase_entities(vert_edges.to_a)
      end


    end#module

  end #module
end #module