#test/TG43_test.rb

app_root=File.join(File.dirname(__FILE__), '..')
app_files=[['lib','TG43maths'],
                ['bin','TG43'],
                ['lib','File_cptf'],
                ['lib','math_cptf']]
app_files.each{|e| require File.join(app_root,*e)}

require 'yaml'
require 'rubygems'
require 'fastercsv'
require 'test/unit'

class TG43mathsTest < Test::Unit::TestCase
  
  def test_doserate_constant
    dr_constants_check=[{'isotope'=>'iridium90','shape'=>'cylinder','strength'=>1.108},
                                  {'isotope'=>'cobalt','shape'=>'sphere','strength'=>4.3},
                                  {'isotope'=>'tech','shape'=>'ellipsoid'},
                                  {'isotope'=>'yttrium','strength'=>5.4}]
    filename="dr_constant_test.yaml"
    this_path=File_cptf::get_pathname(__FILE__)
    File.open(this_path+"/../lib/#{filename}",'w'){|f| YAML.dump(dr_constants_check,f)}
    lookedup_dr=TG43maths::doserate_constant({:isotope=>'iridium90',:shape=>'cylinder'},filename)
    assert_equal(1.108,lookedup_dr)
    assert_equal(nil,TG43maths::doserate_constant({:isotope=>'tech',:shape=>'ellipsoid'},filename))
    File.delete(this_path+"/../lib/#{filename}")
  end
  
  def test_geometry_factor
    assert_equal(1/4.to_f,TG43maths::geometry_factor(2))
    assert_equal(1/9.to_f,TG43maths::geometry_factor(3))
    assert_equal(1/(0.866025**2),TG43maths::geometry_factor(0.866025))
  end
  
  def test_anisotropy_factor
    r=1.5;phi=1.5
    assert_equal(82.5,TG43maths::anisotropy_factor(r,phi))
    assert(19.9.approx(TG43maths::anisotropy_factor(1,1.99)))
    assert_equal(900,TG43maths::anisotropy_factor(1.0,90.0))
    assert_equal(2599.2682,TG43maths::anisotropy_factor(3.2,54.7356))
    assert_equal(547.356,TG43maths::anisotropy_factor(0.866025,54.7356))
  end
  
  def test_should_calculate_doserate_at_dp  
    source_coords=[0,0,0];dp_coords=[-10,0,10];rakr=5
    assert_equal(83.3077,TG43maths.doserate_at_dp(source_coords,dp_coords,rakr)) #hand checked
    assert_equal(166.6155,TG43maths::doserate_at_dp(source_coords,dp_coords)) #hand checked
    assert_equal(2724.9026.to_d,TG43maths::doserate_at_dp([0,0,0],[1.5,1.5,1.5],10,1)) #hand checked
    assert_equal(4059.3127.to_d,TG43maths::doserate_at_dp([1.0,1.0,1.0],[1.5,1.5,1.5],10,0.5))
    assert_equal(26698.3929.to_d,TG43maths::doserate_at_dp([2,2,2],[1.5,1.5,1.5],10,2)) #hand checked
  end
  
  def test_should_clip_r_phi_to_within_af_range
    assert_equal([2,2],TG43maths::clip_to_within_af_range(2,2))
    assert_equal([1,2],TG43maths::clip_to_within_af_range(0.5,2))
    assert_equal([3,2],TG43maths::clip_to_within_af_range(4.2,2))
    assert_equal([2,90],TG43maths::clip_to_within_af_range(2,91))
    assert_equal([2,1],TG43maths::clip_to_within_af_range(2,0.5))
  end
  
  def test_should_calculate_doserate_for_applicator
    applicator=Applicator.new('cervix_HDR_applicator_40U_20O.yaml')
    dp_coords=[-20,0,20] #point A
    rakr=1_000_000*1.9401697/(3600*100) #cGy/hr to Gy/s 
    first=[applicator,dp_coords,rakr]
    second=[applicator,[-20,0,-20],rakr]
    third=[applicator,dp_coords,rakr,'af_godden.yaml']
    fourth=[applicator,[-20,0,50],rakr,'af_godden.yaml']
    assert_equal(343.6629,TG43maths::doserate_from_applicator(*first))
    assert_equal(TG43maths::doserate_from_applicator(*first),
                      TG43maths::doserate_from_applicator(*second))
    assert_equal(0.1169,TG43maths::doserate_from_applicator(*third))
    assert_equal(0.0276.to_d,TG43maths::doserate_from_applicator(*fourth))
  end
  
  def test_seconds_per_position
    applicator=Applicator.new('cervix_HDR_applicator_40U_20O.yaml')
    dp_coords=[-20,0,20] #point A
    rakr=1_000_000*1.9401697/(3600*100) #cGy/hr to Gy/s 
    first=[10,applicator,dp_coords,rakr,'af_godden.yaml']
    second=[10,applicator,[-20,0,-20],rakr,'af_godden.yaml']
    third=[10,applicator,[-20,0,50],rakr,'af_godden.yaml']
    
    assert_equal([[[10, -5, 10],74.8503.to_d],
                 [[10, 0, 10],74.8503.to_d],
                 [[10, 5, 10],74.8503.to_d],
                 [[10, -5, -10],74.8503.to_d],
                 [[10, 0, -10], 74.8503.to_d],
                 [[10, 5, -10],74.8503.to_d],
                 [[-34, 0, 0],85.5432.to_d],
                 [[-29, 0, 0],85.5432.to_d],
                 [[-24, 0, 0],85.5432.to_d],
                 [[-19, 0, 0],85.5432.to_d],
                 [[-14, 0, 0],85.5432.to_d],
                 [[-9, 0, 0],85.5432.to_d],
                 [[-4, 0, 0],85.5432.to_d],
                 [[1, 0, 0],85.5432.to_d]],TG43maths::seconds_per_position(*first))
    assert_equal(TG43maths::seconds_per_position(*first),
                      TG43maths::seconds_per_position(*second))
    assert_equal([[[10, -5, 10],0.317029E3],
                 [[10, 0, 10],0.317029E3],
                 [[10, 5, 10],0.317029E3],
                 [[10, -5, -10],0.317029E3],
                 [[10, 0, -10],0.317029E3],
                 [[10, 5, -10],0.317029E3],
                 [[-34, 0, 0],0.3623188E3],
                 [[-29, 0, 0],0.3623188E3],
                 [[-24, 0, 0],0.3623188E3],
                 [[-19, 0, 0],0.3623188E3],
                 [[-14, 0, 0],0.3623188E3],
                 [[-9, 0, 0],0.3623188E3],
                 [[-4, 0, 0],0.3623188E3],
                 [[1, 0, 0],0.3623188E3]],TG43maths::seconds_per_position(*third))
  end
  
