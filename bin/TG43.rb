
#require files from project
app_root=File.join(File.dirname(__FILE__), '..')
app_files=[['lib','math_cptf'],['lib','TG43maths']]
app_files.each{|e| require File.join(app_root,*e)}

#require stdlib files
['yaml','rubygems','fastercsv','test/unit','highline/import','pp'].each{|e| require e}

x = ask("Enter x coordinate of dose point", Float)
y = ask("Enter y coordinate of dose point", Float)
z = ask("Enter z coordinate of dose point", Float)
dp_coords=[x,y,z]
dose_to_dp = ask("Enter dose to dose point", Float)
applicator_filename = ask("Enter applicator file name"){|f| 
                    f.default = "cervix_HDR_applicator_40U_20O.yaml"}
applicator=Applicator.new(applicator_filename)
af_filename = ask("Enter anisotropy factor filename") do |f|
                  f.default='af_godden.yaml'
                end
rakr=1_000_000*1.9401697/(3600*100) #cGy/hr to Gy/s

params=[dose_to_dp,applicator,dp_coords,rakr,af_filename]

puts "Results:"
TG43maths::seconds_per_position(*params).each_with_index do |e,i| 
            puts "#{i+1}. (#{e[0][0]}, #{e[0][1]}, #{e[0][2]}) =>  #{e[1].to_s} seconds"
          end
            