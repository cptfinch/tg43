
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

class Math_cptfTest < Test::Unit::TestCase
     
  def test_pythagoras
    x,y,z=2.0,3.0,4.0
    a,b,c=BigDecimal.new('2'),BigDecimal.new('3'),BigDecimal.new('4')
    d,e,f='2','3','4'
    hyp_float=Math_cptf::pythagoras(x,y,z)
    hyp_string=Math_cptf::pythagoras(d,e,f)
    ascrowflies=Math_cptf::pythagoras(x)
    
    assert_equal(BigDecimal.new('5.385165'),hyp_float)
    assert_equal(BigDecimal.new('5.385165'),Math_cptf::pythagoras([2.0,3.0,4.0]))
    assert_equal(BigDecimal.new('2'),ascrowflies)
    assert_equal(BigDecimal.new('5.385165'),hyp_string)
    assert_equal(0,Math_cptf::pythagoras([0.0,0.0,0.0]))
    assert_equal(0.866025,Math_cptf::pythagoras([0.5,0.5,0.5]))
    
    assert_raise RuntimeError do 
      Math_cptf.pythagoras(2,3,4)
    end
  end
  
  def test_should_calculate_angle_from_xaxis #cylindrical symmetry along x axis
    assert_equal(90,Math_cptf::angle_between_coords([0.0,0.0,0.0],[0.0,0.0,1.0],'x'))
    assert_equal(0,Math_cptf::angle_between_coords([0.0,0.0,0.0],[1,0.0,0],'x'))
    assert_equal(90,Math_cptf::angle_between_coords([0.0,0.0,0.0],[0.0,1,0],'x'))
    assert_equal(180,Math_cptf::angle_between_coords([0.0,0.0,0.0],[-1.0,0.0,0.0],'x'))
    assert_equal(90,Math_cptf::angle_between_coords([0.0,0.0,0.0],[0.0,0.0,-1.0],'x'))
    assert_equal(90,Math_cptf::angle_between_coords([0.0,0.0,0.0],[0.0,-1.0,0.0],'x'))
    assert_equal(54.7356.to_d,Math_cptf::angle_between_coords([1.0,1.0,1.0],[1.5,1.5,1.5],'x'))

    assert_raise AngleError do 
      Math_cptf::angle_between_coords([0.0,0.0,0.0],[0.0,0,0.0],'x')
    end
    assert_raise AngleError do 
      Math_cptf::angle_between_coords([0.0,0.0,0.0],[0.0,0,0.0],'y')
    end
    assert_raise AngleError do 
      Math_cptf::angle_between_coords([0.0,0.0,0.0],[0.0,0,0.0],'z')
    end    
  end
  
  def test_should_calculate_angle_from_yaxis #cylindrical symmetry along y axis
    assert_equal(90,Math_cptf::angle_between_coords([0.0,0.0,0.0],[1.0,0.0,0.0],'y'))
    assert_equal(0,Math_cptf::angle_between_coords([0.0,0.0,0.0],[0,1.0,0],'y'))
    assert_equal(90,Math_cptf::angle_between_coords([0.0,0.0,0.0],[0.0,0,1],'y'))
    assert_equal(180,Math_cptf::angle_between_coords([0.0,0.0,0.0],[0.0,-1.0,0.0],'y'))
    assert_equal(90,Math_cptf::angle_between_coords([0.0,0.0,0.0],[0.0,0.0,-1.0],'y'))
    assert_equal(90,Math_cptf::angle_between_coords([0.0,0.0,0.0],[-1.0,0.0,0.0],'y'))
    
  end
  
  def test_should_find_2_adjacent_values
    assert_equal([1,2],[1,2].find_adjacent(1.5))
    assert_equal([1.1,1.9],[1,1.1,1.9,1.91,2].find_adjacent(1.534))
    assert_equal([1,2],[2,1].find_adjacent(1.5))
    assert_equal([2],[1,2,3,4].find_adjacent(2))
    assert_equal([2,3],[1,2,3,4].find_adjacent(2.0000001))
    assert_equal([4],[1,2,3,4].find_adjacent(5))
    assert_equal([1],[1,2,3,4].find_adjacent(-1))
    assert_equal([2],[1,2,3,4].find_adjacent(2))
    assert_equal([1],[1,2,3].find_adjacent(0.8))
    assert_equal([90],[1,2,90].find_adjacent(91))
    assert_equal([2,90],[1,2,90].find_adjacent(54.7356))
    
  end
  def test_should_condense_p1p2p3p4_to_p1p4
  xcoords=[1,2]; ycoords=[1,2];
  assert_equal([[1,1],[2,2]],
                    Math_cptf::condense_p1p2p3p4_to_p1p4(xcoords,ycoords))
  assert_equal([[1,1],[1,2]],
                    Math_cptf::condense_p1p2p3p4_to_p1p4([1,1],[1,2]))
  assert_equal([[1,1],[2,1]],
                    Math_cptf::condense_p1p2p3p4_to_p1p4([1,2],[1,1]))
  assert_equal([[2,2],[1,1]],
                    Math_cptf::condense_p1p2p3p4_to_p1p4([2,1],[2,1]))
  assert_equal([[1,1],[1,1]],
                    Math_cptf::condense_p1p2p3p4_to_p1p4([1,1],[1,1]))
  assert_equal([[0.2345,2.34],[5.67,4.33]],
                    Math_cptf::condense_p1p2p3p4_to_p1p4([0.2345,5.67],[2.34,4.33]))
  
  end
  
  def test_radians2degrees
    assert_equal(360,Math_cptf::radians2degrees(2*Math::PI))
    assert_equal(0,Math_cptf::radians2degrees(0))
    assert_equal(180,Math_cptf::radians2degrees(Math::PI))
    assert_equal(90,Math_cptf::radians2degrees(Math::PI/2))
  end
  
  def test_vector_between_coords
    assert_equal([1.0,1.0,1.0],Math_cptf.vector_between_coords([0,0,0],[1,1,1]))
    assert_equal([1.0,1.0,1.0],Math_cptf.vector_between_coords([0.0,0.0,0.0],[1,1,1]))
    assert_equal([1,1,1],Math_cptf.vector_between_coords([0.0,0.0,0.0],[BigDecimal.new('1'),BigDecimal.new('1'),BigDecimal.new('1')]))
    assert_equal([0,0,0],Math_cptf.vector_between_coords([0,0,0],[0,0,0]))
    assert_equal([0,0,0],Math_cptf.vector_between_coords([2,2,2],[2,2,2]))
    assert_equal([0.5,0.5,0.5],Math_cptf.vector_between_coords([1,1,1],[1.5,1.5,1.5]))
  end
  
  def test_should_normalize
    assert_equal([BigDecimal.new('1'),BigDecimal.new('1'),
                  BigDecimal.new('1'),BigDecimal.new('1'),
                  BigDecimal.new('0.6667'),BigDecimal.new('0.6667'),
                  BigDecimal.new('0.6667'),BigDecimal.new('0.6667'),
                  BigDecimal.new('0.6667'),BigDecimal.new('0.6667'),
                  BigDecimal.new('0.6667'),BigDecimal.new('0.6667'),
                  BigDecimal.new('0.8333'),BigDecimal.new('0.8333'),
                  BigDecimal.new('0.8333'),BigDecimal.new('0.8333'),
                  BigDecimal.new('0.8333'),BigDecimal.new('0.8333')],
                  [6,6,6,6,4,4,4,4,4,4,4,4,5,5,5,5,5,5].normalize)
  end
  
  def test_should_find_gradient
    assert_equal(1,Math_cptf::gradient([0,0],[1,1]))
  end
    
  def test_should_linearly_interpolate
    assert_equal(2.5,[2,3].lin_interp(2.5){|l| l})
    assert_equal(5.76,[2,3].lin_interp(2.88){|l| 2*l})
    assert_equal(4,[2,2].lin_interp(2){|l| 2*l})
  end
  
  def test_should_bilinearly_interpolate
    af= {1.0=>{1.0=>10, 90.0=>900, 2.0=>20}, 2.0=>{1.0=>100, 2.0=>200, 90.0=>300}, 3.0=>{1.0=>1000, 2.0=>2000,90.0=>3000}}
    
    assert_equal(0.25,[[0,0],[1,1]].bilin_interp([0.5,0.5]){|x,y|x*y})
    assert_equal(1,[[0,0],[1,1]].bilin_interp([0.5,0.5]){|x,y|x+y})
    assert_equal(0.5,[[0,0],[1,1]].bilin_interp([1,0.5]){|x,y|x*y})
    assert_equal(1,[[0,0],[1,1]].bilin_interp([1,1]){|x,y|x*y})
    assert_equal(2599.2682,[[3,2],[3,90]].bilin_interp([3.0,54.7356]){|x,y| af[x][y]})
    
    assert_raise RuntimeError do
      [[0,0],[1,1]].bilin_interp([2,2]){|x,y|x*y} #extrapolation
    end
    
    assert_equal(82.5,[[1,1],[2,2]].bilin_interp([1.5,1.5]){|x,y| af[x][y]})
    assert_equal(15,[[1,1],[1,2]].bilin_interp([1,1.5]){|x,y| af[x][y]})
    assert_equal(10,[[1,1],[1,1]].bilin_interp([1,1]){|x,y| af[x][y]})
    assert_equal(900,[[1,90],[1,90]].bilin_interp([1.0,90.0]){|x,y| af[x][y]})
    assert_equal(300,[[3,5],[2,90]].bilin_interp([2,90.0]){|x,y| af[x][y]})
    assert_raise RuntimeError do
      [[1,2],[1,90]].bilin_interp([5,54.7356]){|x,y| af[x][y]}
    end
  end  
  
end