#  def test_find_width
#    applicator=Applicator.new('cervix_HDR_applicator_40U_20O.yaml')
#    rakr=1_000_000*1.9401697/(3600*100)
#    first=[0.1169,applicator,rakr,'af_godden.yaml']
#    assert_equal(1,TG43maths::find_width(*first))
#  end
  
  def test_make_af_hash
    assert(TG43maths::make_af_hash('af_file.csv'))
  end
  
  def test_radial_dose_fn
  assert_equal(1,TG43maths::radial_dose_fn(2))
  assert_equal(0.799,TG43maths::radial_dose_fn(120))
  assert_equal(1.004,TG43maths::radial_dose_fn(1))
  assert_equal(1.004,TG43maths::radial_dose_fn(0.99))
  assert_equal(0.681,TG43maths::radial_dose_fn(140.2))
  assert_equal(1.0062,TG43maths::radial_dose_fn(34.4))
  
  end
  
  #~ def test_should_read_csv_table_and_write_to_yaml_file
    #~ TG43maths::csv_table_2_yaml('../tc_TG43/af_file.csv','yamltest.yaml')
    #~ a=",2.5,5,10,20,30,50
#~ 0,0.729,0.667,0.631,0.645,0.660,0.696
#~ 1,0.730,0.662,0.631,0.645,0.661,0.701
#~ 2,0.729,0.662,0.632,0.652,0.670,0.709
#~ 3,0.730,0.663,0.640,0.662,0.679,0.718
#~ 4,0.731,0.664,0.650,0.673,0.690,0.726
#~ 5,0.733,0.671,0.661,0.684,0.700,0.735
#~ 6,0.735,0.680,0.674,0.696,0.711,0.743
#~ 7,0.734,0.691,0.687,0.708,0.723,0.753
#~ 8,0.739,0.702,0.700,0.720,0.734,0.763
#~ 10,0.756,0.727,0.727,0.745,0.758,0.782
#~ 12,0.777,0.751,0.753,0.769,0.781,0.804
#~ 14,0.802,0.775,0.778,0.791,0.802,0.822
#~ 16,0.820,0.797,0.800,0.812,0.822,0.840
#~ 20,0.856,0.836,0.839,0.846,0.854,0.872
#~ 24,0.885,0.868,0.869,0.874,0.877,0.888
#~ 30,0.920,0.904,0.902,0.907,0.906,0.911
#~ 36,0.938,0.930,0.929,0.931,0.934,0.933
#~ 42,0.957,0.949,0.949,0.955,0.956,0.954
#~ 48,0.967,0.963,0.965,0.965,0.969,0.965
#~ 58,0.982,0.982,0.982,0.982,0.983,0.978
#~ 73,0.994,0.997,0.997,0.998,0.996,0.985
#~ 88,0.997,1.001,1.000,1.000,1.000,1.001
#~ 90,1.000,1.000,1.000,1.000,1.000,1.000
#~ 103,0.995,0.995,1.001,0.999,1.000,0.995
#~ 118,0.987,0.987,0.987,0.989,0.989,0.983
#~ 128,0.974,0.972,0.976,0.976,0.980,0.979
#~ 133,0.969,0.961,0.966,0.965,0.973,0.973
#~ 138,0.957,0.949,0.952,0.952,0.959,0.960
#~ 143,0.942,0.933,0.935,0.935,0.944,0.941
#~ 148,0.924,0.912,0.914,0.915,0.924,0.926
#~ 153,0.899,0.886,0.887,0.889,0.899,0.905
#~ 158,0.873,0.850,0.850,0.856,0.863,0.870
#~ 165,0.806,0.779,0.778,0.791,0.801,0.816
#~ 169,0.806,0.725,0.723,0.741,0.754,0.785
#~ 170,0.806,0.710,0.707,0.727,0.742,0.774
#~ 172,0.806,0.678,0.675,0.697,0.714,0.748
#~ 173,0.806,0.662,0.657,0.682,0.700,0.733
#~ 174,0.806,0.642,0.640,0.667,0.686,0.720
#~ 175,0.806,0.623,0.624,0.652,0.672,0.707
#~ 176,0.806,0.605,0.608,0.637,0.658,0.695
#~ 177,0.806,0.606,0.594,0.624,0.645,0.686
#~ 178,0.806,0.608,0.586,0.612,0.634,0.675
#~ 179,0.806,0.609,0.585,0.604,0.624,0.665
#~ 180,0.806,0.609,0.585,0.603,0.622,0.662"
    
    #~ b=a.split("\n")
    
    #~ i=0
    #~ as=open('yamltest.csv','r'){|f| YAML.load(f)}.to_csv
    #~ FasterCSV.foreach("af_file.csv") do |row|
      #~ t=b[i].split(",")
      #~ assert_equal(t,row)
      #~ i+=1
    #~ end
    
    #~ assert_equal(a,TG43maths::make_af_hash('af_file.csv'))
  #~ end
  
  def test_sources_equal_method
    s1=Source.new({:source_coords=>[0,0,0],
                            :cylinder_direction=>'x',
                            :dwell_weight=>1})
    s2=Source.new({:source_coords=>[0,0,0],
                            :cylinder_direction=>'x',
                            :dwell_weight=>1})
    assert_equal(s1,s2)
  end
  
  def test_create_an_applicator
    s1=Source.new({:source_coords=>[0,0,0],
                            :cylinder_direction=>'x',
                            :dwell_weight=>1})
    s2=Source.new({:source_coords=>[1,1,1],
                            :cylinder_direction=>'y',
                            :dwell_weight=>0.5})
    s3=Source.new({:source_coords=>[2,2,2],
                            :cylinder_direction=>'z',
                            :dwell_weight=>2})
    open('../lib/cervix_HDR_applicator_test.yaml','w')do |f|
      YAML.dump([{:source_coords=>[0,0,0],
                            :cylinder_direction=>'x',
                            :dwell_weight=>1},
        {:source_coords=>[1,1,1],
                            :cylinder_direction=>'y',
                            :dwell_weight=>0.5},
        {:source_coords=>[2,2,2],
                            :cylinder_direction=>'z',
                            :dwell_weight=>2}],f)
    end
    a=Applicator.new('cervix_HDR_applicator_test.yaml')
    assert_equal([s1,s2,s3],a.sources)
  end
  
  def test_should_create_a_source
    params={:source_coords=>[0,0,0],:cylinder_direction=>'x',:dwell_weight=>1}
    s=Source.new(params)
    assert_equal([0,0,0],s.source_coords)
    assert_equal('x',s.cylinder_direction)
    assert_equal(1,s.dwell_weight)
  end
    
end
