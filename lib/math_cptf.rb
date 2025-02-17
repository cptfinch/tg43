# lib/FloatComparison.rb

['bigdecimal','bigdecimal/math',
  'bigdecimal/util','yaml','pathname'].each { |f| require f }

class Array
  
  def find_adjacent(value)
    m=[]; self.each_with_index{|e,i| m<<[i,value.to_f-e]}
    neg=m.find_all{|f| f[1]>0} 
    pos=m.find_all { |f| f[1]<0 }
    zero=m.find_all{|f| f[1]==0}
    result=[]
    begin
      if !neg.empty?
        neg=neg.sort_by { |s| s[1] }
        neg_index=neg.first[0]
        result<<self[neg_index]
      end
      if !pos.empty?
        pos=pos.sort_by{|s| s[1]}
        pos_index=pos.last[0]
        result<<self[pos_index]
      end
    end unless !zero.empty?
    if !zero.empty?
      zero_index=zero.last[0]
      result<<self[zero_index]
    end
    result
  end
  
  def lin_interp(value,&proc)
    return yield value if self.include?(value)
    alpha=(value-self[0])/(self[1]-self[0]).to_f
    fx0=yield self[0].to_f
    fx1=yield self[1].to_f
    fx=alpha*fx1+(1-alpha)*fx0
    fx.to_d.round(4)
  end
  
  def bilin_interp(coords,&proc)
    a,b=[self[0][0],self[1][0]].sort
    c,d=[self[0][1],self[1][1]].sort
    if !(a..b).include?(coords[0])||!(c..d).include?(coords[1])
      raise 'Out of range for interp'
    end
    
    p1=[self[0][0], self[0][1]]
    p2=[self[0][0], self[1][1]]
    p3=[self[1][0], self[0][1]]
    p4=[self[1][0], self[1][1]]

    p1y=p1[1];p2y=p2[1]
    p1x=p1[0]
    p3y=p3[1];p4y=p4[1]
    p3x=p3[0]

    ptop=[p1y.to_f,p2y.to_f].lin_interp(coords[1]){|l| yield(p1x.to_f,l.to_f)}
    pbottom=[p3y.to_f,p4y.to_f].lin_interp(coords[1]){|l| yield(p3x.to_f,l.to_f)}
    p_res=[p1x,p3x].lin_interp(coords[0])do |l|
      if l==p1x
        ptop
      elsif l==p3x
          pbottom
      end
    end
  end
  
  def normalize
    max=self.max
    self.map{|m| (m.to_f/max).to_d.round(4)}
  end
  
end

class Float
  def approx(other, relative_epsilon=Float::EPSILON, epsilon=Float::EPSILON)
    difference = other - self
    return true if difference.abs <= epsilon
    relative_error = (difference / (self > other ? self: other)).abs
    return relative_error<=relative_epsilon
  end
end

  class AngleError < RuntimeError
  end

module Math_cptf
  
  def self.pythagoras(*coords)
    coords.flatten! #coords can now either be an array or individual values
    if coords.any?{|a| !a.respond_to? 'to_d'}
      raise 'Pythgoras only accepts floats, strings, rationals' 
    end #raise if argument doesn't respond to to_d - doesn't support integers
    coords=coords.map{|c| c.to_d} #convert to bigdecimal
    squaredcoords=coords.map {|c| c**2}
    sumOfSquaredCoords=squaredcoords.inject {|sum,value| sum+=value}
    hypotenuse=BigMath::sqrt(sumOfSquaredCoords,6).round(6)
  end

  def self.angle_between_coords(source_coords,dp_coords,axis)
    if !['x','y','z'].include?(axis)
      raise 'Please specify axis that angle is relative to, "x", "y" or "z"' 
    end
    dx,dy,dz=vector_between_coords(source_coords,dp_coords)
    r=pythagoras(dx,dy,dz)
    if r==0
      raise AngleError.new 'Cannot calculate angle because coords are the same - i.e. it is a point not a vector'
    else
      return radians2degrees(Math.acos(eval("d#{axis}")/r)).to_d.round(4)
    end
  end
    
  def self.vector_between_coords(coords1,coords2)
    x1,y1,z1=coords1.map{|m| m.to_f}
    x2,y2,z2=coords2.map{|m| m.to_f}
    return [x2-x1,y2-y1,z2-z1]
  end
  
  def self.condense_p1p2p3p4_to_p1p4(x,y)
    p1p4=[]
    p1p4<<[x[0],y[0]] #putting in p1
    p1p4<<[x[1]||=x[0],y[1]||=y[0]] #putting in p4
  end
  
  def self.radians2degrees(angle)
    conversion=360/(2*Math::PI)
    angle*conversion
  end

  def self.gradient(coords1,coords2)
    dy=coords2[1].to_f-coords1[1].to_f
    dx=coords2[0].to_f-coords1[0].to_f
    dy/dx
  end
  
end


