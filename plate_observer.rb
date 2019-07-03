module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'

    class MyPlateObserver < Sketchup::InstanceObserver
      include Control

      def initialize(entity)
      end

      def onChangeEntity(entity)
        # puts "Entity Changed: #{entity}"
        color_by_thickness(entity, get_width(entity))
      end

      def onOpen(instance)
        puts "onOpen: #{instance}"
      end

      def onClose(instance)
        puts "onClose: #{instance}"
      end

      def get_width(plate)
        temp_group = plate.parent.entities.add_group(temp_plate = plate.copy)
        temp_plate.make_unique
        temp_plate.explode

        lengths = Hash.new(0)
        temp_group.entities.each do |e|
          if e.is_a? Sketchup::Edge
            lengths[e.length] += 1
          else
            next
          end

        end
        width = lengths.max_by{|k,v| v}
        temp_group.erase!
        p width[0].round(2)
        return width[0].round(2)
      end


    end
  end
end
