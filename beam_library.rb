module EA_Extensions623
  module EASteelTools
      module BeamLibrary

        #this is the generic data for a beam, copy it to where you need it and input the values

        # "" => { d: , bf: , tf: , tw: , r: ().mm, width_class: },


        def find_beam( height_class, beam )
          input = BeamLibrary::BEAMS["#{height_class}"]["#{beam}"]
          return input
        end

        def all_height_classes
          beams = []
          BeamLibrary::BEAMS.each do |k, v|
            beams << k
          end
          return beams
        end

        #returns an array of all the beams within a height class
        def all_beams_in(height_class)
          beams = []
          BeamLibrary::BEAMS["#{height_class}"].each do |k, v|
            beams << k
          end
          return beams
        end

        BEAMS = {

          # 4" TALL BEAMS
          "W4" => {

            "W4x13" => { d: 4.16, bf: 4.060, tf: 0.345, tw: 0.280, r: (6.4).mm, width_class: 4,}

          },

          # 5" TALL BEAMS
          "W5" => {

            "W5x16" => { d: 5.01, bf: 5.000, tf: 0.360, tw: 0.240, r: (7.6).mm, width_class: 5},
            "W5x19" => { d: 5.15, bf: 5.030, tf: 0.430, tw: 0.270, r: (7.6).mm, width_class: 5}

          },

          # 6" TALL BEAMS
          "W6" => {

            "W6x8" => { d: 5.82, bf: 4.000, tf: 0.194, tw: 0.170, r: (6.4).mm, width_class: 4},
            "W6x9" => { d: 5.90, bf: 3.940, tf: 0.215, tw: 0.170, r: (6.4).mm, width_class: 4},
            "W6x12" => { d: 6.03, bf: 4.000, tf: 0.280, tw: 0.230, r: (6.4).mm, width_class: 4},
            "W6x15" => { d: 5.99, bf: 5.990, tf: 0.260, tw: 0.230, r: (7.6).mm, width_class: 6},
            "W6x16" => { d: 6.28, bf: 4.030, tf: 0.405, tw: 0.260, r: (6.4).mm, width_class: 4},
            "W6x20" => { d: 6.20, bf: 6.020, tf: 0.365, tw: 0.260, r: (7.6).mm, width_class: 6},
            "W6x25" => { d: 6.38, bf: 6.080, tf: 0.455, tw: 0.320, r: (7.6).mm, width_class: 6}

          },

          # 8" TALL BEAMS
          "W8" => {

            "W8x10" => { d: 7.89, bf: 3.940, tf: 0.205, tw: 0.170, r: (7.6).mm, width_class: 4},
            "W8x13" => { d: 7.99, bf: 4.000, tf: 0.255, tw: 0.230, r: (7.6).mm, width_class: 4},
            "W8x15" => { d: 8.11, bf: 4.015, tf: 0.315, tw: 0.245, r: (7.6).mm, width_class: 4},
            "W8x18" => { d: 8.14, bf: 5.250, tf: 0.330, tw: 0.230, r: (7.6).mm, width_class: 5.25},
            "W8x21" => { d: 8.28, bf: 5.270, tf: 0.400, tw: 0.250, r: (7.6).mm, width_class: 5.25},
            "W8x24" => { d: 7.93, bf: 6.495, tf: 0.400, tw: 0.245, r: (10.2).mm, width_class: 6.5},
            "W8x28" => { d: 8.06, bf: 6.535, tf: 0.465, tw: 0.285, r: (10.2).mm, width_class: 6.5},
            "W8x31" => { d: 8.00, bf: 7.995, tf: 0.435, tw: 0.285, r: (10.2).mm, width_class: 8},
            "W8x35" => { d: 8.12, bf: 8.020, tf: 0.495, tw: 0.310, r: (10.2).mm, width_class: 8},
            "W8x40" => { d: 8.25, bf: 8.070, tf: 0.560, tw: 0.360, r: (10.2).mm, width_class: 8},
            "W8x48" => { d: 8.50, bf: 8.110, tf: 0.685, tw: 0.400, r: (10.2).mm, width_class: 8},
            "W8x58" => { d: 8.75, bf: 8.220, tf: 0.810, tw: 0.510, r: (10.2).mm, width_class: 8},
            "W8x67" => { d: 9.00, bf: 8.280, tf: 0.935, tw: 0.570, r: (10.2).mm, width_class: 8}

          },

          # 10" TALL BEAMS
          "W10" => {

            "W10x12" => { d: 9.87, bf: 3.960, tf: 0.210, tw: 0.190, r: (7.6).mm, width_class: 4},
            "W10x15" => { d: 9.99, bf: 4.000, tf: 0.270, tw: 0.230, r: (7.6).mm, width_class: 4},
            "W10x17" => { d: 10.11, bf: 4.010, tf: 0.330, tw: 0.240, r: (7.6).mm, width_class: 4},
            "W10x19" => { d: 10.24, bf: 4.020, tf: 0.395, tw: 0.250, r: (7.6).mm, width_class: 4},
            "W10x22" => { d: 10.17, bf: 5.750, tf: 0.360, tw: 0.240, r: (7.6).mm, width_class: 5.75},
            "W10x26" => { d: 10.33, bf: 5.770, tf: 0.440, tw: 0.260, r: (7.6).mm, width_class: 5.75},
            "W10x30" => { d: 10.47, bf: 5.810, tf: 0.510, tw: 0.300, r: (7.6).mm, width_class: 5.75},
            "W10x33" => { d: 9.73,  bf: 7.960, tf: 0.435, tw: 0.290, r: (12.7).mm, width_class: 8},
            "W10x39" => { d: 9.92,  bf: 7.985, tf: 0.530, tw: 0.315, r: (12.7).mm, width_class: 8},
            "W10x45" => { d: 10.10, bf: 8.020, tf: 0.620, tw: 0.350, r: (12.7).mm, width_class: 8},
            "W10x49" => { d: 9.98, bf: 10.000, tf: 0.560, tw: 0.340, r: (12.7).mm, width_class: 10},
            "W10x54" => { d: 10.09, bf: 10.030, tf: 0.615, tw: 0.370, r: (12.7).mm, width_class: 10},
            "W10x60" => { d: 10.22, bf: 10.080, tf: 0.680, tw: 0.420, r: (12.7).mm, width_class: 10},
            "W10x68" => { d: 10.40, bf: 10.130, tf: 0.770, tw: 0.470, r: (12.7).mm, width_class: 10},
            "W10x77" => { d: 10.60, bf: 10.190, tf: 0.870, tw: 0.530, r: (12.7).mm, width_class: 10},
            "W10x88" => { d: 10.84, bf: 10.265, tf: 0.990, tw: 0.605, r: (12.7).mm, width_class: 10},
            "W10x100" => { d: 11.10, bf: 10.340, tf: 1.120, tw: 0.680, r: (12.7).mm, width_class: 10},
            "W10x112" => { d: 11.36, bf: 10.415, tf: 1.250, tw: 0.755, r: (12.7).mm, width_class: 10}

          },

          # 12" TALL BEAMS
          "W12" => {

            "W12x14" => { d: 11.91, bf: 3.970, tf: 0.225, tw: 0.200, r: (7.6).mm, width_class: 4},
            "W12x16" => { d: 11.99, bf: 3.990, tf: 0.265, tw: 0.220, r: (7.6).mm, width_class: 4},
            "W12x19" => { d: 12.16, bf: 4.005, tf: 0.350, tw: 0.235, r: (7.6).mm, width_class: 4},
            "W12x22" => { d: 12.31, bf: 4.030, tf: 0.425, tw: 0.260, r: (7.6).mm, width_class: 4},
            "W12x26" => { d: 12.22, bf: 6.490, tf: 0.380, tw: 0.230, r: (8.9).mm, width_class: 6.5},
            "W12x30" => { d: 12.34, bf: 6.520, tf: 0.440, tw: 0.260, r: (8.9).mm, width_class: 6.5},
            "W12x35" => { d: 12.50, bf: 6.560, tf: 0.520, tw: 0.300, r: (8.9).mm, width_class: 6.5},
            "W12x40" => { d: 11.94, bf: 8.005, tf: 0.515, tw: 0.295, r: (15.2).mm, width_class: 8},
            "W12x45" => { d: 12.06, bf: 8.045, tf: 0.575, tw: 0.335, r: (15.2).mm, width_class: 8},
            "W12x50" => { d: 12.19, bf: 8.080, tf: 0.640, tw: 0.370, r: (15.2).mm, width_class: 8},
            "W12x53" => { d: 12.06, bf: 9.995, tf: 0.575, tw: 0.345, r: (15.2).mm, width_class: 10},
            "W12x58" => { d: 12.19, bf: 10.010, tf: 0.640, tw: 0.360, r: (15.2).mm, width_class: 10},
            "W12x65" => { d: 12.12, bf: 12.000, tf: 0.605, tw: 0.390, r: (15.2).mm, width_class: 12},
            "W12x72" => { d: 12.25, bf: 12.040, tf: 0.670, tw: 0.430, r: (15.2).mm, width_class: 12 },
            "W12x79" => { d: 12.38, bf: 12.080, tf: 0.735, tw: 0.470, r: (15.2).mm, width_class: 12},
            "W12x87" => { d: 12.53, bf: 12.125, tf: 0.810, tw: 0.515, r: (15.2).mm, width_class: 12},
            "W12x96" => { d: 12.71, bf: 12.160, tf: 0.900, tw: 0.550, r: (15.2).mm, width_class: 12},
            "W12x106" => { d: 12.89, bf: 12.220, tf: 0.990, tw: 0.610, r: (15.2).mm, width_class: 12},
            "W12x120" => { d: 13.12, bf: 12.320, tf: 1.105, tw: 0.710, r: (15.2).mm, width_class: 12},
            "W12x136" => { d: 13.41, bf: 12.400, tf: 1.250, tw: 0.790, r: (15.2).mm, width_class: 12},
            "W12x152" => { d: 13.71, bf: 12.480, tf: 1.400, tw: 0.870, r: (15.2).mm, width_class: 12},
            "W12x170" => { d: 14.03, bf: 12.570, tf: 1.560, tw: 0.960, r: (15.2).mm, width_class: 12},
            "W12x190" => { d: 14.38, bf: 12.670, tf: 1.735, tw: 1.060, r: (15.2).mm, width_class: 12},
            "W12x210" => { d: 14.71, bf: 12.790, tf: 1.900, tw: 1.180, r: (15.2).mm, width_class: 12},
            "W12x230" => { d: 15.05, bf: 12.895, tf: 2.070, tw: 1.285, r: (15.2).mm, width_class: 12},
            "W12x252" => { d: 15.41, bf: 13.005, tf: 2.250, tw: 1.395, r: (15.2).mm, width_class: 12},
            "W12x279" => { d: 15.85, bf: 13.140, tf: 2.470, tw: 1.530, r: (15.2).mm, width_class: 12},
            "W12x305" => { d: 16.32, bf: 13.235, tf: 2.705, tw: 1.625, r: (15.2).mm, width_class: 12},
            "W12x336" => { d: 16.82, bf: 13.385, tf: 2.955, tw: 1.775, r: (15.2).mm, width_class: 12}

          },

          # 14" TALL BEAMS
          "W14" => {

            "W14x22" => { d: 13.74, bf: 5.000, tf: 0.335, tw: 0.230, r: (10.2).mm, width_class: 5},
            "W14x26" => { d: 13.91, bf: 5.025, tf: 0.420, tw: 0.225, r: (10.2).mm, width_class: 5},
            "W14x30" => { d: 13.84, bf: 6.730, tf: 0.385, tw: 0.270, r: (10.2).mm, width_class: 6.75},
            "W14x34" => { d: 13.98, bf: 6.745, tf: 0.455, tw: 0.285, r: (10.2).mm, width_class: 6.75},
            "W14x38" => { d: 14.10, bf: 6.770, tf: 0.515, tw: 0.310, r: (10.2).mm, width_class: 6.75},
            "W14x43" => { d: 13.66, bf: 7.995, tf: 0.530, tw: 0.305, r: (15.2).mm, width_class: 8},
            "W14x48" => { d: 13.79, bf: 8.030, tf: 0.595, tw: 0.340, r: (15.2).mm, width_class: 8},
            "W14x53" => { d: 13.92, bf: 8.060, tf: 0.660, tw: 0.370, r: (15.2).mm, width_class: 8},
            "W14x61" => { d: 13.89, bf: 9.995, tf: 0.645, tw: 0.375, r: (15.2).mm, width_class: 10},
            "W14x68" => { d: 14.04, bf: 10.035, tf: 0.720, tw: 0.415, r: (15.2).mm, width_class: 10},
            "W14x74" => { d: 14.17, bf: 10.070, tf: 0.785, tw: 0.450, r: (15.2).mm, width_class: 10},
            "W14x82" => { d: 14.31, bf: 10.130, tf: 0.855, tw: 0.510, r: (15.2).mm, width_class: 10},
            "W14x90" => { d: 14.02, bf: 14.520, tf: 0.710, tw: 0.440, r: (15.2).mm, width_class: 14.5},
            "W14x99" => { d: 14.16, bf: 14.565, tf: 0.780, tw: 0.485, r: (15.2).mm, width_class: 14.5},
            "W14x109" => { d: 14.32, bf: 14.605, tf: 0.860, tw: 0.525, r: (15.2).mm, width_class: 14.5},
            "W14x120" => { d: 14.48, bf: 14.670, tf: 0.940, tw: 0.590, r: (15.2).mm, width_class: 14.5},
            "W14x132" => { d: 14.66, bf: 14.725, tf: 1.030, tw: 0.645, r: (15.2).mm, width_class: 14.5},
            "W14x145" => { d: 14.78, bf: 15.500, tf: 1.090, tw: 0.680, r: (15.2).mm, width_class: 16},
            "W14x159" => { d: 14.98, bf: 15.565, tf: 1.190, tw: 0.745, r: (15.2).mm, width_class: 16},
            "W14x176" => { d: 15.22, bf: 15.650, tf: 1.310, tw: 0.830, r: (15.2).mm, width_class: 16},
            "W14x193" => { d: 15.48, bf: 15.710, tf: 1.440, tw: 0.890, r: (15.2).mm, width_class: 16},
            "W14x211" => { d: 15.72, bf: 15.800, tf: 1.560, tw: 0.980, r: (15.2).mm, width_class: 16},
            "W14x233" => { d: 16.04, bf: 15.890, tf: 1.720, tw: 1.070, r: (15.2).mm, width_class: 16},
            "W14x257" => { d: 16.38, bf: 15.995, tf: 1.890, tw: 1.175, r: (15.2).mm, width_class: 16},
            "W14x283" => { d: 16.74, bf: 16.110, tf: 2.070, tw: 1.290, r: (15.2).mm, width_class: 16},
            "W14x311" => { d: 17.12, bf: 16.230, tf: 2.260, tw: 1.410, r: (15.2).mm, width_class: 16},
            "W14x342" => { d: 17.54, bf: 16.360, tf: 2.470, tw: 1.540, r: (15.2).mm, width_class: 16},
            "W14x370" => { d: 17.92, bf: 16.475, tf: 2.660, tw: 1.655, r: (15.2).mm, width_class: 16},
            "W14x398" => { d: 18.29, bf: 16.590, tf: 2.845, tw: 1.770, r: (15.2).mm, width_class: 16},
            "W14x426" => { d: 18.67, bf: 16.695, tf: 3.035, tw: 1.875, r: (15.2).mm, width_class: 16},
            "W14x455" => { d: 19.02, bf: 16.835, tf: 3.210, tw: 2.015, r: (15.2).mm, width_class: 16},
            "W14x500" => { d: 19.60, bf: 17.101, tf: 3.500, tw: 2.190, r: (15.2).mm, width_class: 16},
            "W14x550" => { d: 20.24, bf: 17.200, tf: 3.820, tw: 2.380, r: (15.2).mm, width_class: 16},
            "W14x605" => { d: 20.92, bf: 17.415, tf: 4.160, tw: 2.595, r: (15.2).mm, width_class: 16},
            "W14x665" => { d: 21.64, bf: 17.650, tf: 4.520, tw: 2.830, r: (15.2).mm, width_class: 16},
            "W14x730" => { d: 22.42, bf: 17.890, tf: 4.910, tw: 3.070, r: (15.2).mm, width_class: 16}

          },

          # 16" TALL BEAMS
          "W16" => {

            "W16x26" => { d: 15.69, bf: 5.500, tf: 0.345, tw: 0.250, r: (10.2).mm, width_class: 5.5},
            "W16x31" => { d: 15.88, bf: 5.525, tf: 0.440, tw: 0.275, r: (10.2).mm, width_class: 5.5},
            "W16x36" => { d: 15.86, bf: 6.985, tf: 0.430, tw: 0.295, r: (10.2).mm, width_class: 7},
            "W16x40" => { d: 16.01, bf: 6.995, tf: 0.505, tw: 0.305, r: (10.2).mm, width_class: 7},
            "W16x45" => { d: 16.13, bf: 7.035, tf: 0.565, tw: 0.345, r: (10.2).mm, width_class: 7},
            "W16x50" => { d: 16.26, bf: 7.070, tf: 0.630, tw: 0.380, r: (10.2).mm, width_class: 7},
            "W16x57" => { d: 16.43, bf: 7.120, tf: 0.715, tw: 0.430, r: (10.2).mm, width_class: 7},
            "W16x67" => { d: 16.33, bf: 10.235, tf: 0.665, tw: 0.395, r: (10.2).mm, width_class: 10.25},
            "W16x77" => { d: 16.52, bf: 10.295, tf: 0.760, tw: 0.455, r: (10.2).mm, width_class: 10.25},
            "W16x89" => { d: 16.75, bf: 10.365, tf: 0.875, tw: 0.525, r: (10.2).mm, width_class: 10.25},
            "W16x100" => { d: 16.97, bf: 10.425, tf: 0.985, tw: 0.585, r: (10.2).mm, width_class: 10.25}

          },

          # 18" TALL BEAMS
          "W18" => {

            "W18x35" => { d: 17.70, bf: 6.000, tf: 0.425, tw: 0.300, r: (10.2).mm, width_class: 6},
            "W18x40" => { d: 17.90, bf: 6.015, tf: 0.525, tw: 0.315, r: (10.2).mm, width_class: 6},
            "W18x46" => { d: 18.06, bf: 6.060, tf: 0.605, tw: 0.360, r: (10.2).mm, width_class: 6},
            "W18x50" => { d: 17.99, bf: 7.495, tf: 0.570, tw: 0.355, r: (10.2).mm, width_class: 7.5},
            "W18x55" => { d: 18.11, bf: 7.530, tf: 0.630, tw: 0.390, r: (10.2).mm, width_class: 7.5},
            "W18x60" => { d: 18.24, bf: 7.555, tf: 0.695, tw: 0.415, r: (10.2).mm, width_class: 7.5},
            "W18x65" => { d: 18.35, bf: 7.590, tf: 0.750, tw: 0.450, r: (10.2).mm, width_class: 7.5},
            "W18x71" => { d: 18.47, bf: 7.635, tf: 0.810, tw: 0.495, r: (10.2).mm, width_class: 7.5},
            "W18x76" => { d: 18.21, bf: 11.035, tf: 0.680, tw: 0.425, r: (10.2).mm, width_class: 11},
            "W18x86" => { d: 18.39, bf: 11.090, tf: 0.770, tw: 0.480, r: (10.2).mm, width_class: 11},
            "W18x97" => { d: 18.59, bf: 11.145, tf: 0.870, tw: 0.535, r: (10.2).mm, width_class: 11},
            "W18x106" => { d: 18.73, bf: 11.200, tf: 0.940, tw: 0.590, r: (10.2).mm, width_class: 11},
            "W18x119" => { d: 18.87, bf: 11.265, tf: 1.060, tw: 0.655, r: (10.2).mm, width_class: 11},
            "W18x130" => { d: 19.25, bf: 11.160, tf: 1.200, tw: 0.670, r: (10.2).mm, width_class: 11.25},
            "W18x143" => { d: 19.49, bf: 11.220, tf: 1.320, tw: 0.730, r: (10.2).mm, width_class: 11.25},
            "W18x158" => { d: 19.72, bf: 11.300, tf: 1.440, tw: 0.810, r: (10.2).mm, width_class: 11.25},
            "W18x175" => { d: 20.04, bf: 11.375, tf: 1.590, tw: 0.890, r: (10.2).mm, width_class: 11.25},
            "W18x192" => { d: 20.35, bf: 11.455, tf: 1.750, tw: 0.960, r: (10.2).mm, width_class: 11.25},
            "W18x211" => { d: 20.67, bf: 11.555, tf: 1.910, tw: 1.060, r: (10.2).mm, width_class: 11.25},
            "W18x234" => { d: 21.06, bf: 11.650, tf: 2.110, tw: 1.160, r: (10.2).mm, width_class: 11.25},
            "W18x258" => { d: 21.46, bf: 11.770, tf: 2.300, tw: 1.280, r: (10.2).mm, width_class: 11.25},
            "W18x283" => { d: 21.85, bf: 11.890, tf: 2.500, tw: 1.400, r: (10.2).mm, width_class: 11.25},
            "W18x311" => { d: 22.32, bf: 12.005, tf: 2.740, tw: 1.520, r: (10.2).mm, width_class: 11.25}

          },

          # 21" TALL BEAMS
          "W21" => {

            "W21x44" => { d: 20.66, bf: 6.500, tf: 0.450, tw: 0.350, r: (12.7).mm, width_class: 6.5},
            "W21x50" => { d: 20.83, bf: 6.530, tf: 0.535, tw: 0.380, r: (12.7).mm, width_class: 6.5},
            "W21x57" => { d: 21.06, bf: 6.555, tf: 0.650, tw: 0.405, r: (12.7).mm, width_class: 6.5},
            "W21x48" => { d: 20.62, bf: 8.140, tf: 0.430, tw: 0.350, r: (12.7).mm, width_class: 8.25},
            "W21x55" => { d: 20.80, bf: 8.220, tf: 0.522, tw: 0.375, r: (12.7).mm, width_class: 8.25},
            "W21x62" => { d: 20.99, bf: 8.420, tf: 0.615, tw: 0.400, r: (12.7).mm, width_class: 8.25},
            "W21x68" => { d: 21.13, bf: 8.270, tf: 0.685, tw: 0.430, r: (12.7).mm, width_class: 8.25},
            "W21x73" => { d: 21.24, bf: 8.295, tf: 0.740, tw: 0.455, r: (12.7).mm, width_class: 8.25},
            "W21x83" => { d: 21.43, bf: 8.355, tf: 0.835, tw: 0.515, r: (12.7).mm, width_class: 8.25},
            "W21x93" => { d: 21.62, bf: 8.420, tf: 0.930, tw: 0.580, r: (12.7).mm, width_class: 8.25},
            "W21x101" => { d: 21.36, bf: 12.290, tf: 0.800, tw: 0.500, r: (12.7).mm, width_class: 12.25},
            "W21x111" => { d: 21.51, bf: 12.340, tf: 0.875, tw: 0.550, r: (12.7).mm, width_class: 12.25},
            "W21x122" => { d: 21.68, bf: 12.390, tf: 0.960, tw: 0.600, r: (12.7).mm, width_class: 12.25},
            "W21x132" => { d: 21.83, bf: 12.440, tf: 1.035, tw: 0.650, r: (12.7).mm, width_class: 12.25},
            "W21x147" => { d: 22.06, bf: 12.510, tf: 1.150, tw: 0.720, r: (12.7).mm, width_class: 12.25},
            "W21x166" => { d: 22.48, bf: 12.420, tf: 1.360, tw: 0.750, r: (12.7).mm, width_class: 12.25},
            "W21x182" => { d: 22.72, bf: 12.500, tf: 1.480, tw: 0.830, r: (12.7).mm, width_class: 12.25},
            "W21x201" => { d: 23.03, bf: 12.57, tf: 1.630, tw: 0.910, r: (12.7).mm, width_class: 12.25},
            "W21x223" => { d: 23.35, bf: 12.675, tf: 1.790, tw: 1.000, r: (12.7).mm, width_class: 12.25},
            "W21x248" => { d: 23.74, bf: 12.775, tf: 1.990, tw: 1.100, r: (12.7).mm, width_class: 12.25},
            "W21x275" => { d: 24.13, bf: 12.890, tf: 2.190, tw: 1.220, r: (12.7).mm, width_class: 12.25}

          },

          # 24" TALL BEAMS
          "W24" => {

            "W24x55" => { d: 23.57, bf: 7.005, tf: 0.505, tw: 0.395, r: (12.7).mm, width_class: 7},
            "W24x62" => { d: 23.74, bf: 7.040, tf: 0.590, tw: 0.430, r: (12.7).mm, width_class: 7},
            "W24x68" => { d: 23.73, bf: 8.965, tf: 0.585, tw: 0.415, r: (12.7).mm, width_class: 9},
            "W24x76" => { d: 23.92, bf: 8.990, tf: 0.680, tw: 0.440, r: (12.7).mm, width_class: 9},
            "W24x84" => { d: 24.10, bf: 9.020, tf: 0.770, tw: 0.470, r: (12.7).mm, width_class: 9},
            "W24x94" => { d: 24.31, bf: 9.065, tf: 0.875, tw: 0.515, r: (12.7).mm, width_class: 9},
            "W24x103" => { d: 24.53, bf: 9.000, tf: 0.980, tw: 0.550, r: (12.7).mm, width_class: 9},
            "W24x104" => { d: 24.06, bf: 12.750, tf: 0.750, tw: 0.500, r: (12.7).mm, width_class: 12.75},
            "W24x117" => { d: 24.26, bf: 12.800, tf: 0.850, tw: 0.550, r: (12.7).mm, width_class: 12.75},
            "W24x131" => { d: 24.48, bf: 12.855, tf: 0.960, tw: 0.695, r: (12.7).mm, width_class: 12.75},
            "W24x146" => { d: 24.74, bf: 12.900, tf: 1.090, tw: 0.650, r: (12.7).mm, width_class: 12.75},
            "W24x162" => { d: 25.00, bf: 12.955, tf: 1.220, tw: 0.705, r: (12.7).mm, width_class: 12.75},
            "W24x176" => { d: 25.24, bf: 12.890, tf: 1.340, tw: 0.750, r: (12.7).mm, width_class: 12.75},
            "W24x192" => { d: 25.47, bf: 12.950, tf: 1.460, tw: 0.810, r: (12.7).mm, width_class: 12.75},
            "W24x207" => { d: 25.71, bf: 13.010, tf: 1.570, tw: 0.870, r: (12.7).mm, width_class: 12.75},
            "W24x229" => { d: 26.02, bf: 13.110, tf: 1.730, tw: 0.960, r: (16.5).mm, width_class: 12.75},
            "W24x250" => { d: 26.34, bf: 13.185, tf: 1.890, tw: 1.040, r: (16.5).mm, width_class: 12.75},
            "W24x279" => { d: 26.73, bf: 13.305, tf: 2.090, tw: 1.160, r: (16.5).mm, width_class: 12.75},
            "W24x306" => { d: 27.13, bf: 13.405, tf: 2.280, tw: 1.260, r: (16.5).mm, width_class: 12.75},
            "W24x335" => { d: 27.52, bf: 13.520, tf: 2.480, tw: 1.380, r: (16.5).mm, width_class: 12.75},
            "W24x370" => { d: 27.99, bf: 13.660, tf: 2.720, tw: 1.520, r: (16.5).mm, width_class: 12.75}

          },

          # 27" TALL BEAMS
          "W27" => {

            "W27x84" => { d: 26.71, bf: 9.960, tf: 0.640, tw: 0.460, r: (15.2).mm, width_class: 10},
            "W27x94" => { d: 26.92, bf: 9.990, tf: 0.745, tw: 0.490, r: (15.2).mm, width_class: 10},
            "W27x102" => { d: 27.09, bf: 10.015, tf: 0.830, tw: 0.505, r: (15.2).mm, width_class: 10},
            "W27x114" => { d: 27.29, bf: 10.070, tf: 0.930, tw: 0.570, r: (15.2).mm, width_class: 10},
            "W27x129" => { d: 27.63, bf: 10.010, tf: 1.100, tw: 0.616, r: (15.2).mm, width_class: 10},
            "W27x146" => { d: 27.38, bf: 13.965, tf: 0.975, tw: 0.605, r: (15.2).mm, width_class: 14},
            "W27x161" => { d: 27.59, bf: 14.020, tf: 1.080, tw: 0.660, r: (15.2).mm, width_class: 14},
            "W27x178" => { d: 27.81, bf: 14.085, tf: 1.190, tw: 0.725, r: (15.2).mm, width_class: 14},
            "W27x194" => { d: 28.11, bf: 14.035, tf: 1.340, tw: 0.750, r: (15.2).mm, width_class: 14},
            "W27x217" => { d: 28.43, bf: 14.115, tf: 1.500, tw: 0.830, r: (15.2).mm, width_class: 14},
            "W27x235" => { d: 28.66, bf: 14.190, tf: 1.610, tw: 0.910, r: (15.2).mm, width_class: 14},
            "W27x258" => { d: 28.98, bf: 14.270, tf: 1.770, tw: 0.980, r: (15.2).mm, width_class: 14},
            "W27x281" => { d: 27.29, bf: 14.350, tf: 1.930, tw: 1.060, r: (15.2).mm, width_class: 14},
            "W27x307" => { d: 29.61, bf: 14.445, tf: 2.090, tw: 1.160, r: (15.2).mm, width_class: 14},
            "W27x336" => { d: 30.00, bf: 14.550, tf: 2.280, tw: 1.260, r: (15.2).mm, width_class: 14},
            "W27x368" => { d: 30.39, bf: 14.665, tf: 2.480, tw: 1.380, r: (15.2).mm, width_class: 14}

          },

          # 30" TALL BEAMS
          "W30" => {

            "W30x90" => { d: 29.53, bf: 10.400, tf: 0.610, tw: 0.470, r: (16.5).mm, width_class: 10.5},
            "W30x99" => { d: 29.65, bf: 10.450, tf: 0.670, tw: 0.520, r: (16.5).mm, width_class: 10.5},
            "W30x108" => { d: 29.83, bf: 10.475, tf: 0.760, tw: 0.545, r: (16.5).mm, width_class: 10.5},
            "W30x116" => { d: 30.01, bf: 10.495, tf: 0.850, tw: 0.565, r: (16.5).mm, width_class: 10.5},
            "W30x124" => { d: 30.17, bf: 10.515, tf: 0.930, tw: 0.585, r: (16.5).mm, width_class: 10.5},
            "W30x132" => { d: 30.31, bf: 10.545, tf: 1.000, tw: 0.615, r: (16.5).mm, width_class: 10.5},
            "W30x148" => { d: 30.67, bf: 10.480, tf: 1.180, tw: 0.650, r: (16.5).mm, width_class: 10.5},
            "W30x173" => { d: 30.44, bf: 14.985, tf: 1.065, tw: 0.655, r: (16.5).mm, width_class: 15},
            "W30x191" => { d: 30.68, bf: 15.040, tf: 1.185, tw: 0.710, r: (16.5).mm, width_class: 15},
            "W30x211" => { d: 30.94, bf: 15.105, tf: 1.135, tw: 0.775, r: (16.5).mm, width_class: 15},
            "W30x235" => { d: 31.30, bf: 15.055, tf: 1.500, tw: 0.830, r: (16.5).mm, width_class: 15},
            "W30x261" => { d: 31.61, bf: 15.155, tf: 1.650, tw: 0.930, r: (16.5).mm, width_class: 15},
            "W30x292" => { d: 32.01, bf: 15.255, tf: 1.850, tw: 1.020, r: (16.5).mm, width_class: 15},
            "W30x326" => { d: 32.40, bf: 15.370, tf: 2.050, tw: 1.140, r: (16.5).mm, width_class: 15},
            "W30x357" => { d: 32.80, bf: 15.470, tf: 2.240, tw: 1.240, r: (20.0).mm, width_class: 15},
            "W30x391" => { d: 33.19, bf: 15.590, tf: 2.440, tw: 1.360, r: (20.0).mm, width_class: 15}

          },

          # 33" TALL BEAMS
          "W33" => {

            "W33x118" => { d: 32.86, bf: 11.480, tf: 0.740, tw: 0.550, r: (17.8).mm, width_class: 11.5},
            "W33x130" => { d: 33.09, bf: 11.510, tf: 0.855, tw: 0.580, r: (17.8).mm, width_class: 11.5},
            "W33x141" => { d: 33.30, bf: 11.535, tf: 0.960, tw: 0.605, r: (17.8).mm, width_class: 11.5},
            "W33x152" => { d: 33.49, bf: 11.565, tf: 1.055, tw: 0.635, r: (17.8).mm, width_class: 11.5},
            "W33x169" => { d: 33.82, bf: 11.500, tf: 1.220, tw: 0.670, r: (17.8).mm, width_class: 11.5},
            "W33x201" => { d: 33.68, bf: 15.745, tf: 1.150, tw: 0.715, r: (17.8).mm, width_class: 15.75},
            "W33x221" => { d: 33.93, bf: 15.805, tf: 1.275, tw: 0.775, r: (17.8).mm, width_class: 15.75},
            "W33x241" => { d: 34.18, bf: 15.860, tf: 1.400, tw: 0.830, r: (17.8).mm, width_class: 15.75},
            "W33x263" => { d: 34.53, bf: 15.805, tf: 1.570, tw: 0.870, r: (17.8).mm, width_class: 15.75},
            "W33x291" => { d: 34.84, bf: 15.905, tf: 1.730, tw: 0.960, r: (17.8).mm, width_class: 15.75},
            "W33x318" => { d: 35.16, bf: 15.985, tf: 1.890, tw: 1.040, r: (17.8).mm, width_class: 15.75},
            "W33x354" => { d: 35.55, bf: 16.100, tf: 2.090, tw: 1.160, r: (17.8).mm, width_class: 15.75},
            "W33x387" => { d: 35.95, bf: 16.200, tf: 2.280, tw: 1.260, r: (17.8).mm, width_class: 15.75}

          },

          # 36" TALL BEAMS
          "W36" => {

            "W36x135" => { d: 35.55, bf: 11.950, tf: 0.790, tw: 0.600, r: (19.1).mm, width_class: 12},
            "W36x150" => { d: 35.85, bf: 11.975, tf: 0.940, tw: 0.625, r: (19.1).mm, width_class: 12},
            "W36x160" => { d: 36.01, bf: 12.000, tf: 1.020, tw: 0.650, r: (19.1).mm, width_class: 12},
            "W36x170" => { d: 36.17, bf: 12.030, tf: 1.100, tw: 0.680, r: (19.1).mm, width_class: 12},
            "W36x182" => { d: 36.33, bf: 12.075, tf: 1.180, tw: 0.725, r: (19.1).mm, width_class: 12},
            "W36x194" => { d: 36.49, bf: 12.115, tf: 1.260, tw: 0.765, r: (19.1).mm, width_class: 12},
            "W36x210" => { d: 36.69, bf: 12.180, tf: 1.360, tw: 0.830, r: (19.1).mm, width_class: 12},
            "W36x232" => { d: 37.12, bf: 12.120, tf: 1.570, tw: 0.870, r: (19.1).mm, width_class: 12},
            "W36x256" => { d: 37.43, bf: 12.215, tf: 1.730, tw: 0.960, r: (19.1).mm, width_class: 12},
            "W36x231" => { d: 36.49, bf: 16.470, tf: 0.760, tw: 1.260, r: (24.1).mm, width_class: 16.5},
            "W36x247" => { d: 36.67, bf: 16.510, tf: 1.350, tw: 0.800, r: (24.1).mm, width_class: 16.5},
            "W36x262" => { d: 36.85, bf: 16.550, tf: 0.840, tw: 1.440, r: (24.1).mm, width_class: 16.5},
            "W36x282" => { d: 37.11, bf: 16.595, tf: 0.885, tw: 1.570, r: (24.1).mm, width_class: 16.5},
            "W36x302" => { d: 37.33, bf: 16.655, tf: 0.945, tw: 1.680, r: (24.1).mm, width_class: 16.5},
            "W36x330" => { d: 37.67, bf: 16.630, tf: 1.850, tw: 1.020, r: (24.1).mm, width_class: 16.5},
            "W36x361" => { d: 37.99, bf: 16.730, tf: 2.010, tw: 1.120, r: (24.1).mm, width_class: 16.5},
            "W36x395" => { d: 38.37, bf: 16.830, tf: 2.200, tw: 1.220, r: (24.1).mm, width_class: 16.5},
            "W36x441" => { d: 38.85, bf: 16.965, tf: 2.440, tw: 1.360, r: (24.1).mm, width_class: 16.5},
            "W36x527" => { d: 39.21, bf: 17.220, tf: 2.910, tw: 1.610, r: (24.1).mm, width_class: 16.5},
            "W36x650" => { d: 40.47, bf: 17.575, tf: 3.540, tw: 1.970, r: (24.1).mm, width_class: 16.5},
            "W36x798" => { d: 41.97, bf: 17.990, tf: 4.290, tw: 2.380, r: (25.2).mm, width_class: 16.5},
            "W36x848" => { d: 42.45, bf: 18.130, tf: 4.530, tw: 2.520, r: (25.2).mm, width_class: 16.5}

          },

          # 40" TALL BEAMS
          "W40" => {

            "W40x149" => { d: 38.20, bf: 11.810, tf: 0.830, tw: 0.630, r: (30.0).mm, width_class: 12},
            "W40x167" => { d: 38.59, bf: 11.810, tf: 1.025, tw: 0.650, r: (30.0).mm, width_class: 12},
            "W40x183" => { d: 38.98, bf: 11.810, tf: 1.220, tw: 0.650, r: (30.0).mm, width_class: 12},
            "W40x211" => { d: 39.37, bf: 11.810, tf: 1.415, tw: 0.750, r: (30.0).mm, width_class: 12},
            "W40x235" => { d: 39.69, bf: 11.890, tf: 1.575, tw: 0.830, r: (30.0).mm, width_class: 12},
            "W40x264" => { d: 40.00, bf: 11.930, tf: 1.730, tw: 0.960, r: (30.0).mm, width_class: 12},
            "W40x278" => { d: 40.16, bf: 11.969, tf: 1.811, tw: 1.024, r: (30.0).mm, width_class: 12},
            "W40x294" => { d: 40.39, bf: 12.010, tf: 1.930, tw: 1.060, r: (30.0).mm, width_class: 12},
            "W40x327" => { d: 40.79, bf: 12.130, tf: 2.130, tw: 1.180, r: (30.0).mm, width_class: 12},
            "W40x331" => { d: 40.79, bf: 12.165, tf: 2.126, tw: 1.220, r: (30.0).mm, width_class: 12},
            "W40x392" => { d: 41.57, bf: 12.362, tf: 2.520, tw: 1.417, r: (30.0).mm, width_class: 12},
            "W40x199" => { d: 38.67, bf: 15.750, tf: 1.065, tw: 0.650, r: (30.0).mm, width_class: 16},
            "W40x215" => { d: 38.98, bf: 15.750, tf: 1.220, tw: 0.650, r: (30.0).mm, width_class: 16},
            "W40x249" => { d: 39.38, bf: 15.750, tf: 1.420, tw: 0.750, r: (30.0).mm, width_class: 16},
            "W40x277" => { d: 39.69, bf: 15.830, tf: 1.575, tw: 0.830, r: (30.0).mm, width_class: 16},
            "W40x297" => { d: 39.84, bf: 15.825, tf: 1.650, tw: 0.930, r: (30.0).mm, width_class: 16},
            "W40x324" => { d: 40.16, bf: 15.910, tf: 1.810, tw: 1.000, r: (30.0).mm, width_class: 16},
            "W40x362" => { d: 40.55, bf: 16.020, tf: 2.010, tw: 1.120, r: (30.0).mm, width_class: 16},
            "W40x372" => { d: 40.63, bf: 16.063, tf: 2.047, tw: 1.161, r: (30.0).mm, width_class: 16},
            "W40x397" => { d: 40.95, bf: 16.120, tf: 2.200, tw: 1.220, r: (30.0).mm, width_class: 16},
            "W40x431" => { d: 41.26, bf: 16.220, tf: 2.360, tw: 1.340, r: (30.0).mm, width_class: 16}

            },

          # 44" TALL BEAMS
          "W44" => {

            "W44x230" => { d: 42.91, bf: 15.748, tf: 1.220, tw: 0.709, r: (30.0).mm, width_class: 16},
            "W44x262" => { d: 43.31, bf: 15.748, tf: 1.417, tw: 0.878, r: (30.0).mm, width_class: 16},
            "W44x290" => { d: 43.62, bf: 15.827, tf: 1.575, tw: 0.866, r: (30.0).mm, width_class: 16},
            "W44x335" => { d: 44.02, bf: 15.945, tf: 1.772, tw: 1.024, r: (30.0).mm, width_class: 16}

          }
        }
      end #module
  end
end #module
