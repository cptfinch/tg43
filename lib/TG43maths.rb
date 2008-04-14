# lib/TG43maths.rb

app_root=File.join(File.dirname(__FILE__), '..')
app_files=[['lib','File_cptf'],
                ['lib','math_cptf']]
                
['bigdecimal','bigdecimal/math',
  'bigdecimal/util','yaml','pathname',
  'rubygems','fastercsv'].each { |f| require f }

app_files.each{|e| require File.join(app_root,*e)}

include BigMath

class Source

  def initialize(params)
    @source_coords=params[:source_coords]
    @cylinder_direction=params[:cylinder_direction]
    @dwell_weight=params[:dwell_weight]
  end
  attr_reader :source_coords,:cylinder_direction,:dwell_weight
  
  def ==(other)
    @source_coords==other.source_coords &&
      @cylinder_direction==other.cylinder_direction &&
      @dwell_weight==other.dwell_weight
  end
  
end

class Applicator
  
  def initialize(filename) #opens a yaml file containing array of sources
    sources=TG43maths::open_yaml("#{filename}") 
    @sources=sources.map{|e| Source.new(e) }
  end
  attr_reader :sources
end

module TG43maths
  
  def self.open_yaml(filename)
    path=File_cptf::get_pathname(__FILE__)
    open(path+"/#{filename}"){|f| YAML.load(f)}    
  end
  
  def self.doserate_constant(isotope_and_shape,filename="dr_constants.yaml")
    isotope=isotope_and_shape[:isotope]
    shape=isotope_and_shape[:shape]
    dr=open_yaml(filename)
    src_desc=dr.find{|f| f['isotope']==isotope && f['shape']==shape}
    dr_const=src_desc['strength']
    #find in yaml file?
    #dr_const=Doserate_constant.find_by_isotope_and_source('')
  end
    
  def self.geometry_factor(r)
    1.to_f/r**2
  end # approximated to point source - TODO extend for line source
  
  def self.clip_to_within_af_range(r,phi,af_file="anisotropy_factors_test.yaml")
    af=open_yaml(af_file)
    max_r=af.keys.max
    min_r=af.keys.min
    max_phi=af.values[0].keys.max
    min_phi=af.values[0].keys.min
    
    r=max_r if r>max_r
    r=min_r if r<min_r
    phi=max_phi if phi>max_phi
    phi=min_phi if phi<min_phi
    [r,phi]
  end
  
  def self.clip_to_within_gr_range(r,gr_file="gr_file.csv")
    gr=make_gr_hash('g(r).csv')
    max_r=gr.keys.max
    min_r=gr.keys.min
    max_g=gr.values.max
    min_g=gr.values.min
    
    r=max_r if r>max_r
    r=min_r if r<min_r
    r
  end
  
  def self.make_af_hash(af_csv_file) #top row (minus left most cell) represents r; left column phi
    arr_of_arrs = FasterCSV.read(af_csv_file)
    row_size=arr_of_arrs[0].size
    column_size=arr_of_arrs.size
    
    r_arr=arr_of_arrs[0][1..row_size]
    r_arr.map!{|m| m.to_f}
    arr_of_arrs=arr_of_arrs[1..column_size]
    phi_arr=[]
    arr_of_arrs.each{|e| phi_arr<<e[0].to_f}
    
    factors=Array.new(row_size-1)
    (row_size-1).times do|t|
      factors[t]= arr_of_arrs.map{|m| m[t+1].to_f}
    end
    
    vals=[]
    factors.each do|f|
      vals<<Hash[*phi_arr.zip(f).flatten]
    end
    
    af_hash=Hash[*r_arr.zip(vals).flatten]
  end
  
  def self.make_gr_hash(gr_csv_file)
    arr_of_arrs = FasterCSV.read(gr_csv_file)
    row_size=arr_of_arrs[0].size
    column_size=arr_of_arrs.size
    r_arr=arr_of_arrs.map{|m| m[0].to_f}[1..column_size]
    g_arr=arr_of_arrs.map{|m| m[1].to_f}[1..column_size]
    
    gr_hash=Hash[*r_arr.zip(g_arr).flatten]
  end
  
  def self.csv_table_2_yaml(csvfile,yamlfile)
    hash=make_af_hash(csvfile)
    open(yamlfile,'w'){|f| YAML.dump(hash,f)}
  end
  
  def self.anisotropy_factor(r,phi,af_file="anisotropy_factors_test.yaml")
    r,phi=r.to_f,phi.to_f
    af=open_yaml(af_file)  
    i=af.keys.find_adjacent(r)
    j=af.values[0].keys.find_adjacent(phi)
    r,phi=clip_to_within_af_range(r,phi,af_file)
    p1,p4=Math_cptf::condense_p1p2p3p4_to_p1p4(i,j)
    [p1,p4].bilin_interp([r,phi]){|x,y| af[x][y]}
  end
  
  def self.radial_dose_fn(r,gr_file='g(r).csv')
    r=r.to_f
    gr_hash=make_gr_hash(gr_file)
    i=gr_hash.keys.find_adjacent(r)
    r=clip_to_within_gr_range(r,gr_file)
    i.lin_interp(r){|x|gr_hash[x]}
  end
  
  def self.doserate_at_dp(source_coords,dp_coords,rakr=10,dwell_weight=1,af_file="anisotropy_factors_test.yaml",gr_file='g(r).csv',source_dir='x')
    v=Math_cptf::vector_between_coords(source_coords,dp_coords)
    r=Math_cptf::pythagoras v
    phi=Math_cptf::angle_between_coords(source_coords,dp_coords,source_dir)
    dr=rakr*doserate_constant({:isotope=>'iridium90',:shape=>'cylinder'})*
      geometry_factor(r)*anisotropy_factor(r,phi,af_file)*
      dwell_weight*radial_dose_fn(r,gr_file)
    dr.to_d.round(4)
  end
  
  def self.seconds_per_position(prescribed_dose_to_dp=10,applicator=Applicator.new('cervix_HDR_applicator_40U_20O.yaml'),dp_coords=[-20,0,20],rakr=10,af_file="anisotropy_factors_test.yaml",gr_file="g(r).csv")
    weighted_dose=doserate_from_applicator(applicator,dp_coords,rakr,af_file,gr_file)
    source_times=applicator.sources.map do |m|
      [m.source_coords,((prescribed_dose_to_dp.to_f/weighted_dose)*m.dwell_weight).to_d.round(4)]
    end
  end
  
  def self.find_width(target_dose,applicator,rakr=10,af_file="anisotropy_factors_test.yaml",gr_file='g(r).csv')
    target_dose_acceptibility=(target_dose-0.1..target_dose+0.1)
    45.step(55,1)do |z|
      dp_coords=[10,0,z]
      return z if target_dose_acceptibility.include?(doserate_from_applicator(applicator,dp_coords,rakr,af_file,gr_file))
    end
    return 'no, no, no'    
  end
  
  def self.doserate_from_applicator(applicator,dp_coords,rakr=10,af_file="anisotropy_factors_test.yaml",gr_file='g(r).csv')
    doses_at_dp=applicator.sources.map do
      |e| 
          doserate_at_dp(e.source_coords,dp_coords,rakr,e.dwell_weight,af_file,gr_file,e.cylinder_direction)
    end
    summed_dose=doses_at_dp.inject{|total,i| total+=i}
  end  
end