module EA_Extensions623
  module HSSLibrary

    #this is the generic data for a beam, copy it to where you need it and input the values
    # "(size)" => { h: , b: , t: , c: ().mm, width_class: },

    def find_tube( height_class, beam )
          input = HSSLibrary::BEAMS["#{height_class}"]["#{beam}"]
          return input
    end

    def all_height_classes
      beams = []
      HSSLibrary::BEAMS.each do |k, v|
        beams << k
      end
      return beams
    end

    #returns an array of all the beams within a height class
    def all_beams_in(height_class)
      beams = []
      HSSLibrary::BEAMS["#{height_class}"].each do |k, v|
        beams << k
      end
      return beams
    end

    HSS = {
      "4X" => {
        "4X" => { h: , b: , t: , c: ().mm, width_class: },
      }

      "5X" => {

      }

      "6X" => {

      }

      "8X" => {

      }
    }

  end
end