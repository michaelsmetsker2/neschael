  ;
  ; neschael
  ; lib/player/collision/collision.inc
  ;
  ; variables and enums relating to proccessing player collision
  ;

	MIDPOINT_THRESHOLD	= $08 ; the horizontal speed the player is going at to warrent a mid check
														  ; 8 px per frame is the size of a tile.

  PLAYER_RIGHT_FOOT_OFFSET = $06 ; pixel offset from the players left foot to the right for y checking

  ; not memory safe. only for use in find_collision
	tmpCollisionPointX  = $05 ; unsigned 16,  world coords at which to find the collision type
	tmpCollisionPointY  = $07 ; unsigned,     screen coords at which to find the collision type 

  tmpCollisionPointer = $0C ; pointer to the label corrosponding to the collision type collided with 

  tmpDeltaX           = $00 ; signed 8.8,   proposed position change in either X, can change based on collision
	tmpProposedPosFinal = $02 ; unsigned 8.8, proposed position after velocity is applied, high byte is mainly used

.ENUM CollisionType
  empty            = 0
  levelEnd         = 1
  steepSlopeUp     = 2
  shallowSlopeUp   = 3
  steepSlopeDown   = 4
  shallowSlopeDown = 5
  ; unused
  ; unused
  solid            = 9
.ENDENUM

.ENUM Slopes ; slope variations relative to the start of the block of slopes in CollisionType
  steepUp = CollisionType::steepSlopeUp - SLOPE_COLL_START
  shallowUp = CollisionType::shallowSlopeUp - SLOPE_COLL_START
  steepDown = CollisionType::steepSlopeDown - SLOPE_COLL_START
  shallowDown = CollisionType::shallowSlopeDown - SLOPE_COLL_START
.ENDENUM

  SLOPE_COLL_START = CollisionType::steepSlopeUp ; collisionType index where slopes start
  SLOPE_VARIATIONS = $04 ; ammount of slope variations