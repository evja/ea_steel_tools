module EA_Extensions623
  module EASteelTools
    ####################
    ## MAIN CONSTANTS ##
    ####################
    ROOT_FILE_PATH = "ea_steel_tools"

    #Setc the north direction as the green axis
    NORTH = Geom::Vector3d.new [0,1,0]


    #########################
    ## COMPONENT CONSTANTS ##
    #########################
    COMPONENT_PATH     = "#{ROOT_FILE_PATH}/Beam Components"
    NN_SXTNTHS_HOLE    = "9_16 Hole Set.skp"
    THRTN_SXTNTHS_HOLE = "13_16 Hole Set.skp"
    UP_DRCTN           = "UP.skp"
    UP_DRCTN_SM           = "UP_SM.skp"
    HLF_INCH_STD       = "2_Studs.skp"
    STEEL_FONT         = "1CamBam_Stick_7"
    NORTH_LABEL        = "N.skp"
    SOUTH_LABEL        = "S.skp"
    EAST_LABEL         = "E.skp"
    WEST_LABEL         = "W.skp"

    #########################
    # MEASUREMENT CONSTANTS #
    #########################
    RADIUS_RULE = 2
    # Standard label height
    LABEL_HEIGHT = 2


    ###########################
    ## WIDE FLANGE CONSTANTS ##
    ###########################
    #Sets the root radus for the beams
    RADIUS = 3
    #This sets the distance from the end of the beam the direction labels go
    LABELX = 10
    #Sets the distance from the ends of the beams that holes cannot be, in inches
    NO_HOLE_ZONE = 6
    #Sets the minimum beam length before the web holes do not stagger(Actual minimum is < 8)
    MINIMUM_BEAM_LENGTH = 16
    # This sets the stiffener location from each end of the beam
    STIFF_LOCATION = 2
    #Distance from the end of the beam the 13/14" holes are placed
    BIG_HOLES_LOCATION = 4
    # Minimum distance from the inside of the flanges to the center of 13/16" holes can be
    MIN_BIG_HOLE_DISTANCE_FROM_KZONE = 1.5


    ##################################
    ## WIDE FLANGE COLUMN CONSTANTS ##
    ##################################
    #Sets label distance from the bottom of the column
    LABEL_HEIGHT_FROM_FLOOR = 10
    #Sets tyhe distance from the top of the column to the stiffeners
    STIFFENER_DIST = 0

    ###################
    ## HSS CONSTANTS ##
    ###################

    # Most of these constants are not in use as the hss tools pulls the components from a library rather than draws them from scatch using these rules
    STANDARD_BASE_MARGIN = 3
    MINIMUM_WELD_OVERHANG = 0.25
    STANDARD_WELD_OVERHANG = 0.75
    HOLE_OFFSET = 1.5
    BASEPLATE_RADIUS = 0.5
    RADIUS_SEGMENT = 6
    STANDARD_TOP_PLATE_SIZE = 7
    MINIMUM_STUD_DIST_FROM_HSS_ENDS = 7.25
    HSS_BEAM_CAP_THICK = 0 # needs to be whatever the standard cap plates are
    BOTTOM_PLATE_CORNER_RADIUS = 0.5
    STANDARD_BASE_PLATE_THICKNESS = 0.75

    BASETYPES = ["SQ","OC","IL","IC","EX","DR","DL","DI", "Bryceplate"]


    # Normal steel colors for 3DS conventions and procedures
    STEEL_COLORS = {
      red:     {name: ' B Special Thick', rgb: [255,50,50]},
      orange:  {name: ' C ¾" Thick',      rgb: [255,135,50]},
      yellow:  {name: ' D ⅝" Thick',      rgb: [255,255,50]},
      green:   {name: ' E ½" Thick',      rgb: [50,255,50 ]},
      blue:    {name: ' F ⅜" Thick',      rgb: [50,118,255]},
      indigo:  {name: ' G 5/16" Thick',   rgb: [118,50,255]},
      purple:  {name: ' H ¼" Thick',      rgb: [186,50,255]},
      grey:    {name: '1 Done',           rgb: [153,153,153]},
      layedout:    {name: '2 Layed Out',      rgb: [153,127,127]},
      brokeout:    {name: '3 Broken Out',     rgb: [255,180,127]},
      modeled:    {name: '4 Modeled',        rgb: [255,255,127]},
      pink:    {name: 'Edit', rgb: [255,25,113]}
    }

  end
end