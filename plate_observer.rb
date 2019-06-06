module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'

    class MyPlateObserver < Sketchup::InstanceObserver

      def initialize(entity)
      end

      def onChangeEntity(entity)
        # puts "Entity Changed: #{entity}"
      end

      def onOpen(instance)
        puts "onOpen: #{instance}"
      end

      def onClose(instance)
        puts "onClose: #{instance}"
      end
    end

  end
end
