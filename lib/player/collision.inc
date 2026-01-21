  ;
  ; neschael
  ; lib/player/collision.inc
  ;
  ; variables and enums relating to proccessing player collision
  ;

  ; not memory safe. only for use in find_collision
	tmpCollisionPointX  = $05 ; unsigned 16,  world coords at which to find the collision type
	tmpCollisionPointY  = $07 ; unsigned,     screen coords at which to find the collision type 

  tmpCollisionPointer = $0C ; pointer to the label corrosponding to the collision type collided with 

  tmpDeltaX           = $00 ; signed 8.8,   proposed position change in either X, can change based on collision
	tmpProposedPosFinal = $02 ; unsigned 8.8, proposed position after velocity is applied, high byte is mainly used

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