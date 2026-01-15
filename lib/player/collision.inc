  ; these are defined and set in the bounding.s file, they are not memory safe. only for use in find_collision
	tmpCollisionPointX  = $05 ; unsigned 16,  world coords at which to find the collision type
	tmpCollisionPointY  = $07 ; unsigned,     screen coords at which to find the collision type 

  tmpCollisionPointer = $10 ; pointer to the label corrosponding to the collision type collided with 

	; the collision type *2 is the corollating function in collision index
.ENUM CollisionType
  empty = 0
  solid = 1
  hazard = 2
  bounceH = 3
  bounceV = 4
  ; special?
  ; slope l/r and top and bottom?
  ; semisolid?
.ENDENUM